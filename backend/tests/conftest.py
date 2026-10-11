import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app import create_app  # noqa: E402
from app.config import TestConfig  # noqa: E402
from app.extensions import db  # noqa: E402


@pytest.fixture()
def app():
    app = create_app(TestConfig)
    yield app
    with app.app_context():
        db.drop_all()


@pytest.fixture()
def client(app):
    return app.test_client()


@pytest.fixture()
def demo_token(client):
    response = client.post("/api/auth/login", json={"identifier": "0600000000", "password": "123456"})
    return response.get_json()["access_token"]


@pytest.fixture()
def auth(demo_token):
    return {"Authorization": f"Bearer {demo_token}"}
