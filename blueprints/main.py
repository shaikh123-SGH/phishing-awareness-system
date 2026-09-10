"""Public pages: home, about, awareness, safety centre, videos, resources,
emergency guidance, contact and feedback."""
from flask import Blueprint, render_template, request, redirect, url_for, flash, session, jsonify, abort

from utils.database import query_all, query_one, execute
from utils.validation import validate_feedback

main_bp = Blueprint("main", __name__)


def _split_lines(text):
    return [line.strip() for line in (text or "").splitlines() if line.strip()]


@main_bp.app_template_filter("lines")
def lines_filter(text):
    return _split_lines(text)


@main_bp.route("/")
def index():
    categories = query_all(
        "SELECT id, slug, name, icon, summary, risk_level FROM scam_categories "
        "WHERE is_active = 1 ORDER BY display_order"
    )
    videos = query_all(
        "SELECT id, title, youtube_id, description, thumbnail_url FROM videos "
        "WHERE status = 'published' ORDER BY created_at DESC LIMIT 3"
    )
    stats = {
        "categories": len(categories),
        "examples": (query_one("SELECT COUNT(*) c FROM scam_examples WHERE is_active = 1") or {}).get("c", 0),
        "videos": (query_one("SELECT COUNT(*) c FROM videos WHERE status = 'published'") or {}).get("c", 0),
        "learners": (query_one("SELECT COUNT(*) c FROM users WHERE is_active = 1") or {}).get("c", 0),
    }
    return render_template("index.html", categories=categories, videos=videos, stats=stats)


@main_bp.route("/about")
def about():
    return render_template("about.html")


@main_bp.route("/awareness")
def awareness():
    search = (request.args.get("q") or "").strip()
    risk = request.args.get("risk") or ""
    sql = "SELECT * FROM scam_categories WHERE is_active = 1"
    params = []
    if search:
        sql += " AND (name LIKE %s OR summary LIKE %s)"
        params += [f"%{search}%", f"%{search}%"]
    if risk in ("low", "medium", "high"):
        sql += " AND risk_level = %s"
        params.append(risk)
    sql += " ORDER BY display_order"
    categories = query_all(sql, params)
    return render_template("awareness.html", categories=categories, search=search, risk=risk)


@main_bp.route("/awareness/<slug>")
def scam_detail(slug):
    category = query_one("SELECT * FROM scam_categories WHERE slug = %s AND is_active = 1", (slug,))
    if not category:
        abort(404)
    examples = query_all(
        "SELECT * FROM scam_examples WHERE category_id = %s AND is_active = 1 LIMIT 4",
        (category["id"],),
    )
    videos = query_all(
        "SELECT id, title, youtube_id, thumbnail_url FROM videos "
        "WHERE category_id = %s AND status = 'published'",
        (category["id"],),
    )
    others = query_all(
        "SELECT slug, name, icon, summary FROM scam_categories "
        "WHERE is_active = 1 AND id <> %s ORDER BY RAND() LIMIT 3",
        (category["id"],),
    )
    # Track learning progress for signed-in users.
    if session.get("role") == "user":
        execute(
            "INSERT IGNORE INTO user_progress (user_id, category_id) VALUES (%s, %s)",
            (session["user_id"], category["id"]),
        )
    return render_template(
        "phishing.html", category=category, examples=examples, videos=videos, others=others
    )


@main_bp.route("/scams")
def scams():
    """Grid of every fictional scam example, filterable by channel."""
    channel = request.args.get("channel") or ""
    search = (request.args.get("q") or "").strip()
    sql = (
        "SELECT e.*, c.name AS category_name, c.slug AS category_slug "
        "FROM scam_examples e LEFT JOIN scam_categories c ON c.id = e.category_id "
        "WHERE e.is_active = 1"
    )
    params = []
    if channel:
        sql += " AND e.channel = %s"
        params.append(channel)
    if search:
        sql += " AND (e.sender LIKE %s OR e.body LIKE %s OR e.subject LIKE %s)"
        params += [f"%{search}%"] * 3
    sql += " ORDER BY e.id"
    examples = query_all(sql, params)
    return render_template("scams.html", examples=examples, channel=channel, search=search)


@main_bp.route("/safety-center")
def safety_center():
    topics = query_all("SELECT * FROM safety_topics ORDER BY display_order")
    return render_template("safety_center.html", topics=topics)


@main_bp.route("/videos")
def videos():
    search = (request.args.get("q") or "").strip()
    category_id = request.args.get("category") or ""
    sql = (
        "SELECT v.*, c.name AS category_name FROM videos v "
        "LEFT JOIN scam_categories c ON c.id = v.category_id WHERE v.status = 'published'"
    )
    params = []
    if search:
        sql += " AND (v.title LIKE %s OR v.description LIKE %s)"
        params += [f"%{search}%", f"%{search}%"]
    if category_id.isdigit():
        sql += " AND v.category_id = %s"
        params.append(int(category_id))
    sql += " ORDER BY v.created_at DESC"
    video_list = query_all(sql, params)
    categories = query_all("SELECT id, name FROM scam_categories WHERE is_active = 1 ORDER BY display_order")
    return render_template(
        "videos.html", videos=video_list, categories=categories, search=search, category_id=category_id
    )


@main_bp.route("/videos/<int:video_id>/view", methods=["POST"])
def video_view(video_id):
    execute("UPDATE videos SET views = views + 1 WHERE id = %s", (video_id,))
    return jsonify({"ok": True})


@main_bp.route("/resources")
def resources():
    rtype = request.args.get("type") or ""
    search = (request.args.get("q") or "").strip()
    sql = "SELECT * FROM learning_resources WHERE is_published = 1"
    params = []
    if rtype:
        sql += " AND resource_type = %s"
        params.append(rtype)
    if search:
        sql += " AND (title LIKE %s OR summary LIKE %s)"
        params += [f"%{search}%", f"%{search}%"]
    sql += " ORDER BY created_at DESC"
    return render_template(
        "resources.html", resources=query_all(sql, params), rtype=rtype, search=search
    )


@main_bp.route("/resources/<int:resource_id>/download")
def resource_download(resource_id):
    """Serve a resource as a plain-text download so material can be printed."""
    from flask import Response

    row = query_one(
        "SELECT title, content FROM learning_resources WHERE id = %s AND is_published = 1",
        (resource_id,),
    )
    if not row:
        abort(404)
    filename = "".join(ch if ch.isalnum() or ch in " -_" else "" for ch in row["title"])[:60]
    body = f"{row['title']}\n{'=' * len(row['title'])}\n\n{row['content']}\n\n" \
           "Phishing Scam & Fraud Detection Awareness Program - educational material.\n"
    return Response(
        body,
        mimetype="text/plain; charset=utf-8",
        headers={"Content-Disposition": f'attachment; filename="{filename}.txt"'},
    )


@main_bp.route("/emergency")
def emergency():
    return render_template("emergency.html")


@main_bp.route("/contact", methods=["GET", "POST"])
def contact():
    errors, data = {}, {}
    if request.method == "POST":
        data, errors = validate_feedback(request.form)
        if not errors:
            execute(
                "INSERT INTO feedback (user_id, name, email, rating, message, suggestions) "
                "VALUES (%s, %s, %s, %s, %s, %s)",
                (
                    session.get("user_id") if session.get("role") == "user" else None,
                    data["name"],
                    data["email"],
                    data["rating"],
                    data["message"],
                    data["suggestions"],
                ),
            )
            flash("Thank you. Your feedback has been recorded.", "success")
            return redirect(url_for("main.contact"))
        flash("Please correct the highlighted fields.", "error")
    return render_template("contact.html", errors=errors, data=data)
