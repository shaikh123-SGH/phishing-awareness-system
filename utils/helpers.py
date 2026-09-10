"""Small shared helpers used across blueprints and templates."""
from datetime import datetime


def percentage(score, total):
    if not total:
        return 0
    return round((score / total) * 100)


def awareness_level(percent: int) -> str:
    if percent >= 85:
        return "Excellent"
    if percent >= 70:
        return "Good"
    if percent >= 50:
        return "Moderate"
    if percent >= 30:
        return "Needs Improvement"
    return "High Risk"


def level_colour(percent: int) -> str:
    if percent >= 85:
        return "safe"
    if percent >= 50:
        return "warn"
    return "danger"


def format_date(value):
    if isinstance(value, datetime):
        return value.strftime("%d %b %Y, %I:%M %p")
    return value or ""


def paginate(items, page, per_page=9):
    page = max(1, page)
    start = (page - 1) * per_page
    total_pages = max(1, -(-len(items) // per_page))
    return items[start : start + per_page], page, total_pages


def register_template_helpers(app):
    app.jinja_env.filters["fmt_date"] = format_date
    app.jinja_env.globals["awareness_level"] = awareness_level
    app.jinja_env.globals["level_colour"] = level_colour
    app.jinja_env.globals["current_year"] = lambda: datetime.now().year
