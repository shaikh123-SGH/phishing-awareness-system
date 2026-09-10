"""Pre-test, post-test and the Spot the Scam interactive exercise."""
from flask import Blueprint, render_template, request, redirect, url_for, flash, session, jsonify

from utils.database import query_all, query_one, execute
from utils.auth import login_required
from utils.helpers import percentage, awareness_level

quiz_bp = Blueprint("quiz", __name__)


def _load_questions(quiz_type):
    questions = query_all(
        "SELECT id, question, explanation FROM quiz_questions "
        "WHERE quiz_type = %s AND is_active = 1 ORDER BY id",
        (quiz_type,),
    )
    for question in questions:
        question["options"] = query_all(
            "SELECT id, option_text, is_correct FROM quiz_options WHERE question_id = %s ORDER BY id",
            (question["id"],),
        )
    return questions


def _grade(quiz_type, form):
    questions = _load_questions(quiz_type)
    score = 0
    review = []
    answers = []
    for question in questions:
        chosen_id = form.get(f"q{question['id']}")
        chosen = next((o for o in question["options"] if str(o["id"]) == str(chosen_id)), None)
        correct = next((o for o in question["options"] if o["is_correct"]), None)
        is_correct = bool(chosen and chosen["is_correct"])
        score += 1 if is_correct else 0
        review.append(
            {
                "question": question["question"],
                "explanation": question["explanation"],
                "chosen": chosen["option_text"] if chosen else "Not answered",
                "correct": correct["option_text"] if correct else "",
                "is_correct": is_correct,
            }
        )
        answers.append((question["id"], chosen["option_text"] if chosen else "Not answered", int(is_correct)))
    return questions, score, review, answers


def _store_attempt(quiz_type, score, total, answers, example_answers=None):
    if session.get("role") != "user":
        return None
    percent = percentage(score, total)
    attempt_id = execute(
        "INSERT INTO quiz_attempts (user_id, quiz_type, score, total, percentage, awareness_level) "
        "VALUES (%s, %s, %s, %s, %s, %s)",
        (session["user_id"], quiz_type, score, total, percent, awareness_level(percent)),
    )
    for question_id, given, is_correct in answers or []:
        execute(
            "INSERT INTO quiz_answers (attempt_id, question_id, given_answer, is_correct) "
            "VALUES (%s, %s, %s, %s)",
            (attempt_id, question_id, given, is_correct),
        )
    for example_id, given, is_correct in example_answers or []:
        execute(
            "INSERT INTO quiz_answers (attempt_id, example_id, given_answer, is_correct) "
            "VALUES (%s, %s, %s, %s)",
            (attempt_id, example_id, given, is_correct),
        )
    return attempt_id


@quiz_bp.route("/pre-test", methods=["GET", "POST"])
def pre_test():
    if request.method == "POST":
        questions, score, review, answers = _grade("pre", request.form)
        total = len(questions)
        _store_attempt("pre", score, total, answers)
        percent = percentage(score, total)
        flash("Pre-test completed. Explore the awareness section next.", "success")
        return render_template(
            "quiz_result.html",
            title="Pre-Test Result",
            quiz_type="pre",
            score=score,
            total=total,
            percent=percent,
            level=awareness_level(percent),
            review=review,
            comparison=None,
        )
    return render_template("pre_test.html", questions=_load_questions("pre"))


@quiz_bp.route("/post-test", methods=["GET", "POST"])
def post_test():
    if request.method == "POST":
        questions, score, review, answers = _grade("post", request.form)
        total = len(questions)
        _store_attempt("post", score, total, answers)
        percent = percentage(score, total)

        comparison = None
        if session.get("role") == "user":
            pre = query_one(
                "SELECT percentage FROM quiz_attempts WHERE user_id = %s AND quiz_type = 'pre' "
                "ORDER BY attempted_at DESC LIMIT 1",
                (session["user_id"],),
            )
            if pre:
                comparison = {
                    "pre": pre["percentage"],
                    "post": percent,
                    "improvement": percent - pre["percentage"],
                }
        flash("Post-test completed.", "success")
        return render_template(
            "quiz_result.html",
            title="Post-Test Result",
            quiz_type="post",
            score=score,
            total=total,
            percent=percent,
            level=awareness_level(percent),
            review=review,
            comparison=comparison,
        )
    return render_template("post_test.html", questions=_load_questions("post"))


@quiz_bp.route("/spot-the-scam")
def spot_scam():
    examples = query_all(
        "SELECT id, channel, sender, subject, body, is_scam, explanation, warning_signs, difficulty "
        "FROM scam_examples WHERE is_active = 1 ORDER BY RAND()"
    )
    return render_template("spot_scam.html", examples=examples)


@quiz_bp.route("/spot-the-scam/submit", methods=["POST"])
def spot_scam_submit():
    """Called by spot-scam.js once the exercise is finished."""
    payload = request.get_json(silent=True) or {}
    responses = payload.get("answers") or []
    if not isinstance(responses, list) or not responses:
        return jsonify({"ok": False, "error": "No answers submitted."}), 400

    example_answers, score = [], 0
    for item in responses[:100]:
        example = query_one(
            "SELECT id, is_scam FROM scam_examples WHERE id = %s", (item.get("id"),)
        )
        if not example:
            continue
        given = "scam" if item.get("answer") == "scam" else "safe"
        is_correct = int((given == "scam") == bool(example["is_scam"]))
        score += is_correct
        example_answers.append((example["id"], given, is_correct))

    total = len(example_answers)
    _store_attempt("spot", score, total, [], example_answers)
    percent = percentage(score, total)
    return jsonify(
        {
            "ok": True,
            "score": score,
            "total": total,
            "percent": percent,
            "level": awareness_level(percent),
            "saved": session.get("role") == "user",
        }
    )


@quiz_bp.route("/learning")
def learning():
    """Guided learning path shown between the pre-test and the post-test."""
    categories = query_all(
        "SELECT slug, name, icon, summary FROM scam_categories WHERE is_active = 1 ORDER BY display_order"
    )
    topics = query_all("SELECT slug, title, icon, summary FROM safety_topics ORDER BY display_order")
    resources = query_all(
        "SELECT id, title, resource_type, summary FROM learning_resources WHERE is_published = 1 LIMIT 6"
    )
    videos = query_all(
        "SELECT id, title, youtube_id, thumbnail_url FROM videos WHERE status = 'published' LIMIT 4"
    )
    done = []
    if session.get("role") == "user":
        done = [
            r["category_id"]
            for r in query_all("SELECT category_id FROM user_progress WHERE user_id = %s", (session["user_id"],))
        ]
    return render_template(
        "learning.html", categories=categories, topics=topics, resources=resources,
        videos=videos, done=done,
    )
