# app/services/notification_service.py
import smtplib
from email.mime.text import MIMEText
from app.core.config import settings


class NotificationService:

    def _cursor(self, conn):
        return conn.cursor(dictionary=True)

    def _log(
        self,
        conn,
        cycle_id: int,
        user_id: int,
        notif_type: str,
        channel: str,
        provider_id=None,
        status="sent",
        destination=None,
        error_message=None,
    ):
        cur = self._cursor(conn)
        try:
            cur.execute(
                """
                INSERT INTO nom035_notification_log
                (cycle_id, user_id, type, channel, provider_id, status, destination, error_message)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    cycle_id,
                    user_id,
                    notif_type,
                    channel,
                    provider_id,
                    status,
                    destination,
                    error_message,
                ),
            )
            conn.commit()
        finally:
            cur.close()

    def _already_sent(self, conn, cycle_id: int, user_id: int, notif_type: str, channel: str) -> bool:
        cur = self._cursor(conn)
        try:
            cur.execute(
                """
                SELECT id
                FROM nom035_notification_log
                WHERE cycle_id = %s
                  AND user_id = %s
                  AND type = %s
                  AND channel = %s
                  AND status = 'sent'
                LIMIT 1
                """,
                (cycle_id, user_id, notif_type, channel),
            )
            return cur.fetchone() is not None
        finally:
            cur.close()

    def send_email(self, conn, cycle_id: int, user_id: int, to_email: str, subject: str, body_html: str):
        if not to_email:
            self._log(conn, cycle_id, user_id, "start", "email", status="skipped", error_message="Usuario sin correo")
            return

        if not settings.smtp_host or not settings.smtp_user or not settings.smtp_password or not settings.smtp_from:
            self._log(conn, cycle_id, user_id, "start", "email", status="skipped", destination=to_email, error_message="SMTP no configurado")
            return

        try:
            msg = MIMEText(body_html, "html", "utf-8")
            msg["Subject"] = subject
            msg["From"] = settings.smtp_from
            msg["To"] = to_email

            with smtplib.SMTP(settings.smtp_host, settings.smtp_port) as server:
                server.starttls()
                server.login(settings.smtp_user, settings.smtp_password)
                server.send_message(msg)

            self._log(conn, cycle_id, user_id, "start", "email", status="sent", destination=to_email)

        except Exception as e:
            self._log(conn, cycle_id, user_id, "start", "email", status="error", destination=to_email, error_message=str(e))

    def send_sms(self, conn, cycle_id: int, user_id: int, phone: str, body: str):
        if not phone:
            self._log(conn, cycle_id, user_id, "start", "sms", status="skipped", error_message="Usuario sin teléfono")
            return

        if not settings.twilio_account_sid or not settings.twilio_auth_token or not settings.twilio_phone_number:
            self._log(conn, cycle_id, user_id, "start", "sms", status="skipped", destination=phone, error_message="Twilio no configurado")
            return

        try:
            from twilio.rest import Client

            client = Client(settings.twilio_account_sid, settings.twilio_auth_token)
            response = client.messages.create(
            body=body,
            from_=f"whatsapp:{settings.twilio_phone_number.replace('whatsapp:', '')}",
            to=f"whatsapp:{phone}",
            )

            self._log(
                conn,
                cycle_id,
                user_id,
                "start",
                "sms",
                provider_id=response.sid,
                status="sent",
                destination=phone,
            )

        except Exception as e:
            self._log(conn, cycle_id, user_id, "start", "sms", status="error", destination=phone, error_message=str(e))

    def notify_cycle_start(
        self,
        conn,
        cycle_id: int,
        user_id: int,
        name: str,
        email: str,
        phone: str,
        cycle_title: str,
        due_at=None,
        force_resend: bool = False,
    ):
        name = (name or "").strip() or "Colaborador"
        email = (email or "").strip()
        phone = (phone or "").strip()

        limit_text = ""
        if due_at:
            try:
                limit_text = due_at.strftime("%d/%m/%Y %H:%M")
            except Exception:
                limit_text = str(due_at)

        subject = f"NOM-035 STPS - {cycle_title}"

        body_html = f"""
        <html>
        <body>
            <p>Hola <strong>{name}</strong>,</p>
            <p>Se activó el cuestionario de la <strong>{cycle_title}</strong>.</p>
            <p>Tienes hasta <strong>{limit_text}</strong> para contestarlo.</p>
            <p><strong>Es obligatorio contestar.</strong></p>
        </body>
        </html>
        """

        sms_text = (
            f"Hola {name},\n"
            f"Se activó el cuestionario de la {cycle_title}.\n"
            f"Tienes hasta {limit_text} para contestarlo.\n"
            f"Es obligatorio contestar."
        )

        if force_resend or not self._already_sent(conn, cycle_id, user_id, "start", "email"):
            self.send_email(conn, cycle_id, user_id, email, subject, body_html)

        if force_resend or not self._already_sent(conn, cycle_id, user_id, "start", "sms"):
            self.send_sms(conn, cycle_id, user_id, phone, sms_text)


notification_service = NotificationService()