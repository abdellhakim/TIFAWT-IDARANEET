"""Applies operations from a device's sync queue.

Each operation is validated, applied, and recorded in `sync_logs` under the
id generated on the device, so replaying the same batch is harmless
(network drops often cause retries).
"""
from datetime import datetime, timezone

from .extensions import db
from .models import (
    Application,
    Favorite,
    Opportunity,
    Profile,
    ProgressEvent,
    SyncLog,
    UserBadge,
    UserDocuments,
)

STATUSES = ("interested", "registered", "inTraining", "completed", "certified")
EVENT_TYPES = ("profileCompleted", "orientation", "opportunitySelected", "statusChanged")
BADGES = ("PROFILE_COMPLETED", "FIRST_RECOMMENDATION", "FIRST_OPPORTUNITY", "TRAINING_STARTED", "TRAINING_COMPLETED")


class InvalidOperation(ValueError):
    pass


def _parse_time(value):
    if not value:
        return datetime.now(timezone.utc)
    parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)


def _newer(incoming, stored):
    """Last write wins, on the device timestamp."""
    if stored is None:
        return True
    if stored.tzinfo is None:
        stored = stored.replace(tzinfo=timezone.utc)
    return incoming >= stored


def _profile(user_id, op, payload, at):
    if op != "UPDATE":
        raise InvalidOperation("profile supports UPDATE only")
    for field in ("age", "province", "education", "objective"):
        if field not in payload:
            raise InvalidOperation(f"profile.{field} missing")
    row = db.session.get(Profile, user_id)
    if row is None:
        row = Profile(user_id=user_id)
        db.session.add(row)
    elif not _newer(at, row.updated_at):
        return
    row.data = {**payload, "userId": user_id}
    row.province = payload["province"]
    row.completed = bool(payload.get("completed"))
    row.updated_at = at


def _application(user_id, op, payload, at):
    opportunity_id = payload.get("opportunityId")
    status = payload.get("status")
    if status not in STATUSES:
        raise InvalidOperation("unknown status")
    if db.session.get(Opportunity, opportunity_id) is None:
        raise InvalidOperation("unknown opportunity")
    row = Application.query.filter_by(user_id=user_id, opportunity_id=opportunity_id).first()
    if row is None:
        db.session.add(Application(user_id=user_id, opportunity_id=opportunity_id, status=status,
                                   created_at=at, updated_at=at))
    elif _newer(at, row.updated_at):
        row.status = status
        row.updated_at = at


def _progress_event(user_id, op, payload, at):
    if payload.get("type") not in EVENT_TYPES:
        raise InvalidOperation("unknown event type")
    if db.session.get(ProgressEvent, payload["id"]) is None:
        db.session.add(ProgressEvent(
            id=payload["id"], user_id=user_id, type=payload["type"],
            opportunity_id=payload.get("opportunityId"), status=payload.get("status"),
            at=_parse_time(payload.get("at")),
        ))


def _badge(user_id, op, payload, at):
    if payload.get("code") not in BADGES:
        raise InvalidOperation("unknown badge")
    if db.session.get(UserBadge, (user_id, payload["code"])) is None:
        db.session.add(UserBadge(user_id=user_id, code=payload["code"], earned_at=_parse_time(payload.get("earnedAt"))))


def _favorite(user_id, op, payload, at):
    key = (user_id, payload.get("opportunityId"))
    row = db.session.get(Favorite, key)
    if op == "CREATE" and row is None:
        db.session.add(Favorite(user_id=user_id, opportunity_id=key[1]))
    elif op == "DELETE" and row is not None:
        db.session.delete(row)


def _documents(user_id, op, payload, at):
    row = db.session.get(UserDocuments, user_id)
    if row is None:
        db.session.add(UserDocuments(user_id=user_id, data=payload.get("documents", [])))
    else:
        row.data = payload.get("documents", [])


HANDLERS = {
    "profile": _profile,
    "application": _application,
    "progress_event": _progress_event,
    "badge": _badge,
    "favorite": _favorite,
    "document": _documents,
}


def apply_operations(user_id, operations):
    results = []
    for op in operations:
        op_id = op.get("id")
        if not op_id:
            results.append({"id": None, "status": "error", "error": "missing id"})
            continue
        if db.session.get(SyncLog, op_id) is not None:
            results.append({"id": op_id, "status": "duplicate"})
            continue

        entity, operation = op.get("entity"), op.get("operation")
        handler = HANDLERS.get(entity)
        try:
            if handler is None:
                raise InvalidOperation(f"unsupported entity {entity}")
            at = _parse_time(op.get("timestamp"))
            with db.session.begin_nested():
                handler(user_id, operation, op.get("payload") or {}, at)
            status, error = "ok", None
        except (InvalidOperation, KeyError, TypeError, ValueError) as exc:
            status, error = "error", str(exc)[:200]

        db.session.add(SyncLog(id=op_id, user_id=user_id, entity=str(entity), operation=str(operation),
                               client_timestamp=_parse_time(op.get("timestamp")) if status == "ok" else None,
                               status=status, error=error))
        results.append({"id": op_id, "status": status, **({"error": error} if error else {})})

    db.session.commit()
    return results
