import os
import secrets
import sys

from pydantic_settings import BaseSettings, SettingsConfigDict


# The value that shipped in the committed .env. Anyone who has seen the repo
# knows it, so it must never be able to sign real requests.
INSECURE_DEFAULT_SECRET = "vnl-default-secret-key-change-in-production"


class Settings(BaseSettings):
    # No default. The secret has to be supplied by the environment; see
    # _validate() below for why a fallback would be dangerous.
    HMAC_SECRET_KEY: str = ""
    FIREBASE_STORAGE_BUCKET: str = ""
    PORT: int = 8080
    ENV: str = "development"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()


def _validate() -> None:
    """Refuse to run with a missing or publicly-known HMAC secret.

    The HMAC signature is the ONLY thing authenticating the simulation engine's
    /simulate endpoint. If the secret is the committed default, anyone can sign
    a valid request and run arbitrary topologies against the engine, so treating
    that case as 'good enough for now' would leave the service open.

    Behaviour differs by environment on purpose:
      * production  -> hard exit. Never silently downgrade security.
      * development -> generate a random per-process key and warn loudly. Tests
        and local runs stay convenient, but the key does not persist and cannot
        accidentally become the production one.
    """
    is_production = settings.ENV.lower() in ("production", "prod", "staging")
    key = settings.HMAC_SECRET_KEY.strip()

    if not key or key == INSECURE_DEFAULT_SECRET:
        problem = "is not set" if not key else "is still the published default"

        if is_production:
            sys.stderr.write(
                f"\nFATAL: HMAC_SECRET_KEY {problem}.\n"
                "The simulation engine will not start in production without a "
                "unique secret.\n"
                "Generate one with:  python -c \"import secrets; "
                'print(secrets.token_urlsafe(48))"\n'
                "then set it as an environment variable (or a Secret Manager "
                "entry) named HMAC_SECRET_KEY.\n"
                "It must match the value the Cloud Function signs with.\n\n"
            )
            raise SystemExit(1)

        settings.HMAC_SECRET_KEY = secrets.token_urlsafe(48)
        sys.stderr.write(
            f"WARNING: HMAC_SECRET_KEY {problem}. A random development key has "
            "been generated for this process only. Requests signed elsewhere "
            "will be rejected. Set HMAC_SECRET_KEY to test the real flow.\n"
        )


# Skipped under pytest: the auth tests set settings.HMAC_SECRET_KEY themselves,
# and a random key here would make them non-deterministic.
if "pytest" not in sys.modules and os.getenv("VNL_SKIP_CONFIG_VALIDATION") != "1":
    _validate()
