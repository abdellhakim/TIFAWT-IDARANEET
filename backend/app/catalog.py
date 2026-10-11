"""Seeds the database from the JSON files shared with the mobile app."""
import json
import re

from werkzeug.security import generate_password_hash

from .config import DATA_DIR
from .extensions import db
from .models import AssistantFaq, Center, Opportunity, Organization, Profile, User


def _load(name):
    with open(DATA_DIR / name, encoding="utf-8") as f:
        return json.load(f)


def _slug(text):
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def seed_catalog():
    for item in _load("opportunities.json")["items"]:
        org_id = _slug(item["organization"])
        if db.session.get(Organization, org_id) is None:
            db.session.add(Organization(id=org_id, name=item["organization"]))
        db.session.merge(Opportunity(
            id=item["id"],
            type=item["type"],
            organization_id=org_id,
            province=item.get("province"),
            data=item,
        ))
    for item in _load("centers.json")["items"]:
        db.session.merge(Center(id=item["id"], province=item["province"], data=item))
    for item in _load("assistant_knowledge.json")["faq"]:
        db.session.merge(AssistantFaq(id=item["id"], data=item))
    db.session.commit()


DEMO_USER_ID = "demo-chahd"


def seed_demo_user():
    """Same fictional persona as the app (lib/core/storage/demo_seed.dart)."""
    if db.session.get(User, DEMO_USER_ID):
        return
    db.session.add(User(
        id=DEMO_USER_ID,
        name="شهد أمزيان",
        name_latin="Chahd Amzian",
        phone="0600000000",
        email="chahd@tifawt.ma",
        password_hash=generate_password_hash("123456"),
        role="youth",
    ))
    db.session.add(Profile(
        user_id=DEMO_USER_ID,
        province="taroudant",
        completed=False,
        data={
            "userId": DEMO_USER_ID, "age": 21, "sex": "female", "province": "taroudant",
            "commune": "Taroudant", "situation": "trainingSeeking", "education": "bac",
            "lastDiploma": "bac", "vocationalTraining": "", "objective": "training",
            "interests": ["digital", "commerce"], "skills": ["communication", "languages"],
            "mobility": "commune", "internetAccess": "occasional", "connectionType": "mobile3g",
            "availability": "fullTime", "modality": "any", "completed": False,
        },
    ))
    db.session.commit()


def catalog_items():
    return [o.data for o in Opportunity.query.order_by(Opportunity.id).all()]
