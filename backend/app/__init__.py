from dotenv import load_dotenv
from flask import Flask, jsonify
from flask_cors import CORS

from .config import Config
from .extensions import db, jwt


def create_app(config=Config):
    load_dotenv()
    app = Flask(__name__)
    app.config.from_object(config)

    db.init_app(app)
    jwt.init_app(app)
    CORS(app, resources={r"/api/*": {"origins": app.config["CORS_ORIGINS"]}})

    from . import api, auth

    app.register_blueprint(auth.bp)
    app.register_blueprint(api.bp)

    @jwt.unauthorized_loader
    @jwt.invalid_token_loader
    def _unauthorized(reason):
        return jsonify({"error": reason}), 401

    @jwt.expired_token_loader
    def _expired(_header, _payload):
        return jsonify({"error": "token expired"}), 401

    with app.app_context():
        from .catalog import seed_catalog, seed_demo_user

        db.create_all()
        seed_catalog()
        seed_demo_user()

    return app
