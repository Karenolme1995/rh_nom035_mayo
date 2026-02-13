from app.core.db import get_db
from app.core.security import hash_password

def is_bcrypt(p: str) -> bool:
    return isinstance(p, str) and p.startswith("$2")

def main():
    db = get_db()

    try:
        cursor = db.cursor(dictionary=True)
        cursor.execute("SELECT id, password FROM users")
        users = cursor.fetchall()
        cursor.close()

        updated = 0

        for user in users:
            pwd = user.get("password")

            # Solo migra si existe y NO parece bcrypt
            if pwd and not is_bcrypt(pwd):
                # bcrypt usa solo 72 bytes, truncamos
                new_hash = hash_password(pwd)

                cur2 = db.cursor()
                cur2.execute(
                    "UPDATE users SET password=%s WHERE id=%s",
                    (new_hash, user["id"]),
                )
                cur2.close()

                updated += 1

        db.commit()
        print(f"✅ Migración completada. Usuarios actualizados: {updated}")

    finally:
        try:
            db.close()
        except:
            pass

if __name__ == "__main__":
    main()
