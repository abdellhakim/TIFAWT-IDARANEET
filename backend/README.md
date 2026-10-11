# API TIFAWT (Flask)

API REST qui reçoit la file de synchronisation de l'application et sert le catalogue, les
recommandations et l'assistant. Le catalogue est lu depuis `../assets/data/`, les mêmes
fichiers que l'application mobile.

## Démarrage

```bash
python -m venv .venv
.venv\Scripts\activate            # Windows
source .venv/bin/activate         # Linux / macOS
pip install -r requirements-dev.txt
cp .env.example .env              # puis renseigner JWT_SECRET_KEY
python run.py                     # http://localhost:5000
```

Sans `DATABASE_URL`, une base SQLite `tifawt.db` est créée et remplie au démarrage (catalogue,
centres, FAQ, compte de démonstration `0600000000` / `chahd@tifawt.ma`, mot de passe `123456`).
Pour PostgreSQL : `DATABASE_URL=postgresql+psycopg://user:pass@host:5432/tifawt`.

## Tests

```bash
pytest
```

Ils couvrent l'authentification (téléphone ou e-mail, doublons, rafraîchissement), la
synchronisation (scénario hors ligne complet, idempotence, dernier statut gagnant, opérations
invalides refusées), les recommandations (parité avec le moteur Dart : 92 % pour le parcours
nominal), l'assistant et le contrôle d'accès par rôle.

## Synchronisation

`POST /api/sync` avec `{"operations": [...]}` (200 opérations maximum). Entités acceptées :
`profile`, `application`, `progress_event`, `badge`, `favorite`, `document`. La réponse donne un
statut par opération : `ok`, `duplicate` (déjà reçue) ou `error` (avec la raison) ; l'application
ne supprime de sa file que ce qui est confirmé.

## Assistant

`ASSISTANT_PROVIDER=rule_based` par défaut. `openai` (avec `OPENAI_API_KEY` et `OPENAI_MODEL`) ou
`local` (avec `LOCAL_LLM_URL` et `LOCAL_LLM_MODEL`, API compatible OpenAI) ajoutent une
reformulation par un modèle, qui ne reçoit que le contexte récupéré ; en cas d'erreur la réponse
à base de règles est renvoyée. Ces fournisseurs n'ont pas été testés avec un modèle réel.
