const baseUrl = process.argv[2] ?? 'https://resource-memory-api.madincrease.workers.dev';
try {
  const response = await fetch(new URL('/health', baseUrl), { signal: AbortSignal.timeout(15000) });
  const health = await response.json();
  if (!response.ok || health.ok !== true || health.passwordCryptoOk !== true || health.build !== 'password-compat-v2') {
    throw new Error('Worker is unhealthy or still running old code. Deploy the latest worker and retry.');
  }
  console.log('Worker is running password-compat-v2; password hashing passed.');
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
