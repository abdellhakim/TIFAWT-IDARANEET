import re
import uuid
from functools import wraps

from flask import Blueprint, jsonify, request
from flask_jwt_extended import (
    create_access_token,
    create_refresh_token,
    get_jwt,
    get_jwt_identity,
    jwt_required,
    verify_jwt_in_request,
)
from werkzeug.security import check_password_hash, generate_password_hash

from .extensions import db
from .models import User

bp = Blueprint("auth", __name__, url_prefix="/api/auth")

EMAIL = re.compile(r"^[^@\s]+@[^@\s]+\.[a-z]{2,}$")
PHONE = re.compile(r"^(\+212|0)[5-7]\d{8}$")


def normalize_identifier(raw):
    value = (raw or "").strip().lower()
    return value if "@" in value else re.sub(r"[\s.\-]", "", value)


def _find(identifier):
    if EMAIL.match(identifier):
        return User.query.filter_by(email=identifier).first()
    return User.query.filter_by(phone=identifier).first()


def _tokens(user):
    claims = {"role": user.role}
    return {
        "access_token": create_access_token(identity=user.id, additional_claims=claims),
        "refresh_token": create_refresh_token(identity=user.id, additional_claims=claims),
        "user": user.to_json(),
    }


def error(message, status):
    return jsonify({"error": message}), status


@bp.post("/register")
def register():
    body = request.get_json(silent=True) or {}
    name = (body.get("name") or "").strip()
    identifier = normalize_identifier(body.get("identifier"))
    password = body.get("password") or ""

    if len(name) < 2 or len(password) < 6:
        return error("invalid name or password", 400)
    is_email = bool(EMAIL.match(identifier))
    if not is_email and not PHONE.match(identifier):
        return error("invalid phone or e-mail", 400)
    if _find(identifier):
        return error("account already exists", 409)

    user = User(
        # Accounts created offline keep the id generated on the device.
        id=body.get("id") or str(uuid.uuid4()),
        name=name,
        email=identifier if is_email else None,
        phone=None if is_email else identifier,
        password_hash=generate_password_hash(password),
    )
    db.session.add(user)
    db.session.commit()
    return jsonify(_tokens(user)), 201


@bp.post("/login")
def login():
    body = request.get_json(silent=True) or {}
    user = _find(normalize_identifier(body.get("identifier")))
    if user is None or not check_password_hash(user.password_hash, body.get("password") or ""):
        return error("invalid credentials", 401)
    return jsonify(_tokens(user))


@bp.post("/refresh")
@jwt_required(refresh=True)
def refresh():
    user = db.session.get(User, get_jwt_identity())
    if user is None:
        return error("unknown user", 401)
    return jsonify({"access_token": create_access_token(identity=user.id, additional_claims={"role": user.role})})


def roles_required(*roles):
    """Role-based access control for association / institution / admin endpoints."""

    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            verify_jwt_in_request()
            if get_jwt().get("role") not in roles:
                return error("forbidden", 403)
            return fn(*args, **kwargs)

        return wrapper

    return decorator
