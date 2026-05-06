# app/core/db_mysql.py
from app.core.db import get_db  #retorna mysql.connector connection

def get_mysql_conn():
    conn = get_db()
    try:
        yield conn
    finally:
        try:
            conn.close()
        except Exception:
            pass