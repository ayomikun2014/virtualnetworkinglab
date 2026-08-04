import * as crypto from "crypto";

/**
 * Computes an HMAC-SHA256 signature header for payload verification.
 * Format: t=<timestamp>,v1=<hex_signature>
 * Message signed: `${t}.${JSON.stringify(payload)}`
 *
 * @param payload - Request body object to sign.
 * @param secret - Shared secret key.
 * @returns Formatted X-VNL-Signature header string.
 */
export function generateHmacSignature(payload: object, secret: string): string {
  const timestamp = Math.floor(Date.now() / 1000).toString();
  const serializedPayload = JSON.stringify(payload);
  const message = `${timestamp}.${serializedPayload}`;

  const hash = crypto
    .createHmac("sha256", secret)
    .update(message, "utf8")
    .digest("hex");

  return `t=${timestamp},v1=${hash}`;
}
