import os
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    HMAC_SECRET_KEY: str = "vnl-default-secret-key-change-in-production"
    FIREBASE_STORAGE_BUCKET: str = ""
    PORT: int = 8080
    ENV: str = "development"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()
