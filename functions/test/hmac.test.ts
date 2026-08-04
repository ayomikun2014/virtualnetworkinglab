import { generateHmacSignature } from '../src/utils/hmac';
import * as crypto from 'crypto';

describe('HMAC Signature Utility', () => {
  it('should generate a valid t=... and v1=... signature string', () => {
    const payload = { queueId: 'test_queue_123', userId: 'user_456' };
    const secret = 'vnl_secret_key_123';

    const sigHeader = generateHmacSignature(payload, secret);

    expect(sigHeader).toMatch(/^t=\d+,v1=[a-f0-9]{64}$/);

    const parts = Object.fromEntries(
      sigHeader.split(',').map((p) => p.split('='))
    );

    expect(parts.t).toBeDefined();
    expect(parts.v1).toBeDefined();

    // Verify hash calculation independently
    const expectedMessage = `${parts.t}.${JSON.stringify(payload)}`;
    const expectedHash = crypto
      .createHmac('sha256', secret)
      .update(expectedMessage, 'utf8')
      .digest('hex');

    expect(parts.v1).toEqual(expectedHash);
  });
});
