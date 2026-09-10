"""
Phishing Scam & Fraud Detection Awareness Program
Application factory. Route logic lives in the blueprints/ package so that
this file stays small and readable.

Run locally:  python app.py
"""
import os

from flask import Flask, render_template, session

try:
    from dotenv import load_dotenv

    load_dotenv()
except ImportError:  # dotenv is optional
    pass

from config import get_config
from utils import database
from utils.auth import get_csrf_token, validate_csrf
from utils.helpers import register_template_helpers

from blueprints.main import main_bp
from blueprints.auth_routes import auth_bp
from blueprints.quiz import quiz_bp
from blueprints.admin import admin_bp


def create_app():
    app = Flask(__name__)
    app.config.from_object(get_config())
    os.makedirs(app.config["UPLOAD_FOLDER"], exist_ok=True)

    database.init_app(app)
    register_template_helpers(app)

    # CSRF protection for every state-changing request in the application.
    @app.before_request
    def _csrf_guard():
        validate_csrf()

    # Values available inside every template.
    @app.context_processor
    def _inject_globals():
        return {
            "csrf_token": get_csrf_token(),
            "session_user": {
                "id": session.get("user_id"),
                "name": session.get("full_name"),
                "role": session.get("role"),
            },
        }

    app.register_blueprint(main_bp)
    app.register_blueprint(auth_bp)
    app.register_blueprint(quiz_bp)
    app.register_blueprint(admin_bp)

    @app.errorhandler(404)
    def _not_found(_e):
        return render_template("errors/404.html"), 404

    @app.errorhandler(400)
    def _bad_request(e):
        return render_template("errors/400.html", message=getattr(e, "description", "")), 400

    @app.errorhandler(500)
    def _server_error(_e):
        return render_template("errors/500.html"), 500

    return app


app = create_app()

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=app.config.get("DEBUG", True))
