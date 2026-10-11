"""Assistant service with swappable providers.

    AssistantService
      ├── RuleBasedAssistant   (default — same behaviour as the offline app)
      ├── OpenAIProvider       (cloud, Responses API, key stays on the server)
      └── LocalLLMProvider     (sovereign model behind an OpenAI-compatible API)

LLM providers receive the system prompt below, the youth profile and the
retrieved context (FAQ + matching opportunities), and fall back to the
rule-based answer on any error, so the assistant never goes silent.
"""
import json
import os
import re
import unicodedata

import requests

from . import recommendation

SYSTEM_PROMPT = """Tu es l'assistant TIFAWT.
Ta mission est d'aider les jeunes NEET du Souss-Massa à identifier des formations,
opportunités et dispositifs correspondant à leur situation.
Tu dois :
- utiliser uniquement les informations fournies dans le contexte ;
- ne jamais inventer une formation ou une opportunité ;
- demander une précision lorsque les informations sont insuffisantes ;
- expliquer simplement les recommandations ;
- utiliser un langage accessible, en darija ou en français selon la question ;
- orienter vers la source officielle lorsqu'une inscription est nécessaire."""


def normalize(text):
    text = unicodedata.normalize("NFKD", text.lower())
    text = "".join(c for c in text if not unicodedata.combining(c))
    for a, b in (("أ", "ا"), ("إ", "ا"), ("آ", "ا"), ("ة", "ه"), ("ى", "ي")):
        text = text.replace(a, b)
    return re.sub(r"\s+", " ", re.sub(r"[?!.,;:'«»()\-]", " ", text)).strip()


ARABIC = re.compile(r"[؀-ۿ]")

INTENTS = [
    ("internship", ["stage", "تدريب"], ["internship"]),
    ("entrepreneurship", ["projet", "entreprise", "cooperative", "مشروع", "تعاونيه"], ["entrepreneurship"]),
    ("training", ["formation", "apprendre", "تكوين", "نتكون", "نتعلم"], ["formation", "workshop"]),
    ("job", ["emploi", "travail", "job", "خدمه", "نخدم", "khdma"], ["job", "program"]),
    ("support", ["aide", "financement", "دعم", "تمويل"], ["program", "support", "entrepreneurship"]),
]

DOMAINS = {
    "digital": ["informatique", "numerique", "ordinateur", "حاسوب", "معلوميات", "رقمي"],
    "agriculture": ["agriculture", "safran", "فلاحه", "زراعه"],
    "tourism": ["tourisme", "hotel", "سياحه", "فندق"],
    "commerce": ["commerce", "vente", "تجاره", "بيع"],
    "crafts": ["artisanat", "couture", "electricite", "خياطه", "حرفه"],
    "renewableEnergy": ["solaire", "energie", "طاقه"],
    "foodProcessing": ["cuisine", "argan", "طبخ", "اركان"],
}

NEAR = ["deplacer", "transport", "loin", "proche", "قريب", "بعيد", "نتنقل"]


class RuleBasedAssistant:
    name = "rule_based"

    def answer(self, message, profile, catalog, faq):
        text = normalize(message)
        is_ar = bool(ARABIC.search(message))

        for entry in faq:
            if any(normalize(k) in text for k in entry["keywords"]):
                return {"text": entry["answer"]["ar" if is_ar else "fr"], "results": [], "intent": "faq"}

        intent, types = next(((name, t) for name, kws, t in INTENTS if any(k in text for k in kws)), (None, None))
        domain = next((d for d, kws in DOMAINS.items() if any(k in text for k in kws)), None)
        near = any(k in text for k in NEAR)

        if intent is None and domain is None:
            return {
                "text": "باش نعاونك مزيان: واش كتقلب على تكوين، خدمة، ولا مواكبة؟" if is_ar
                else "Pour bien vous aider : cherchez-vous une formation, un emploi ou un accompagnement ?",
                "results": [], "intent": "clarify",
            }
        if profile is None:
            return {"text": "Complétez votre profil pour recevoir des propositions.", "results": [], "intent": intent}

        by_id = {o["id"]: o for o in catalog}
        ranked = recommendation.rank(catalog, profile)
        results = []
        for r in ranked:
            o = by_id[r["id"]]
            if types and o["type"] not in types:
                continue
            if domain and domain not in o.get("interests", []):
                continue
            if near and r["breakdown"]["proximity"] < 0.9 and o.get("modality") == "onSite":
                continue
            results.append({"id": r["id"], "score": r["score"]})
        results = results[:3]

        if is_ar:
            text = "حسب الملف ديالك، نقدر نقترح عليك فرص قريبة منك و مناسبة للمستوى ديالك." if results \
                else "ما لقيتش فرص بهاد الشروط دابا."
        else:
            text = "D'après votre profil, je peux vous proposer des opportunités accessibles dans votre zone et adaptées à votre niveau." \
                if results else "Je n'ai pas trouvé d'opportunité avec ces critères pour l'instant."
        return {"text": text, "results": results, "intent": intent or "explore", "domain": domain}


class _ChatProvider:
    """Shared retrieval-augmented call; subclasses only differ by endpoint."""

    name = "llm"

    def __init__(self, fallback):
        self.fallback = fallback

    def _complete(self, system, user):  # pragma: no cover - needs a live model
        raise NotImplementedError

    def answer(self, message, profile, catalog, faq):
        base = self.fallback.answer(message, profile, catalog, faq)
        by_id = {o["id"]: o for o in catalog}
        context = {
            "profile": profile,
            "candidates": [{**by_id[r["id"]], "score": r["score"]} for r in base["results"]],
            "faq": [f["answer"] for f in faq if any(normalize(k) in normalize(message) for k in f["keywords"])],
        }
        try:
            text = self._complete(SYSTEM_PROMPT, f"Question : {message}\n\nContexte : {json.dumps(context, ensure_ascii=False)}")
            return {**base, "text": text, "provider": self.name}
        except Exception:  # model down, quota, timeout: keep the rule-based answer
            return {**base, "provider": self.fallback.name}


class OpenAIProvider(_ChatProvider):  # pragma: no cover - needs network and a key
    name = "openai"

    def _complete(self, system, user):
        response = requests.post(
            "https://api.openai.com/v1/responses",
            headers={"Authorization": f"Bearer {os.environ['OPENAI_API_KEY']}"},
            json={"model": os.environ["OPENAI_MODEL"], "instructions": system, "input": user},
            timeout=20,
        )
        response.raise_for_status()
        data = response.json()
        return "".join(
            part.get("text", "")
            for item in data.get("output", [])
            for part in item.get("content", [])
            if part.get("type") == "output_text"
        )


class LocalLLMProvider(_ChatProvider):  # pragma: no cover - needs a running model
    name = "local"

    def _complete(self, system, user):
        response = requests.post(
            f"{os.environ['LOCAL_LLM_URL'].rstrip('/')}/v1/chat/completions",
            json={"model": os.environ["LOCAL_LLM_MODEL"],
                  "messages": [{"role": "system", "content": system}, {"role": "user", "content": user}]},
            timeout=30,
        )
        response.raise_for_status()
        return response.json()["choices"][0]["message"]["content"]


def build_provider(name):
    rules = RuleBasedAssistant()
    if name == "openai" and os.getenv("OPENAI_API_KEY") and os.getenv("OPENAI_MODEL"):
        return OpenAIProvider(rules)
    if name == "local" and os.getenv("LOCAL_LLM_URL") and os.getenv("LOCAL_LLM_MODEL"):
        return LocalLLMProvider(rules)
    return rules
