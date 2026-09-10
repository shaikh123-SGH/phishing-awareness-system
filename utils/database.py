"""MySQL connection helpers. Every query uses parameter binding (no string
concatenation) which protects the application from SQL injection."""
import pymysql
from pymysql.cursors import DictCursor
from flask import current_app, g


def get_connection():
    """Return a per-request MySQL connection stored on Flask's `g` object."""
    if "db_conn" not in g:
        cfg = current_app.config
        g.db_conn = pymysql.connect(
            host=cfg["MYSQL_HOST"],
            port=cfg["MYSQL_PORT"],
            user=cfg["MYSQL_USER"],
            password=cfg["MYSQL_PASSWORD"],
            database=cfg["MYSQL_DB"],
            charset="utf8mb4",
            cursorclass=DictCursor,
            autocommit=False,
        )
    return g.db_conn


def close_connection(_exc=None):
    conn = g.pop("db_conn", None)
    if conn is not None:
        conn.close()


def query_all(sql, params=None):
    with get_connection().cursor() as cur:
        cur.execute(sql, params or ())
        return cur.fetchall()


def query_one(sql, params=None):
    with get_connection().cursor() as cur:
        cur.execute(sql, params or ())
        return cur.fetchone()


def execute(sql, params=None):
    """Run an INSERT/UPDATE/DELETE and return the last inserted id."""
    conn = get_connection()
    with conn.cursor() as cur:
        cur.execute(sql, params or ())
        last_id = cur.lastrowid
    conn.commit()
    return last_id


def execute_many(sql, seq_params):
    conn = get_connection()
    with conn.cursor() as cur:
        cur.executemany(sql, seq_params)
    conn.commit()


def init_app(app):
    app.teardown_appcontext(close_connection)
