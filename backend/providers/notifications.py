"""
Pluggable Notification Gateway Architecture.
Supports TextBee Gateway (https://textbee.dev), SMTP Email, and Console Simulator.
"""

import os
import hashlib
import logging
import re
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import httpx
from abc import ABC, abstractmethod
from typing import Dict, Any, Optional

logger = logging.getLogger(__name__)

TEXTBEE_API_BASE_URL = "https://api.textbee.dev"
INDIAN_PHONE_PATTERN = re.compile(r"^[6-9]\d{9}$")


def normalize_indian_phone_number(phone_number: str) -> str:
    """Return an Indian number in E.164 form or raise ValueError."""
    if not isinstance(phone_number, str):
        raise ValueError("Phone number must be a string")

    compact = re.sub(r"[\s().-]", "", phone_number.strip())
    if compact.startswith("+91"):
        national_number = compact[3:]
    elif compact.startswith("91") and len(compact) == 12:
        national_number = compact[2:]
    elif len(compact) == 10:
        national_number = compact
    else:
        raise ValueError("Indian phone number must be a 10-digit mobile number")

    if not INDIAN_PHONE_PATTERN.fullmatch(national_number):
        raise ValueError("Indian phone number must start with 6, 7, 8, or 9")
    return f"+91{national_number}"


def _sanitize_provider_detail(detail: Any) -> str:
    if isinstance(detail, dict):
        safe_detail = {
            key: value for key, value in detail.items()
            if key.lower() not in {"token", "api_key", "apikey", "authorization", "x-api-key"}
        }
        return str(safe_detail)[:500]
    return str(detail)[:500]


# -------------------------------------------------------------
# 1. SMS PROVIDERS (TextBee Gateway)
# -------------------------------------------------------------
class SMSProvider(ABC):
    @abstractmethod
    async def send_sms(self, phone_number: str, message: str) -> Dict[str, Any]:
        pass


class TextBeeSMSProvider(SMSProvider):
    """
    TextBee SMS Gateway (https://textbee.dev).
    Sends real carrier SMS directly via connected Android device / TextBee API.
    """
    def __init__(self, api_key: str, device_id: str):
        self.api_key = api_key
        self.device_id = device_id

    async def send_sms(self, phone_number: str, message: str) -> Dict[str, Any]:
        try:
            clean_number = normalize_indian_phone_number(phone_number)
        except ValueError as exc:
            logger.warning("TextBee request rejected: invalid phone number")
            return {"success": False, "provider": "textbee", "error_code": "INVALID_PHONE_NUMBER", "error": str(exc)}

        url = f"{TEXTBEE_API_BASE_URL}/api/v1/gateway/send-sms"
        headers = {
            "x-api-key": self.api_key,
            "Content-Type": "application/json"
        }
        payload = {
            "recipients": [clean_number],
            "message": message,
            "deviceId": self.device_id,
        }

        try:
            logger.info("TextBee request started")
            async with httpx.AsyncClient(timeout=15.0) as client:
                response = await client.post(url, headers=headers, json=payload)
                logger.info("TextBee response status: %s", response.status_code)
                try:
                    res_json = response.json()
                except ValueError:
                    res_json = {"text": response.text[:500]}

                data_obj = res_json.get("data", {}) if isinstance(res_json, dict) else {}
                if response.status_code == 200 and isinstance(data_obj, dict) and data_obj.get("success") is True:
                    batch_id = data_obj.get("smsBatchId") or "queued"
                    logger.info("TextBee SMS accepted for %s", clean_number)
                    return {
                        "success": True,
                        "provider": "textbee",
                        "batch_id": batch_id,
                        "status": "ACCEPTED",
                    }
                detail = _sanitize_provider_detail(res_json)
                logger.warning("TextBee provider error status=%s detail=%s", response.status_code, detail)
                return {
                    "success": False,
                    "provider": "textbee",
                    "error_code": "PROVIDER_ERROR",
                    "http_status": response.status_code,
                    "error": detail,
                }
        except httpx.TimeoutException:
            logger.error("TextBee request timed out")
            return {"success": False, "provider": "textbee", "error_code": "TIMEOUT", "error": "TextBee request timed out"}
        except httpx.RequestError as exc:
            logger.error("TextBee network error: %s", type(exc).__name__)
            return {"success": False, "provider": "textbee", "error_code": "NETWORK_ERROR", "error": "TextBee network request failed"}


class ConsoleSMSProvider(SMSProvider):
    async def send_sms(self, phone_number: str, message: str) -> Dict[str, Any]:
        logger.info("[SIMULATED SMS] To: %s | Message: %s", phone_number, message)
        return {"success": True, "provider": "console_sms", "status": "DELIVERED"}


class UnconfiguredSMSProvider(SMSProvider):
    async def send_sms(self, phone_number: str, message: str) -> Dict[str, Any]:
        logger.error("TextBee SMS is not configured")
        return {
            "success": False,
            "provider": "textbee",
            "error_code": "MISSING_CONFIGURATION",
            "error": "TextBee credentials are not configured",
        }


# -------------------------------------------------------------
# 2. EMAIL PROVIDERS
# -------------------------------------------------------------
class EmailProvider(ABC):
    @abstractmethod
    async def send_email(self, recipient_email: str, subject: str, html_body: str) -> Dict[str, Any]:
        pass


class SMTPEmailProvider(EmailProvider):
    def __init__(self, host: str, port: int, user: str, password: str, from_email: str):
        self.host = host
        self.port = port
        self.user = user
        self.password = password
        self.from_email = from_email

    async def send_email(self, recipient_email: str, subject: str, html_body: str) -> Dict[str, Any]:
        try:
            msg = MIMEMultipart("alternative")
            msg["Subject"] = subject
            msg["From"] = f"NER Disaster Early Warning <{self.from_email}>"
            msg["To"] = recipient_email
            msg.attach(MIMEText(html_body, "html"))

            with smtplib.SMTP(self.host, self.port) as server:
                server.starttls()
                server.login(self.user, self.password)
                server.sendmail(self.from_email, recipient_email, msg.as_string())

            logger.info("[EMAIL SENT] To: %s | Subject: %s", recipient_email, subject)
            return {"success": True, "provider": "smtp_email", "status": "DELIVERED"}
        except Exception as e:
            logger.error("[EMAIL EXCEPTION] To %s: %s", recipient_email, e)
            return {"success": False, "provider": "smtp_email", "error": str(e)}


class ConsoleEmailProvider(EmailProvider):
    async def send_email(self, recipient_email: str, subject: str, html_body: str) -> Dict[str, Any]:
        logger.info("[SIMULATED EMAIL] To: %s | Subject: %s", recipient_email, subject)
        return {"success": True, "provider": "console_email", "status": "DELIVERED"}


# -------------------------------------------------------------
# FACTORY GETTERS
# -------------------------------------------------------------
def get_notification_gateways():
    from pathlib import Path
    from dotenv import load_dotenv
    _backend_dir = Path(__file__).resolve().parent.parent
    load_dotenv(_backend_dir / ".env", override=True)

    textbee_key = os.getenv("TEXTBEE_API_KEY")
    textbee_device = os.getenv("TEXTBEE_DEVICE_ID")

    if textbee_key and textbee_device and textbee_key.strip() and textbee_device.strip():
        logger.info("Using TextBee SMS Gateway")
        sms_gate = TextBeeSMSProvider(api_key=textbee_key.strip(), device_id=textbee_device.strip())
    else:
        logger.error("TextBee SMS credentials are missing; SMS sending is disabled")
        sms_gate = UnconfiguredSMSProvider()

    smtp_host = os.getenv("SMTP_HOST")
    smtp_user = os.getenv("SMTP_USER")
    smtp_pass = os.getenv("SMTP_PASSWORD")
    smtp_port = int(os.getenv("SMTP_PORT", 587))
    smtp_from = os.getenv("SMTP_FROM", smtp_user or "alerts@ner-disaster.gov.in")
    email_gate = SMTPEmailProvider(smtp_host, smtp_port, smtp_user, smtp_pass, smtp_from) if (smtp_host and smtp_user and smtp_pass) else ConsoleEmailProvider()

    return sms_gate, email_gate


sms_provider, email_provider = get_notification_gateways()
