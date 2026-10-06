// Prints a SQL statement that sets a user's password in the format the Worker expects.
// Usage: node scripts/reset-password-sql.mjs you@example.com 'new password'
// Paste the output into the Neon SQL editor.
import { pbkdf2Sync, randomBytes } from 'node:crypto';

const [email, password] = process.argv.slice(2);
if (!email || !password || password.length < 8) {
  console.error("Usage: node scripts/reset-password-sql.mjs <email> '<password, 8+ chars>'");
  process.exit(1);
}

const iterations = 100000;
const salt = randomBytes(16);
const hash = pbkdf2Sync(password, salt, iterations, 32, 'sha256').toString('hex');
const quote = (value) => `'${value.replaceAll("'", "''")}'`;
console.log(
  `update users set password_salt = ${quote(salt.toString('hex'))}, ` +
    `password_hash = ${quote(`pbkdf2-sha256$${iterations}$${hash}`)} ` +
    `where email = ${quote(email.trim().toLowerCase())};`,
);
