"""User registration, login, logout and profile."""
from flask import Blueprint, render_template, request, redirect, url_for, flash, session

from utils.database import query_one, query_all, execute
from utils.auth import (
    hash_password, verify_password, login_user, logout_user, login_required, current_user,
)
from utils.validation import validate_registration, clean, EMAIL_RE
from utils.helpers import awareness_level

auth_bp = Blueprint("auth", __name__)


@auth_bp.route("/register", methods=["GET", "POST"])
def register():
    errors, data = {}, {}
    if request.method == "POST":
        data, errors = validate_registration(request.form)
        if not errors:
            if query_one("SELECT id FROM users WHERE email = %s", (data["email"],)):
                errors["email"] = "An account already exists with this email address."
            else:
                user_id = execute(
                    "INSERT INTO users (full_name, email, password_hash, age_group, occupation, city) "
                    "VALUES (%s, %s, %s, %s, %s, %s)",
                    (
                        data["full_name"], data["email"], hash_password(data["password"]),
                        data["age_group"] or None, data["occupation"] or None, data["city"] or None,
                    ),
                )
                login_user({"id": user_id, "full_name": data["full_name"]}, role="user")
                flash("Welcome aboard. Start with the pre-test to measure your current awareness.", "success")
                return redirect(url_for("quiz.pre_test"))
        flash("Please correct the highlighted fields.", "error")
    return render_template("register.html", errors=errors, data=data)


@auth_bp.route("/login", methods=["GET", "POST"])
def login():
    errors = {}
    email = ""
    if request.method == "POST":
        email = clean(request.form.get("email"), 120).lower()
        password = request.form.get("password") or ""
        if not EMAIL_RE.match(email):
            errors["email"] = "Please enter a valid email address."
        if not password:
            errors["password"] = "Please enter your password."
        if not errors:
            user = query_one(
                "SELECT id, full_name, password_hash, is_active FROM users WHERE email = %s", (email,)
            )
            if not user or not verify_password(user["password_hash"], password):
                flash("Email or password is incorrect.", "error")
            elif not user["is_active"]:
                flash("This account has been deactivated. Please contact the administrator.", "error")
            else:
                login_user(user, role="user")
                flash(f"Signed in successfully. Welcome back, {user['full_name'].split()[0]}.", "success")
                nxt = request.args.get("next")
                return redirect(nxt if nxt and nxt.startswith("/") else url_for("main.index"))
        else:
            flash("Please correct the highlighted fields.", "error")
    return render_template("login.html", errors=errors, email=email)


@auth_bp.route("/logout", methods=["POST"])
def logout():
    logout_user()
    flash("You have been signed out.", "info")
    return redirect(url_for("main.index"))


@auth_bp.route("/profile")
@login_required
def profile():
    user = current_user()
    attempts = query_all(
        "SELECT * FROM quiz_attempts WHERE user_id = %s ORDER BY attempted_at DESC", (user["id"],)
    )
    pre = next((a for a in attempts if a["quiz_type"] == "pre"), None)
    post = next((a for a in attempts if a["quiz_type"] == "post"), None)
    spot = next((a for a in attempts if a["quiz_type"] == "spot"), None)
    improvement = (post["percentage"] - pre["percentage"]) if (pre and post) else None

    total_categories = (query_one("SELECT COUNT(*) c FROM scam_categories WHERE is_active = 1") or {})["c"]
    read_categories = (query_one(
        "SELECT COUNT(*) c FROM user_progress WHERE user_id = %s", (user["id"],)
    ) or {})["c"]
    progress_percent = round((read_categories / total_categories) * 100) if total_categories else 0

    return render_template(
        "profile.html",
        user=user,
        attempts=attempts,
        pre=pre,
        post=post,
        spot=spot,
        improvement=improvement,
        progress_percent=progress_percent,
        read_categories=read_categories,
        total_categories=total_categories,
        level=awareness_level(post["percentage"] if post else (pre["percentage"] if pre else 0)),
    )
