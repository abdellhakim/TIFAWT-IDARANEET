import json
from datetime import date

from app import recommendation
from app.config import DATA_DIR

CHAHD = {
    "age": 21, "sex": "female", "province": "taroudant", "commune": "Taroudant",
    "situation": "trainingSeeking", "education": "bac", "lastDiploma": "bac", "objective": "training",
    "interests": ["digital", "commerce"], "skills": ["communication", "languages"], "mobility": "commune",
    "internetAccess": "occasional", "connectionType": "mobile3g", "availability": "fullTime", "modality": "any",
}


def catalog():
    with open(DATA_DIR / "opportunities.json", encoding="utf-8") as f:
        return json.load(f)["items"]


def op(op_id, entity, operation, payload, ts="2026-10-10T10:00:00Z"):
    return {"id": op_id, "entity": entity, "operation": operation, "timestamp": ts, "payload": payload}


# ── Recommendation engine (parity with the Dart engine) ───────────────────


def test_engine_matches_the_mobile_app():
    ranked = recommendation.rank(catalog(), CHAHD, today=date(2026, 10, 10))
    top = ranked[0]
    assert top["id"] == "op_numerique_init"
    assert top["score"] == 92  # same value asserted in test/recommendation_engine_test.dart
    assert [r["kind"] for r in top["reasons"]] == ["objective", "interests", "level", "zone"]


def test_weights_follow_the_specification():
    assert recommendation.WEIGHTS == {"objective": 25, "level": 20, "interests": 20, "skills": 15,
                                      "proximity": 10, "constraints": 10}


# ── Authentication ──────────────────────────────────────────────────────


def test_demo_login_with_phone_or_email(client):
    for identifier in ("0600000000", "chahd@tifawt.ma", " CHAHD@tifawt.ma "):
        response = client.post("/api/auth/login", json={"identifier": identifier, "password": "123456"})
        assert response.status_code == 200
        assert response.get_json()["user"]["nameLatin"] == "Chahd Amzian"


def test_wrong_password_is_rejected(client):
    response = client.post("/api/auth/login", json={"identifier": "0600000000", "password": "nope"})
    assert response.status_code == 401


def test_register_keeps_the_device_id_and_refuses_duplicates(client):
    body = {"id": "device-uuid-1", "name": "Youssef", "identifier": "0611223344", "password": "secret1"}
    first = client.post("/api/auth/register", json=body)
    assert first.status_code == 201
    assert first.get_json()["user"]["id"] == "device-uuid-1"
    assert client.post("/api/auth/register", json=body).status_code == 409


def test_refresh_token(client):
    tokens = client.post("/api/auth/login", json={"identifier": "0600000000", "password": "123456"}).get_json()
    response = client.post("/api/auth/refresh", headers={"Authorization": f"Bearer {tokens['refresh_token']}"})
    assert response.status_code == 200 and "access_token" in response.get_json()


def test_protected_routes_need_a_token(client):
    assert client.get("/api/profile").status_code == 401
    assert client.post("/api/sync", json={"operations": []}).status_code == 401


# ── Sync queue ──────────────────────────────────────────────────────────


def test_sync_applies_the_offline_scenario(client, auth):
    operations = [
        op("o1", "application", "CREATE", {"opportunityId": "op_numerique_init", "status": "interested"}),
        op("o2", "progress_event", "CREATE", {"id": "e1", "type": "opportunitySelected",
                                               "opportunityId": "op_numerique_init", "at": "2026-10-10T10:00:00"}),
        op("o3", "application", "UPDATE", {"opportunityId": "op_numerique_init", "status": "registered"},
           ts="2026-10-10T10:05:00Z"),
        op("o4", "badge", "CREATE", {"code": "FIRST_OPPORTUNITY", "earnedAt": "2026-10-10T10:00:01Z"}),
    ]
    response = client.post("/api/sync", json={"operations": operations}, headers=auth)
    assert [r["status"] for r in response.get_json()["results"]] == ["ok"] * 4

    progress = client.get("/api/progress", headers=auth).get_json()
    assert progress["applications"][0]["status"] == "registered"
    assert progress["events"][0]["type"] == "opportunitySelected"
    assert client.get("/api/badges", headers=auth).get_json()["badges"][0]["code"] == "FIRST_OPPORTUNITY"


def test_sync_is_idempotent(client, auth):
    batch = [op("dup-1", "favorite", "CREATE", {"opportunityId": "op_metier_technique"})]
    client.post("/api/sync", json={"operations": batch}, headers=auth)
    again = client.post("/api/sync", json={"operations": batch}, headers=auth).get_json()
    assert again["results"][0]["status"] == "duplicate"


def test_older_status_does_not_overwrite_a_newer_one(client, auth):
    client.post("/api/sync", json={"operations": [
        op("n1", "application", "CREATE", {"opportunityId": "op_numerique_init", "status": "registered"},
           ts="2026-10-10T12:00:00Z"),
        op("n2", "application", "UPDATE", {"opportunityId": "op_numerique_init", "status": "interested"},
           ts="2026-10-10T09:00:00Z"),
    ]}, headers=auth)
    progress = client.get("/api/progress", headers=auth).get_json()
    assert progress["applications"][0]["status"] == "registered"


def test_invalid_operations_are_reported_not_applied(client, auth):
    results = client.post("/api/sync", json={"operations": [
        op("b1", "application", "CREATE", {"opportunityId": "does-not-exist", "status": "interested"}),
        op("b2", "application", "CREATE", {"opportunityId": "op_numerique_init", "status": "hired"}),
        op("b3", "unknown", "CREATE", {}),
    ]}, headers=auth).get_json()["results"]
    assert [r["status"] for r in results] == ["error"] * 3
    assert client.get("/api/progress", headers=auth).get_json()["applications"] == []


def test_profile_sync_then_recommendations(client, auth):
    client.post("/api/sync", json={"operations": [
        op("p1", "profile", "UPDATE", {**CHAHD, "completed": True}),
    ]}, headers=auth)
    items = client.get("/api/recommendations", headers=auth).get_json()["items"]
    assert items[0]["id"] == "op_numerique_init"


# ── Assistant, catalog, roles ───────────────────────────────────────────


def test_assistant_answers_the_parcours_question(client, auth):
    reply = client.post("/api/assistant/message", headers=auth, json={
        "message": "Je cherche une formation en informatique mais je n'ai pas beaucoup de moyens pour me déplacer.",
    }).get_json()
    assert reply["intent"] == "training"
    assert reply["results"][0] == {"id": "op_numerique_init", "score": 92}
    assert reply["text"].startswith("D'après votre profil")


def test_catalog_is_public_and_filterable(client):
    items = client.get("/api/opportunities?province=tata").get_json()["items"]
    assert items and all(o["province"] in ("tata", None) for o in items)
    assert len(client.get("/api/centers").get_json()["items"]) == 5


def test_statistics_are_restricted_to_institutional_roles(client, auth):
    assert client.get("/api/admin/stats", headers=auth).status_code == 403
