"""Admin panel: dashboard analytics and CRUD for every content type."""
from flask import (
    Blueprint, render_template, request, redirect, url_for, flash, session, jsonify, abort,
)

from utils.database import query_all, query_one, execute
from utils.auth import (
    verify_password, login_user, logout_user, admin_required, current_admin,
)
from utils.validation import clean, validate_video, EMAIL_RE

admin_bp = Blueprint("admin", __name__, url_prefix="/admin")


# ----------------------------------------------------------------- auth -----
@admin_bp.route("/login", methods=["GET", "POST"])
def login():
    errors = {}
    if request.method == "POST":
        email = clean(request.form.get("email"), 120).lower()
        password = request.form.get("password") or ""
        if not EMAIL_RE.match(email):
            errors["email"] = "Enter a valid email address."
        if not errors:
            admin = query_one(
                "SELECT id, full_name, password_hash FROM admins WHERE email = %s", (email,)
            )
            if admin and verify_password(admin["password_hash"], password):
                login_user(admin, role="admin")
                flash("Administrator signed in.", "success")
                return redirect(url_for("admin.dashboard"))
            flash("Invalid administrator credentials.", "error")
    return render_template("admin/login.html", errors=errors)


@admin_bp.route("/logout", methods=["POST"])
def logout():
    logout_user()
    flash("Administrator signed out.", "info")
    return redirect(url_for("admin.login"))


# ------------------------------------------------------------ dashboard -----
def _avg(quiz_type):
    row = query_one(
        "SELECT AVG(percentage) a FROM quiz_attempts WHERE quiz_type = %s", (quiz_type,)
    )
    return round(row["a"]) if row and row["a"] is not None else 0


@admin_bp.route("/")
@admin_bp.route("/dashboard")
@admin_required
def dashboard():
    pre_avg, post_avg = _avg("pre"), _avg("post")
    stats = {
        "users": query_one("SELECT COUNT(*) c FROM users")["c"],
        "attempts": query_one("SELECT COUNT(*) c FROM quiz_attempts")["c"],
        "videos": query_one("SELECT COUNT(*) c FROM videos")["c"],
        "examples": query_one("SELECT COUNT(*) c FROM scam_examples")["c"],
        "categories": query_one("SELECT COUNT(*) c FROM scam_categories")["c"],
        "feedback": query_one("SELECT COUNT(*) c FROM feedback")["c"],
        "pre_avg": pre_avg,
        "post_avg": post_avg,
        "improvement": post_avg - pre_avg,
    }
    recent_users = query_all(
        "SELECT id, full_name, email, city, created_at FROM users ORDER BY created_at DESC LIMIT 6"
    )
    recent_feedback = query_all(
        "SELECT name, rating, message, created_at FROM feedback ORDER BY created_at DESC LIMIT 4"
    )
    return render_template(
        "admin/dashboard.html", admin=current_admin(), stats=stats,
        recent_users=recent_users, recent_feedback=recent_feedback,
    )


@admin_bp.route("/api/analytics")
@admin_required
def analytics_api():
    """Feeds the animated charts on the dashboard and reports pages."""
    participation = query_all(
        "SELECT DATE_FORMAT(attempted_at, '%%Y-%%m') AS period, COUNT(*) AS total "
        "FROM quiz_attempts GROUP BY period ORDER BY period"
    )
    performance = query_all(
        "SELECT quiz_type, ROUND(AVG(percentage)) AS avg_percent, COUNT(*) AS attempts "
        "FROM quiz_attempts GROUP BY quiz_type"
    )
    per_user = query_all(
        "SELECT u.full_name, "
        " MAX(CASE WHEN a.quiz_type='pre' THEN a.percentage END) AS pre_pct, "
        " MAX(CASE WHEN a.quiz_type='post' THEN a.percentage END) AS post_pct "
        "FROM users u JOIN quiz_attempts a ON a.user_id = u.id GROUP BY u.id ORDER BY u.id LIMIT 10"
    )
    category_awareness = query_all(
        "SELECT c.name, "
        " ROUND(100 * SUM(ans.is_correct) / NULLIF(COUNT(ans.id),0)) AS accuracy "
        "FROM scam_categories c "
        "LEFT JOIN quiz_questions q ON q.category_id = c.id "
        "LEFT JOIN quiz_answers ans ON ans.question_id = q.id "
        "GROUP BY c.id HAVING COUNT(ans.id) > 0 ORDER BY accuracy DESC"
    )
    return jsonify(
        {
            "participation": participation,
            "performance": performance,
            "per_user": per_user,
            "category_awareness": category_awareness,
        }
    )


@admin_bp.route("/reports")
@admin_required
def reports():
    return render_template("admin/reports.html", admin=current_admin())


# ---------------------------------------------------------------- users -----
@admin_bp.route("/users")
@admin_required
def users():
    search = (request.args.get("q") or "").strip()
    sql = (
        "SELECT u.*, "
        " (SELECT percentage FROM quiz_attempts WHERE user_id=u.id AND quiz_type='pre' "
        "  ORDER BY attempted_at DESC LIMIT 1) AS pre_pct, "
        " (SELECT percentage FROM quiz_attempts WHERE user_id=u.id AND quiz_type='post' "
        "  ORDER BY attempted_at DESC LIMIT 1) AS post_pct "
        "FROM users u"
    )
    params = []
    if search:
        sql += " WHERE u.full_name LIKE %s OR u.email LIKE %s OR u.city LIKE %s"
        params = [f"%{search}%"] * 3
    sql += " ORDER BY u.created_at DESC"
    return render_template(
        "admin/users.html", admin=current_admin(), users=query_all(sql, params), search=search
    )


@admin_bp.route("/users/<int:user_id>/toggle", methods=["POST"])
@admin_required
def user_toggle(user_id):
    execute("UPDATE users SET is_active = 1 - is_active WHERE id = %s", (user_id,))
    flash("User status updated.", "success")
    return redirect(url_for("admin.users"))


@admin_bp.route("/users/<int:user_id>/delete", methods=["POST"])
@admin_required
def user_delete(user_id):
    execute("DELETE FROM users WHERE id = %s", (user_id,))
    flash("User deleted along with their attempts.", "success")
    return redirect(url_for("admin.users"))


# ----------------------------------------------------- scam categories ------
CATEGORY_FIELDS = (
    "slug", "name", "icon", "summary", "what_is_it", "how_it_works",
    "warning_signs", "example_text", "stay_safe", "if_targeted", "risk_level",
)


@admin_bp.route("/scam-categories")
@admin_required
def scam_categories():
    rows = query_all("SELECT * FROM scam_categories ORDER BY display_order")
    return render_template("admin/scam_categories.html", admin=current_admin(), categories=rows)


@admin_bp.route("/scam-categories/save", methods=["POST"])
@admin_required
def scam_category_save():
    data = {f: clean(request.form.get(f), 6000) for f in CATEGORY_FIELDS}
    if not data["name"] or not data["slug"]:
        flash("Name and slug are required.", "error")
        return redirect(url_for("admin.scam_categories"))
    if data["risk_level"] not in ("low", "medium", "high"):
        data["risk_level"] = "high"
    category_id = request.form.get("id")
    if category_id and category_id.isdigit():
        execute(
            "UPDATE scam_categories SET slug=%s, name=%s, icon=%s, summary=%s, what_is_it=%s, "
            "how_it_works=%s, warning_signs=%s, example_text=%s, stay_safe=%s, if_targeted=%s, "
            "risk_level=%s WHERE id=%s",
            tuple(data[f] for f in CATEGORY_FIELDS) + (int(category_id),),
        )
        flash("Scam category updated.", "success")
    else:
        execute(
            "INSERT INTO scam_categories (slug, name, icon, summary, what_is_it, how_it_works, "
            "warning_signs, example_text, stay_safe, if_targeted, risk_level, display_order) "
            "VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)",
            tuple(data[f] for f in CATEGORY_FIELDS)
            + (query_one("SELECT COALESCE(MAX(display_order),0)+1 n FROM scam_categories")["n"],),
        )
        flash("Scam category added.", "success")
    return redirect(url_for("admin.scam_categories"))


@admin_bp.route("/scam-categories/<int:category_id>/delete", methods=["POST"])
@admin_required
def scam_category_delete(category_id):
    execute("DELETE FROM scam_categories WHERE id = %s", (category_id,))
    flash("Scam category deleted.", "success")
    return redirect(url_for("admin.scam_categories"))


# ------------------------------------------------------- scam examples ------
@admin_bp.route("/scam-examples")
@admin_required
def scam_examples():
    rows = query_all(
        "SELECT e.*, c.name AS category_name FROM scam_examples e "
        "LEFT JOIN scam_categories c ON c.id = e.category_id ORDER BY e.id DESC"
    )
    categories = query_all("SELECT id, name FROM scam_categories ORDER BY display_order")
    return render_template(
        "admin/scam_examples.html", admin=current_admin(), examples=rows, categories=categories
    )


@admin_bp.route("/scam-examples/save", methods=["POST"])
@admin_required
def scam_example_save():
    channel = request.form.get("channel")
    if channel not in ("sms", "email", "whatsapp", "call", "webpage", "payment"):
        flash("Please choose a valid channel.", "error")
        return redirect(url_for("admin.scam_examples"))
    values = (
        int(request.form["category_id"]) if (request.form.get("category_id") or "").isdigit() else None,
        channel,
        clean(request.form.get("sender"), 120),
        clean(request.form.get("subject"), 160) or None,
        clean(request.form.get("body"), 4000),
        1 if request.form.get("is_scam") == "1" else 0,
        clean(request.form.get("explanation"), 2000),
        clean(request.form.get("warning_signs"), 2000),
        request.form.get("difficulty") if request.form.get("difficulty") in ("easy", "medium", "hard") else "easy",
    )
    example_id = request.form.get("id")
    if example_id and example_id.isdigit():
        execute(
            "UPDATE scam_examples SET category_id=%s, channel=%s, sender=%s, subject=%s, body=%s, "
            "is_scam=%s, explanation=%s, warning_signs=%s, difficulty=%s WHERE id=%s",
            values + (int(example_id),),
        )
        flash("Scam example updated.", "success")
    else:
        execute(
            "INSERT INTO scam_examples (category_id, channel, sender, subject, body, is_scam, "
            "explanation, warning_signs, difficulty) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)",
            values,
        )
        flash("Scam example added.", "success")
    return redirect(url_for("admin.scam_examples"))


@admin_bp.route("/scam-examples/<int:example_id>/delete", methods=["POST"])
@admin_required
def scam_example_delete(example_id):
    execute("DELETE FROM scam_examples WHERE id = %s", (example_id,))
    flash("Scam example deleted.", "success")
    return redirect(url_for("admin.scam_examples"))


# -------------------------------------------------------------- quizzes -----
@admin_bp.route("/quizzes")
@admin_required
def quizzes():
    questions = query_all(
        "SELECT q.*, c.name AS category_name FROM quiz_questions q "
        "LEFT JOIN scam_categories c ON c.id = q.category_id ORDER BY q.quiz_type, q.id"
    )
    for question in questions:
        question["options"] = query_all(
            "SELECT * FROM quiz_options WHERE question_id = %s ORDER BY id", (question["id"],)
        )
    categories = query_all("SELECT id, name FROM scam_categories ORDER BY display_order")
    return render_template(
        "admin/quizzes.html", admin=current_admin(), questions=questions, categories=categories
    )


@admin_bp.route("/quizzes/save", methods=["POST"])
@admin_required
def quiz_save():
    quiz_type = request.form.get("quiz_type")
    if quiz_type not in ("pre", "post", "general"):
        flash("Choose a valid quiz type.", "error")
        return redirect(url_for("admin.quizzes"))
    options = [clean(request.form.get(f"option{i}"), 300) for i in range(1, 5)]
    correct = request.form.get("correct_option")
    if len([o for o in options if o]) < 2 or correct not in ("1", "2", "3", "4"):
        flash("Provide at least two options and mark the correct one.", "error")
        return redirect(url_for("admin.quizzes"))

    category_id = int(request.form["category_id"]) if (request.form.get("category_id") or "").isdigit() else None
    question_text = clean(request.form.get("question"), 400)
    explanation = clean(request.form.get("explanation"), 2000)
    question_id = request.form.get("id")

    if question_id and question_id.isdigit():
        execute(
            "UPDATE quiz_questions SET quiz_type=%s, category_id=%s, question=%s, explanation=%s WHERE id=%s",
            (quiz_type, category_id, question_text, explanation, int(question_id)),
        )
        execute("DELETE FROM quiz_options WHERE question_id = %s", (int(question_id),))
        qid = int(question_id)
        flash("Question updated.", "success")
    else:
        qid = execute(
            "INSERT INTO quiz_questions (quiz_type, category_id, question, explanation) VALUES (%s,%s,%s,%s)",
            (quiz_type, category_id, question_text, explanation),
        )
        flash("Question added.", "success")

    for index, text in enumerate(options, start=1):
        if text:
            execute(
                "INSERT INTO quiz_options (question_id, option_text, is_correct) VALUES (%s,%s,%s)",
                (qid, text, 1 if str(index) == correct else 0),
            )
    return redirect(url_for("admin.quizzes"))


@admin_bp.route("/quizzes/<int:question_id>/delete", methods=["POST"])
@admin_required
def quiz_delete(question_id):
    execute("DELETE FROM quiz_questions WHERE id = %s", (question_id,))
    flash("Question deleted.", "success")
    return redirect(url_for("admin.quizzes"))


# --------------------------------------------------------------- videos -----
@admin_bp.route("/videos")
@admin_required
def videos():
    rows = query_all(
        "SELECT v.*, c.name AS category_name FROM videos v "
        "LEFT JOIN scam_categories c ON c.id = v.category_id ORDER BY v.created_at DESC"
    )
    categories = query_all("SELECT id, name FROM scam_categories ORDER BY display_order")
    return render_template(
        "admin/videos.html", admin=current_admin(), videos=rows, categories=categories
    )


@admin_bp.route("/videos/save", methods=["POST"])
@admin_required
def video_save():
    data, errors = validate_video(request.form)
    if errors:
        flash(" ".join(errors.values()), "error")
        return redirect(url_for("admin.videos"))
    video_id = request.form.get("id")
    values = (
        data["title"], data["youtube_id"], data["video_url"], data["description"],
        data["category_id"], data["thumbnail_url"], data["status"],
    )
    if video_id and video_id.isdigit():
        execute(
            "UPDATE videos SET title=%s, youtube_id=%s, video_url=%s, description=%s, "
            "category_id=%s, thumbnail_url=%s, status=%s WHERE id=%s",
            values + (int(video_id),),
        )
        flash("Video updated.", "success")
    else:
        execute(
            "INSERT INTO videos (title, youtube_id, video_url, description, category_id, "
            "thumbnail_url, status) VALUES (%s,%s,%s,%s,%s,%s,%s)",
            values,
        )
        flash("Video added.", "success")
    return redirect(url_for("admin.videos"))


@admin_bp.route("/videos/<int:video_id>/toggle", methods=["POST"])
@admin_required
def video_toggle(video_id):
    execute(
        "UPDATE videos SET status = IF(status='published','draft','published') WHERE id=%s", (video_id,)
    )
    flash("Video visibility updated.", "success")
    return redirect(url_for("admin.videos"))


@admin_bp.route("/videos/<int:video_id>/delete", methods=["POST"])
@admin_required
def video_delete(video_id):
    execute("DELETE FROM videos WHERE id = %s", (video_id,))
    flash("Video deleted.", "success")
    return redirect(url_for("admin.videos"))


# ---------------------------------------------------- learning resources ----
@admin_bp.route("/resources")
@admin_required
def resources():
    rows = query_all("SELECT * FROM learning_resources ORDER BY created_at DESC")
    categories = query_all("SELECT id, name FROM scam_categories ORDER BY display_order")
    return render_template(
        "admin/resources.html", admin=current_admin(), resources=rows, categories=categories
    )


@admin_bp.route("/resources/save", methods=["POST"])
@admin_required
def resource_save():
    rtype = request.form.get("resource_type")
    if rtype not in ("article", "checklist", "infographic", "poster", "tip"):
        flash("Choose a valid resource type.", "error")
        return redirect(url_for("admin.resources"))
    values = (
        clean(request.form.get("title"), 160),
        rtype,
        int(request.form["category_id"]) if (request.form.get("category_id") or "").isdigit() else None,
        clean(request.form.get("summary"), 300),
        clean(request.form.get("content"), 20000),
        1 if request.form.get("is_published") == "1" else 0,
    )
    resource_id = request.form.get("id")
    if resource_id and resource_id.isdigit():
        execute(
            "UPDATE learning_resources SET title=%s, resource_type=%s, category_id=%s, summary=%s, "
            "content=%s, is_published=%s WHERE id=%s",
            values + (int(resource_id),),
        )
        flash("Resource updated.", "success")
    else:
        execute(
            "INSERT INTO learning_resources (title, resource_type, category_id, summary, content, "
            "is_published) VALUES (%s,%s,%s,%s,%s,%s)",
            values,
        )
        flash("Resource added.", "success")
    return redirect(url_for("admin.resources"))


@admin_bp.route("/resources/<int:resource_id>/delete", methods=["POST"])
@admin_required
def resource_delete(resource_id):
    execute("DELETE FROM learning_resources WHERE id = %s", (resource_id,))
    flash("Resource deleted.", "success")
    return redirect(url_for("admin.resources"))


# ------------------------------------------------------------- feedback -----
@admin_bp.route("/feedback")
@admin_required
def feedback():
    rows = query_all("SELECT * FROM feedback ORDER BY created_at DESC")
    average = query_one("SELECT ROUND(AVG(rating),1) a FROM feedback")["a"] or 0
    return render_template(
        "admin/feedback.html", admin=current_admin(), feedback=rows, average=average
    )


@admin_bp.route("/feedback/<int:feedback_id>/read", methods=["POST"])
@admin_required
def feedback_read(feedback_id):
    execute("UPDATE feedback SET is_read = 1 WHERE id = %s", (feedback_id,))
    return redirect(url_for("admin.feedback"))


@admin_bp.route("/feedback/<int:feedback_id>/delete", methods=["POST"])
@admin_required
def feedback_delete(feedback_id):
    execute("DELETE FROM feedback WHERE id = %s", (feedback_id,))
    flash("Feedback removed.", "success")
    return redirect(url_for("admin.feedback"))
