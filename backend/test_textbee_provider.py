import unittest
from unittest.mock import AsyncMock, patch

import httpx

from providers.notifications import (
    TextBeeSMSProvider,
    UnconfiguredSMSProvider,
    normalize_indian_phone_number,
)


class FakeResponse:
    def __init__(self, status_code, body):
        self.status_code = status_code
        self._body = body
        self.headers = {"content-type": "application/json"}
        self.text = str(body)

    def json(self):
        return self._body


class FakeAsyncClient:
    def __init__(self, response=None, error=None):
        self.response = response
        self.error = error
        self.post = AsyncMock(side_effect=error or (lambda *args, **kwargs: self.response))

    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc, traceback):
        return False


class TextBeeProviderTests(unittest.IsolatedAsyncioTestCase):
    async def test_valid_number_posts_current_contract_and_accepts_queue(self):
        client = FakeAsyncClient(FakeResponse(200, {"data": {"success": True, "smsBatchId": "batch-id"}}))
        with patch("providers.notifications.httpx.AsyncClient", return_value=client):
            result = await TextBeeSMSProvider("key", "device").send_sms("98765 43210", "Alert")

        self.assertTrue(result["success"])
        self.assertEqual(result["status"], "ACCEPTED")
        args = client.post.await_args
        self.assertEqual(args.args[0], "https://api.textbee.dev/api/v1/gateway/send-sms")
        self.assertEqual(args.kwargs["headers"]["x-api-key"], "key")
        self.assertEqual(args.kwargs["json"], {"recipients": ["+919876543210"], "message": "Alert", "deviceId": "device"})

    async def test_invalid_number_does_not_call_provider(self):
        client = FakeAsyncClient()
        with patch("providers.notifications.httpx.AsyncClient", return_value=client):
            result = await TextBeeSMSProvider("key", "device").send_sms("12345", "Alert")

        self.assertEqual(result["error_code"], "INVALID_PHONE_NUMBER")
        client.post.assert_not_awaited()

    async def test_missing_configuration_is_explicit_failure(self):
        result = await UnconfiguredSMSProvider().send_sms("9876543210", "Alert")
        self.assertEqual(result["error_code"], "MISSING_CONFIGURATION")
        self.assertFalse(result["success"])

    async def test_provider_failure_is_sanitized(self):
        client = FakeAsyncClient(FakeResponse(401, {"message": "invalid key", "apiKey": "redact-me"}))
        with patch("providers.notifications.httpx.AsyncClient", return_value=client):
            result = await TextBeeSMSProvider("key", "device").send_sms("9876543210", "Alert")

        self.assertEqual(result["error_code"], "PROVIDER_ERROR")
        self.assertEqual(result["http_status"], 401)
        self.assertNotIn("redact-me", result["error"])

    async def test_timeout_is_reported(self):
        client = FakeAsyncClient(error=httpx.ReadTimeout("timed out"))
        with patch("providers.notifications.httpx.AsyncClient", return_value=client):
            result = await TextBeeSMSProvider("key", "device").send_sms("9876543210", "Alert")
        self.assertEqual(result["error_code"], "TIMEOUT")


class IndianPhoneNumberTests(unittest.TestCase):
    def test_normalizes_supported_forms(self):
        self.assertEqual(normalize_indian_phone_number("+91 98765-43210"), "+919876543210")
        self.assertEqual(normalize_indian_phone_number("919876543210"), "+919876543210")

    def test_rejects_non_mobile_number(self):
        with self.assertRaises(ValueError):
            normalize_indian_phone_number("0123456789")


if __name__ == "__main__":
    unittest.main()