import { defineSecret } from "firebase-functions/params";

/**
 * Secret parameter for HMAC-SHA256 signature generation.
 * Managed securely via Google Cloud Secret Manager / Firebase Secrets.
 *
 * Set it with:
 *   firebase functions:secrets:set HMAC_SECRET_KEY
 *
 * The SAME value must be set on the Cloud Run engine, or every signature will
 * be rejected with 401.
 */
export const HMAC_SECRET_KEY = defineSecret("HMAC_SECRET_KEY");

/**
 * Base URL of the FastAPI simulation engine running on Cloud Run.
 *
 * Supplied through `functions/.env` (or `functions/.env.<project-id>`), which
 * the Firebase CLI bundles into the deployed function's environment. See
 * `functions/.env.example`.
 *
 * The localhost fallback is for the Functions emulator ONLY. A deployed
 * function has no localhost engine to talk to, so falling back there silently
 * produced a 45-second axios timeout and a queue document stuck on 'failed'
 * with an ECONNREFUSED message that pointed nowhere. `assertEngineUrlIsUsable`
 * below turns that into an explicit, readable error instead.
 */
export const FASTAPI_ENGINE_URL =
  process.env.FASTAPI_ENGINE_URL || "http://localhost:8080";

/** True when running under the local Functions emulator. */
export function isEmulator(): boolean {
  return process.env.FUNCTIONS_EMULATOR === "true";
}

/**
 * Throws if the configured engine URL cannot possibly work in the current
 * environment.
 *
 * Called at dispatch time rather than at module load: throwing during module
 * evaluation would break `firebase deploy`, which loads the code to discover
 * the function definitions before any environment file is applied.
 */
export function assertEngineUrlIsUsable(): void {
  const isLocal =
    FASTAPI_ENGINE_URL.includes("localhost") ||
    FASTAPI_ENGINE_URL.includes("127.0.0.1");

  if (isLocal && !isEmulator()) {
    throw new Error(
      "FASTAPI_ENGINE_URL is not configured. The deployed function is trying " +
        `to reach '${FASTAPI_ENGINE_URL}', which does not exist in Cloud ` +
        "Functions. Put the Cloud Run service URL in functions/.env as " +
        "FASTAPI_ENGINE_URL=https://<service>-<hash>-<region>.a.run.app and " +
        "redeploy with: firebase deploy --only functions"
    );
  }
}
