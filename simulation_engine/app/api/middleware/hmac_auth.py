import hmac
import hashlib
import time
from fastapi import Request, HTTPException, Security
from fastapi.security import APIKeyHeader
from app.core.config import settings

X_VNL_SIGNATURE_HEADER = APIKeyHeader(name="X-VNL-Signature", auto_error=False)


async def verify_hmac_signature(
    request: Request,
    signature_header: str | None = Security(X_VNL_SIGNATURE_HEADER),
) -> bool:
    """
    Dependency that verifies the HMAC-SHA256 signature in the X-VNL-Signature header.
    Expected header format: t=<timestamp>,v1=<hmac_hex>
    Signature string: timestamp.body_bytes
    """
    if not signature_header:
        if settings.ENV == "development":
            return True
        raise HTTPException(
            status_code=401,
            detail="Missing X-VNL-Signature header",
        )

    # Parse header parameters e.g., t=1700000000,v1=abcdef...
    parts = {}
    for item in signature_header.split(","):
        if "=" in item:
            k, v = item.split("=", 1)
            parts[k.strip()] = v.strip()

    timestamp = parts.get("t")
    received_sig = parts.get("v1")

    # Fallback if raw hex string was passed directly
    if not timestamp or not received_sig:
        received_sig = signature_header.strip()
        timestamp = ""

    body_bytes = await request.body()
    secret_bytes = settings.HMAC_SECRET_KEY.encode("utf-8")

    if timestamp:
        try:
            ts_int = int(timestamp)
            if abs(time.time() - ts_int) > 300:  # 5 minutes window
                if settings.ENV != "development":
                    raise HTTPException(
                        status_code=401,
                        detail="X-VNL-Signature timestamp expired",
                    )
        except ValueError:
            pass

        message = f"{timestamp}.".encode("utf-8") + body_bytes
    else:
        message = body_bytes

    expected_sig = hmac.new(secret_bytes, message, hashlib.sha256).hexdigest()

    if not hmac.compare_digest(received_sig.lower(), expected_sig.lower()):
        raise HTTPException(
            status_code=401,
            detail="Invalid HMAC signature",
        )

    return True

