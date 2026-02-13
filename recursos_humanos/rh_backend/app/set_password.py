from app.core.db import get_db
from app.core.security import hash_password

def main():
    emp = "485"
    new_plain = "485"
    new_hash = hash_password(new_plain)

    db = get_db()
    try:
        cur = db.cursor()
        cur.execute(
            "UPDATE users SET password=%s, active=1 WHERE employee_number=%s",
            (new_hash, emp),
        )
        db.commit()
        print("✅ Password actualizado para employee_number =", emp)
    finally:
        try:
            db.close()
        except:
            pass

if __name__ == "__main__":
    main()
