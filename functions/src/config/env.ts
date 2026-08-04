import { defineSecret } from "firebase-functions/params";

/**
 * Secret parameter for HMAC-SHA256 signature generation.
 * Managed securely via Google Cloud Secret Manager / Firebase Secrets.
 */
export const HMAC_SECRET_KEY = defineSecret("HMAC_SECRET_KEY");

/**
 * Target Cloud Run FastAPI Simulation Engine Base URL.
 */
export const FASTAPI_ENGINE_URL = process.env.FASTAPI_ENGINE_URL || "http://localhost:8080";
