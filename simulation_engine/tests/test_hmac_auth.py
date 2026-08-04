import time
import hmac
import hashlib
import pytest
from fastapi import FastAPI, Depends, Request
from fastapi.testclient import TestClient
from app.api.middleware.hmac_auth import verify_hmac_signature
from app.core.config import settings

app = FastAPI()


@app.post("/test-auth", dependencies=[Depends(verify_hmac_signature)])
async def dummy_endpoint(request: Request):
    body = await request.json()
    return {"status": "ok", "received": body}



client = TestClient(app)


def test_hmac_auth_valid_signature():
    settings.ENV = "production"
    settings.HMAC_SECRET_KEY = "test_secret_key"

    timestamp = str(int(time.time()))
    payload = b'{"hello":"world"}'
    message = f"{timestamp}.".encode("utf-8") + payload

    signature = hmac.new(
        settings.HMAC_SECRET_KEY.encode("utf-8"),
        message,
        hashlib.sha256,
    ).hexdigest()

    header_val = f"t={timestamp},v1={signature}"

    response = client.post(
        "/test-auth",
        content=payload,
        headers={"X-VNL-Signature": header_val, "Content-Type": "application/json"},
    )

    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_hmac_auth_invalid_signature():
    settings.ENV = "production"
    settings.HMAC_SECRET_KEY = "test_secret_key"

    timestamp = str(int(time.time()))
    header_val = f"t={timestamp},v1=invalid_signature_hex"

    response = client.post(
        "/test-auth",
        content=b'{"hello":"world"}',
        headers={"X-VNL-Signature": header_val, "Content-Type": "application/json"},
    )

    assert response.status_code == 401
    assert "Invalid HMAC signature" in response.json()["detail"]


def test_hmac_auth_dev_mode_bypass():
    settings.ENV = "development"

    response = client.post(
        "/test-auth",
        content=b'{"hello":"world"}',
        headers={"Content-Type": "application/json"},
    )

    assert response.status_code == 200
