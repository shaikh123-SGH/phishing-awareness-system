"""Authentication, password hashing, session handling and role guards."""
import secrets
from functools import wraps

from flask import session, redirect, url_for, flash, request, abort
from werkzeug.security import generate_password_hash, check_password_hash

from utils.database import query_one


def hash_password(raw_password: str) -> str:
    return generate_password_hash(raw_password, method="pbkdf2:sha256", salt_length=16)


def verify_password(password_hash: str, raw_password: str) -> bool:
    return check_password_hash(password_hash, raw_password)


def login_user(user_row, role="user"):
    session.clear()
    session.permanent = True
    session["user_id"] = user_row["id"]
    session["full_name"] = user_row["full_name"]
    session["role"] = role
    session["csrf_token"] = secrets.token_urlsafe(32)


def logout_user():
    session.clear()


def current_user():
    if "user_id" not in session or session.get("role") != "user":
        return None
    return query_one(
        "SELECT id, full_name, email, age_group, occupation, city, is_active, created_at "
        "FROM users WHERE id = %s",
        (session["user_id"],),
    )


def current_admin():
    if "user_id" not in session or session.get("role") != "admin":
        return None
    return query_one(
        "SELECT id, full_name, email FROM admins WHERE id = %s", (session["user_id"],)
    )


def login_required(view):
    @wraps(view)
    def wrapper(*args, **kwargs):
        if session.get("role") != "user":
            flash("Please log in to continue.", "warning")
            return redirect(url_for("auth.login", next=request.path))
        return view(*args, **kwargs)

    return wrapper


def admin_required(view):
    @wraps(view)
    def wrapper(*args, **kwargs):
        if session.get("role") != "admin":
            return redirect(url_for("admin.login"))
        return view(*args, **kwargs)

    return wrapper


def get_csrf_token():
    if "csrf_token" not in session:
        session["csrf_token"] = secrets.token_urlsafe(32)
    return session["csrf_token"]


def validate_csrf():
    """Called before every state-changing request."""
    if request.method in ("POST", "PUT", "PATCH", "DELETE"):
        sent = request.form.get("csrf_token") or request.headers.get("X-CSRF-Token")
        if not sent or not secrets.compare_digest(sent, session.get("csrf_token", "")):
            abort(400, description="Invalid or missing CSRF token.")
