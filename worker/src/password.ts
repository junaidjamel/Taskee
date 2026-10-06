import { pbkdf2Sync, randomBytes, timingSafeEqual } from 'node:crypto';
import { Buffer } from 'node:buffer';

const ITERATIONS = 120000;
const PREFIX = 'pbkdf2-sha256';
const SALT_HEX = /^[0-9a-f]{32}$/i;
const HASH_HEX = /^[0-9a-f]{64}$/i;

function derive(password: string, saltHex: string, iterations: number): string {
  // node:crypto supports the original 120k parameters in Workers. Changing
  // the count when checking a legacy hash would invalidate existing passwords.
  return pbkdf2Sync(password, Buffer.from(saltHex, 'hex'), iterations, 32, 'sha256').toString('hex');
}

export async function hashPassword(password: string, saltHex?: string): Promise<{ salt: string; hash: string }> {
  const salt = saltHex ?? randomBytes(16).toString('hex');
  if (!SALT_HEX.test(salt)) throw new Error('Invalid password salt.');
  return { salt, hash: `${PREFIX}$${ITERATIONS}$${derive(password, salt, ITERATIONS)}` };
}

export async function verifyPassword(
  password: string,
  saltHex: string,
  storedHash: string,
): Promise<{ ok: boolean; needsReset: boolean; needsRehash: boolean }> {
  const invalid = { ok: false, needsReset: true, needsRehash: false };
  try {
    if (typeof saltHex !== 'string' || !SALT_HEX.test(saltHex) || typeof storedHash !== 'string') return invalid;

    const modular = /^pbkdf2-sha256\$([1-9][0-9]{0,5})\$([0-9a-f]{64})$/i.exec(storedHash);
    const legacy = HASH_HEX.test(storedHash);
    if (!modular && !legacy) return invalid;

    const iterations = modular ? Number(modular[1]) : ITERATIONS;
    // Bound the work before calling crypto, including malformed database rows.
    if (iterations > ITERATIONS) return invalid;
    const expected = modular ? modular[2] : storedHash;
    const actual = derive(password, saltHex, iterations);
    const ok = timingSafeEqual(Buffer.from(actual, 'hex'), Buffer.from(expected, 'hex'));
    return { ok, needsReset: false, needsRehash: ok && (legacy || iterations !== ITERATIONS) };
  } catch {
    return invalid;
  }
}

export async function passwordCryptoSelfTest(): Promise<boolean> {
  // Test the actual iteration count against a known PBKDF2-SHA256 vector,
  // rather than a cheap probe that can pass while real login hashing fails.
  try {
    const record = await hashPassword('health-probe', '00000000000000000000000000000000');
    return record.hash === `${PREFIX}$${ITERATIONS}$81def367047cb9311fd913f04221e4bdbb12bf90f399acaa51e330db6dc34afd`;
  } catch {
    return false;
  }
}
