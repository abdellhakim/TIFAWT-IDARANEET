from flask import Blueprint, current_app, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required
from sqlalchemy import func

from . import recommendation
from .assistant import build_provider
from .auth import error, roles_required
from .catalog import catalog_items
from .extensions import db
from .models import (
    Application,
    AssistantFaq,
    Center,
    Favorite,
    Profile,
    ProgressEvent,
    SyncLog,
    User,
    UserBadge,
)
from .sync import apply_operations

bp = Blueprint("api", __name__, url_prefix="/api")

PROFILE_FIELDS = ("age", "province", "commune", "education", "objective", "interests", "skills",
                  "mobility", "internetAccess")


def _profile_data(user_id):
    row = db.session.get(Profile, user_id)
    return row.data if row else None


@bp.get("/health")
def health():
    return jsonify({"status": "ok"})


@bp.get("/profile")
@jwt_required()
def get_profile():
    data = _profile_data(get_jwt_identity())
    return jsonify({"profile": data}) if data else error("profile not found", 404)


@bp.put("/profile")
@jwt_required()
def put_profile():
    body = request.get_json(silent=True) or {}
    missing = [f for f in PROFILE_FIELDS if f not in body]
    if missing:
        return error(f"missing fields: {', '.join(missing)}", 400)
    user_id = get_jwt_identity()
    row = db.session.get(Profile, user_id) or Profile(user_id=user_id)
    row.data = {**body, "userId": user_id}
    row.province = body["province"]
    row.completed = bool(body.get("completed", True))
    db.session.add(row)
    db.session.commit()
    return jsonify({"profile": row.data})


@bp.get("/opportunities")
def opportunities():
    items = catalog_items()
    province = request.args.get("province")
    if province:
        items = [o for o in items if o.get("province") in (province, None)]
    return jsonify({"items": items})


@bp.get("/recommendations")
@jwt_required()
def recommendations():
    profile = _profile_data(get_jwt_identity())
    if profile is None:
        return error("complete the profile first", 409)
    ranked = recommendation.rank(catalog_items(), profile)
    return jsonify({
        "weights": recommendation.WEIGHTS,
        "items": [r for r in ranked if r["score"] >= recommendation.RECOMMENDED_THRESHOLD],
    })


@bp.get("/progress")
@jwt_required()
def get_progress():
    user_id = get_jwt_identity()
    applications = Application.query.filter_by(user_id=user_id).all()
    events = ProgressEvent.query.filter_by(user_id=user_id).order_by(ProgressEvent.at).all()
    return jsonify({
        "applications": [{"opportunityId": a.opportunity_id, "status": a.status,
                          "updatedAt": a.updated_at.isoformat()} for a in applications],
        "events": [{"id": e.id, "type": e.type, "opportunityId": e.opportunity_id,
                    "status": e.status, "at": e.at.isoformat()} for e in events],
    })


@bp.post("/progress")
@jwt_required()
def post_progress():
    """Direct (online) variant of the sync path for a single status change."""
    body = request.get_json(silent=True) or {}
    results = apply_operations(get_jwt_identity(), [{
        "id": body.get("id"), "entity": "application", "operation": "UPDATE",
        "timestamp": body.get("timestamp"), "payload": body,
    }])
    status = 200 if results[0]["status"] in ("ok", "duplicate") else 400
    return jsonify(results[0]), status


@bp.get("/badges")
@jwt_required()
def badges():
    rows = UserBadge.query.filter_by(user_id=get_jwt_identity()).all()
    return jsonify({"badges": [{"code": b.code, "earnedAt": b.earned_at.isoformat()} for b in rows]})


@bp.get("/centers")
def centers():
    return jsonify({"items": [c.data for c in Center.query.order_by(Center.id).all()]})


@bp.post("/assistant/message")
@jwt_required()
def assistant_message():
    message = ((request.get_json(silent=True) or {}).get("message") or "").strip()
    if not message:
        return error("empty message", 400)
    provider = build_provider(current_app.config["ASSISTANT_PROVIDER"])
    faq = [f.data for f in AssistantFaq.query.all()]
    reply = provider.answer(message, _profile_data(get_jwt_identity()), catalog_items(), faq)
    return jsonify(reply)


@bp.post("/sync")
@jwt_required()
def sync():
    operations = (request.get_json(silent=True) or {}).get("operations")
    if not isinstance(operations, list):
        return error("operations must be a list", 400)
    if len(operations) > current_app.config["MAX_SYNC_BATCH"]:
        return error("batch too large", 413)
    return jsonify({"results": apply_operations(get_jwt_identity(), operations)})


@bp.get("/admin/stats")
@roles_required("admin", "institution", "association")
def stats():
    """Territorial follow-up for institutions — aggregated, no personal data."""
    by_province = dict(db.session.query(Profile.province, func.count()).group_by(Profile.province).all())
    by_status = dict(db.session.query(Application.status, func.count()).group_by(Application.status).all())
    popular = db.session.query(Application.opportunity_id, func.count()).group_by(
        Application.opportunity_id).order_by(func.count().desc()).limit(5).all()
    return jsonify({
        "youth": User.query.filter_by(role="youth").count(),
        "profilesByProvince": by_province,
        "applicationsByStatus": by_status,
        "topOpportunities": [{"id": i, "count": c} for i, c in popular],
        "savedOpportunities": Favorite.query.count(),
        "syncedOperations": SyncLog.query.filter_by(status="ok").count(),
    })
