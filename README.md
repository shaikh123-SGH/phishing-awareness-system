# Phishing, Scam & Fraud Detection Awareness Program

A Flask + MySQL web application for a Semester 5 Community Engagement Project.
It teaches people how phishing, OTP fraud, UPI scams, fake job offers, lottery
scams and similar frauds work, measures awareness with a pre-test and a
post-test, and gives an administrator full content management.

**Safety promise:** the platform never asks for real passwords (other than the
account password you choose for this site), OTPs, PINs, card numbers or bank
details. Every scam message shown is fictional and clearly for training.

## Features

- Public awareness site: home, about, scam library, per-scam briefings, safety
  centre, video centre, resources, emergency guidance, feedback.
- Secure accounts: registration, login/logout, hashed passwords, CSRF-protected
  forms, session management, profile with progress.
- Pre-test and post-test with scoring, answer review, awareness level and a
  pre-vs-post improvement comparison.
- "Spot the Scam" interactive exercise with instant explanations and warning signs.
- Admin panel: dashboard statistics, animated reports, and CRUD for users,
  scam categories, scam examples, quiz questions/options, videos, resources
  and feedback.
- Responsive design, animations, keyboard-accessible components, reduced-motion
  support.

## Project structure

```
Phishing-Awareness-System/
├── app.py                 # application factory and entry point
├── config.py              # environment-based configuration
├── requirements.txt
├── database.sql           # schema + fictional seed data
├── .env.example
├── blueprints/            # main, auth_routes, quiz, admin
├── utils/                 # database, auth, validation, helpers
├── templates/             # base, public pages, components/, admin/, errors/
└── static/                # css/, js/, images/, uploads/
```

## Setup

1. **Requirements:** Python 3.10+, MySQL 8.0+ (or MariaDB 10.5+).
2. **Create and activate a virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate      # Windows: venv\Scripts\activate
   ```
3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```
4. **Create the database**
   ```bash
   mysql -u root -p < database.sql
   ```
   This creates the `phishing_awareness` database, all tables and the fictional
   seed content.
5. **Configure environment**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` and set `SECRET_KEY`, `MYSQL_USER`, `MYSQL_PASSWORD`,
   `MYSQL_HOST`, `MYSQL_DB`.
6. **Run**
   ```bash
   python app.py
   ```
   Open http://127.0.0.1:5000

## Security notes

- Passwords are stored with Werkzeug PBKDF2 hashing; plain passwords are never saved.
- All SQL uses parameterised queries, so user input cannot alter a query.
- Every state-changing form carries a CSRF token that is validated server-side.
- Feedback and profile input is length-limited, trimmed and screened for
  anything that looks like a card number or OTP.
- Session cookies are HTTP-only and SameSite=Lax; enable `SESSION_COOKIE_SECURE`
  and set `FLASK_ENV=production` when deploying behind HTTPS.

## Deployment

For production use a WSGI server instead of the development server:

```bash
pip install gunicorn
gunicorn -w 4 "app:create_app()"
```

Serve behind Nginx or Apache with HTTPS, set a strong `SECRET_KEY`, and use a
dedicated MySQL user limited to this database.

## Disclaimer

This is an educational awareness project. It cannot investigate incidents,
contact banks or recover money, and it does not replace official cybercrime
authorities. Always report real incidents through official channels.
