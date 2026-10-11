"""Relational model (PostgreSQL target).

Catalog rows keep the full JSON document shared with the mobile app in a
`data` column; the columns used for filtering or joins are duplicated.
"""
from datetime import datetime, timezone

from .extensions import db


def utcnow():
    return datetime.now(timezone.utc)


ROLES = ("youth", "association", "institution", "company", "admin")


class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.String(64), primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    name_latin = db.Column(db.String(120))
    phone = db.Column(db.String(20), unique=True)
    email = db.Column(db.String(160), unique=True)
    password_hash = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(20), nullable=False, default="youth")
    created_at = db.Column(db.DateTime(timezone=True), default=utcnow)

    def to_json(self):
        return {
            "id": self.id,
            "name": self.name,
            "nameLatin": self.name_latin,
            "phone": self.phone,
            "email": self.email,
            "role": self.role,
        }


class Profile(db.Model):
    __tablename__ = "profiles"

    user_id = db.Column(db.String(64), db.ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    data = db.Column(db.JSON, nullable=False)
    province = db.Column(db.String(20))
    completed = db.Column(db.Boolean, default=False)
    updated_at = db.Column(db.DateTime(timezone=True), default=utcnow)


class Organization(db.Model):
    __tablename__ = "organizations"

    id = db.Column(db.String(64), primary_key=True)
    name = db.Column(db.String(120), nullable=False)


class Opportunity(db.Model):
    __tablename__ = "opportunities"

    id = db.Column(db.String(64), primary_key=True)
    type = db.Column(db.String(30), nullable=False)
    organization_id = db.Column(db.String(64), db.ForeignKey("organizations.id"))
    province = db.Column(db.String(20))
    data = db.Column(db.JSON, nullable=False)
    updated_at = db.Column(db.DateTime(timezone=True), default=utcnow)


class Center(db.Model):
    __tablename__ = "centers"

    id = db.Column(db.String(64), primary_key=True)
    province = db.Column(db.String(20))
    data = db.Column(db.JSON, nullable=False)


class AssistantFaq(db.Model):
    __tablename__ = "assistant_faq"

    id = db.Column(db.String(64), primary_key=True)
    data = db.Column(db.JSON, nullable=False)


class Application(db.Model):
    """An opportunity selected by a youth ("Je suis intéressée") and its status."""

    __tablename__ = "applications"
    __table_args__ = (db.UniqueConstraint("user_id", "opportunity_id"),)

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.String(64), db.ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    opportunity_id = db.Column(db.String(64), db.ForeignKey("opportunities.id"), nullable=False)
    status = db.Column(db.String(20), nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), default=utcnow)
    updated_at = db.Column(db.DateTime(timezone=True), default=utcnow)


class ProgressEvent(db.Model):
    __tablename__ = "progress"

    id = db.Column(db.String(64), primary_key=True)  # generated on the device
    user_id = db.Column(db.String(64), db.ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    type = db.Column(db.String(30), nullable=False)
    opportunity_id = db.Column(db.String(64))
    status = db.Column(db.String(20))
    at = db.Column(db.DateTime(timezone=True), nullable=False)


class UserBadge(db.Model):
    __tablename__ = "badges"

    user_id = db.Column(db.String(64), db.ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    code = db.Column(db.String(40), primary_key=True)
    earned_at = db.Column(db.DateTime(timezone=True), default=utcnow)


class Favorite(db.Model):
    __tablename__ = "favorites"

    user_id = db.Column(db.String(64), db.ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    opportunity_id = db.Column(db.String(64), primary_key=True)


class UserDocuments(db.Model):
    __tablename__ = "documents"

    user_id = db.Column(db.String(64), db.ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    data = db.Column(db.JSON, nullable=False)


class SyncLog(db.Model):
    """One row per operation received from a device; makes /api/sync idempotent."""

    __tablename__ = "sync_logs"

    id = db.Column(db.String(64), primary_key=True)  # operation id from the device queue
    user_id = db.Column(db.String(64), nullable=False, index=True)
    entity = db.Column(db.String(30), nullable=False)
    operation = db.Column(db.String(20), nullable=False)
    client_timestamp = db.Column(db.DateTime(timezone=True))
    received_at = db.Column(db.DateTime(timezone=True), default=utcnow)
    status = db.Column(db.String(20), nullable=False)
    error = db.Column(db.String(200))
