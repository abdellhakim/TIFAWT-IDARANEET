import os
from datetime import timedelta
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
# Catalog files shared with the mobile app.
DATA_DIR = Path(os.getenv("TIFAWT_DATA_DIR", BASE_DIR.parent / "assets" / "data"))


class Config:
    SQLALCHEMY_DATABASE_URI = os.getenv("DATABASE_URL") or f"sqlite:///{BASE_DIR / 'tifawt.db'}"
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "dev-only-change-me")
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=1)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)

    # Comma-separated origins; by default any localhost port (development only).
    CORS_ORIGINS = [o.strip() for o in os.getenv("CORS_ORIGINS", "").split(",") if o.strip()] or [r"http://localhost:\d+"]
    ASSISTANT_PROVIDER = os.getenv("ASSISTANT_PROVIDER", "rule_based")

    # Sync: refuse absurd batches.
    MAX_SYNC_BATCH = 200


class TestConfig(Config):
    TESTING = True
    SQLALCHEMY_DATABASE_URI = "sqlite:///:memory:"
    JWT_SECRET_KEY = "test-secret-key-with-enough-length-for-hs256"
