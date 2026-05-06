# app/core/db.py
import mysql.connector
from mysql.connector import Error
from app.core.config import settings

def get_db():
    try:
        connection = mysql.connector.connect(
            host=settings.mysql_host,
            port=settings.mysql_port,
            user=settings.mysql_user,
            password=settings.mysql_password,
            database=settings.mysql_db,
            charset="utf8mb4",
            use_unicode=True,
        )
        return connection
    except Error as e:
        print("Error MySQL:", e)
        raise