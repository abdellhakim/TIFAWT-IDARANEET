"""Explainable rule-based recommendation engine.

Score = 25% objective + 20% level + 20% interests + 15% skills
      + 10% proximity + 10% constraints, normalised to 0..100.

Exact mirror of lib/features/recommendations/domain/recommendation_engine.dart
so the device (offline) and the server always agree on a score.
"""
from datetime import date

WEIGHTS = {"objective": 25, "level": 20, "interests": 20, "skills": 15, "proximity": 10, "constraints": 10}
RECOMMENDED_THRESHOLD = 60

EDUCATION = ["none", "primary", "middle", "bac", "higher"]
MOBILITY = ["commune", "province", "region", "anywhere"]
INTERNET = ["none", "occasional", "regular"]

RELATED = {
    "training": {"skills", "employment", "studies"},
    "skills": {"training", "entrepreneurship"},
    "employment": {"training"},
    "studies": {"training"},
    "entrepreneurship": {"skills"},
}


def _idx(values, value, default=0):
    try:
        return values.index(value)
    except ValueError:
        return default


def _objective(o, p):
    objectives = o.get("objectives") or []
    if not objectives:
        return 0.5
    if p["objective"] in objectives:
        return 1.0
    return 0.5 if RELATED.get(p["objective"], set()) & set(objectives) else 0.0


def _level(o, p):
    gap = _idx(EDUCATION, p["education"]) - _idx(EDUCATION, o.get("requiredLevel", "none"))
    if gap == 0:
        return 1.0
    if gap == 1:
        return 0.9
    if gap > 1:
        return 0.75
    return 0.4 if gap == -1 else 0.0


def _interests(o, p):
    wanted = o.get("interests") or []
    if not wanted:
        return 0.5
    overlap = len([i for i in wanted if i in p.get("interests", [])])
    return 0.0 if overlap == 0 else 0.6 + 0.4 * overlap / len(wanted)


def _skills(o, p):
    wanted = o.get("skills") or []
    if not wanted:
        return 0.6
    overlap = len([s for s in wanted if s in p.get("skills", [])])
    return 0.4 + 0.6 * overlap / len(wanted)


def _proximity(o, p):
    if o.get("province") is None or o.get("modality") == "remote":
        return 1.0
    mobility = _idx(MOBILITY, p["mobility"])
    if o["province"] == p["province"] and o.get("commune") == p.get("commune"):
        return 1.0
    if o["province"] == p["province"]:
        return 0.9 if mobility >= MOBILITY.index("province") else 0.6
    if mobility >= MOBILITY.index("region"):
        return 0.7
    return 0.3 if p["mobility"] == "province" else 0.1


def _constraints(o, p):
    modality, pref = o.get("modality", "onSite"), p.get("modality", "any")
    checks = [
        1.0 if _idx(INTERNET, p["internetAccess"]) >= _idx(INTERNET, o.get("internetRequired", "none")) else 0.0,
        1.0 if _idx(MOBILITY, p["mobility"]) >= _idx(MOBILITY, o.get("mobilityRequired", "commune")) else 0.4,
        1.0 if pref == "any" or modality == "hybrid" or (pref, modality) in {("onSite", "onSite"), ("remote", "remote")} else 0.5,
        1.0 if o.get("ageMin", 15) <= p["age"] <= o.get("ageMax", 34) else 0.0,
        0.5 if p.get("availability") == "weekends" and o.get("type") != "workshop" else 1.0,
    ]
    return sum(checks) / len(checks)


def evaluate(o, p, today=None):
    """Returns {id, score, breakdown, reasons, warnings} for one opportunity."""
    b = {
        "objective": _objective(o, p),
        "level": _level(o, p),
        "interests": _interests(o, p),
        "skills": _skills(o, p),
        "proximity": _proximity(o, p),
        "constraints": _constraints(o, p),
    }
    # Half-up rounding, like Dart's round() (Python's round() is half-even).
    score = max(0, min(100, int(sum(WEIGHTS[k] * v for k, v in b.items()) + 0.5)))

    remote = o.get("province") is None or o.get("modality") == "remote"
    reasons = []
    if b["objective"] == 1:
        reasons.append({"kind": "objective", "objective": p["objective"]})
    if b["interests"] >= 0.6:
        reasons.append({"kind": "interests", "interests": [i for i in o.get("interests", []) if i in p.get("interests", [])]})
    if b["level"] >= 0.9:
        reasons.append({"kind": "level"})
    if remote:
        reasons.append({"kind": "remote"})
    elif b["proximity"] >= 0.9:
        reasons.append({"kind": "zone", "commune": o.get("commune")})
    if b["skills"] >= 0.8:
        reasons.append({"kind": "skills", "skills": [s for s in o.get("skills", []) if s in p.get("skills", [])]})

    warnings = []
    if o.get("province") is not None and b["proximity"] < 0.7:
        warnings.append({"kind": "travel", "province": o["province"]})
    if _idx(INTERNET, p["internetAccess"]) < _idx(INTERNET, o.get("internetRequired", "none")):
        warnings.append({"kind": "internet"})
    if _idx(EDUCATION, p["education"]) < _idx(EDUCATION, o.get("requiredLevel", "none")):
        warnings.append({"kind": "level", "level": o.get("requiredLevel")})
    if not o.get("ageMin", 15) <= p["age"] <= o.get("ageMax", 34):
        warnings.append({"kind": "age", "ageMin": o.get("ageMin"), "ageMax": o.get("ageMax")})

    return {"id": o["id"], "score": score, "breakdown": b, "reasons": reasons, "warnings": warnings}


def is_open(o, today=None):
    deadline = o.get("deadline")
    if not deadline:
        return True
    return (today or date.today()) <= date.fromisoformat(deadline)


def rank(catalog, profile, today=None):
    results = [evaluate(o, profile, today) for o in catalog if is_open(o, today)]
    return sorted(results, key=lambda r: r["score"], reverse=True)
