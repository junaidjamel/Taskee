// Minimal type shim for the node:crypto APIs used by the Worker.
// The Workers runtime provides these via the nodejs_compat flag;
// this keeps `tsc --strict` happy without pulling in @types/node.
declare module 'node:crypto' {
  export function pbkdf2Sync(
    password: string | Uint8Array,
    salt: string | Uint8Array,
    iterations: number,
    keylen: number,
    digest: string,
  ): Uint8Array;
  export function randomBytes(size: number): Uint8Array;
}
