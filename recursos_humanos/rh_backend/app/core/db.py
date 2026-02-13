import mysql.connector
from mysql.connector import Error
from app.core.config import settings

def get_db():
    try:
        connection = mysql.connector.connect(
            host="mysql.aom-proyectos.com",
            user="karen723434236",
            password="karen828343!12!",
            database="aomproyectosbase",
            charset="utf8mb4",
            use_unicode=True,
        )
        return connection
    except Error as e:
        print("Error MySQL:", e)
        raise



