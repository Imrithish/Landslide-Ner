import asyncio
import os
from pathlib import Path

from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parent / ".env")

from providers.notifications import TextBeeSMSProvider


async def test_textbee():
    api_key = os.getenv("TEXTBEE_API_KEY", "")
    device_id = os.getenv("TEXTBEE_DEVICE_ID", "")
    phone_number = os.getenv("TEXTBEE_TEST_PHONE", "")
    message = "TextBee connectivity test from NER Landslide Early Warning."

    if not api_key or not device_id or not phone_number:
        raise RuntimeError("Set TextBee credentials and TEXTBEE_TEST_PHONE before running this live test")
    result = await TextBeeSMSProvider(api_key, device_id).send_sms(phone_number, message)
    print({"success": result.get("success"), "provider": result.get("provider"), "status": result.get("status"), "error_code": result.get("error_code"), "http_status": result.get("http_status")})


if __name__ == "__main__":
    asyncio.run(test_textbee())
