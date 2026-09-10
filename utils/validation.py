"""Server-side input validation. Never trust anything sent by the browser."""
import re
from urllib.parse import urlparse, parse_qs

EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[a-zA-Z]{2,}$")
SENSITIVE_RE = re.compile(
    r"\b(\d{12,19}|otp\s*[:=]\s*\d{4,8}|pin\s*[:=]\s*\d{4,6})\b", re.IGNORECASE
)


def clean(value, max_length=255):
    return (value or "").strip()[:max_length]


def validate_registration(form):
    errors = {}
    full_name = clean(form.get("full_name"), 100)
    email = clean(form.get("email"), 120).lower()
    password = form.get("password") or ""
    confirm = form.get("confirm_password") or ""

    if len(full_name) < 3:
        errors["full_name"] = "Please enter your full name (at least 3 characters)."
    if not EMAIL_RE.match(email):
        errors["email"] = "Please enter a valid email address."
    if len(password) < 8:
        errors["password"] = "Password must be at least 8 characters long."
    elif not re.search(r"[A-Za-z]", password) or not re.search(r"\d", password):
        errors["password"] = "Password must contain both letters and numbers."
    if password != confirm:
        errors["confirm_password"] = "Passwords do not match."

    data = {
        "full_name": full_name,
        "email": email,
        "password": password,
        "age_group": clean(form.get("age_group"), 20),
        "occupation": clean(form.get("occupation"), 60),
        "city": clean(form.get("city"), 60),
    }
    return data, errors


def validate_feedback(form):
    errors = {}
    name = clean(form.get("name"), 100)
    email = clean(form.get("email"), 120).lower()
    rating = form.get("rating", "")
    message = clean(form.get("message"), 1500)

    if len(name) < 2:
        errors["name"] = "Please enter your name."
    if email and not EMAIL_RE.match(email):
        errors["email"] = "Please enter a valid email address or leave it blank."
    if rating not in {"1", "2", "3", "4", "5"}:
        errors["rating"] = "Please choose a rating from 1 to 5."
    if len(message) < 10:
        errors["message"] = "Please write at least 10 characters of feedback."
    if contains_sensitive_data(message):
        errors["message"] = "Please do not include card numbers, OTPs or PINs."

    data = {
        "name": name,
        "email": email or None,
        "rating": int(rating) if rating.isdigit() else 0,
        "message": message,
        "suggestions": clean(form.get("suggestions"), 1000),
    }
    return data, errors


def contains_sensitive_data(text: str) -> bool:
    """Blocks users from accidentally submitting card/OTP/PIN-looking data."""
    return bool(SENSITIVE_RE.search(text or ""))


def extract_youtube_id(url: str):
    """Accept only well-formed YouTube URLs and return the 11-char video id."""
    if not url:
        return None
    url = url.strip()
    if not url.startswith(("http://", "https://")):
        url = "https://" + url
    parsed = urlparse(url)
    host = parsed.netloc.lower().replace("www.", "")
    video_id = None
    if host in ("youtube.com", "m.youtube.com", "music.youtube.com"):
        if parsed.path == "/watch":
            video_id = (parse_qs(parsed.query).get("v") or [None])[0]
        elif parsed.path.startswith(("/embed/", "/shorts/", "/v/")):
            video_id = parsed.path.split("/")[2]
    elif host == "youtu.be":
        video_id = parsed.path.lstrip("/")
    if video_id and re.fullmatch(r"[A-Za-z0-9_-]{11}", video_id):
        return video_id
    return None


def validate_video(form):
    errors = {}
    title = clean(form.get("title"), 150)
    url = clean(form.get("video_url"), 300)
    video_id = extract_youtube_id(url)

    if len(title) < 3:
        errors["title"] = "Please enter a video title."
    if not video_id:
        errors["video_url"] = "Enter a valid YouTube link (watch, youtu.be, shorts or embed)."

    data = {
        "title": title,
        "youtube_id": video_id,
        "video_url": url,
        "description": clean(form.get("description"), 1000),
        "category_id": int(form["category_id"]) if (form.get("category_id") or "").isdigit() else None,
        "thumbnail_url": clean(form.get("thumbnail_url"), 300)
        or (f"https://img.youtube.com/vi/{video_id}/hqdefault.jpg" if video_id else ""),
        "status": "published" if form.get("status") == "published" else "draft",
    }
    return data, errors
