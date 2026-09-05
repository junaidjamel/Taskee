import { neon } from '@neondatabase/serverless';

interface Env {
  DATABASE_URL: string;
  RESOURCE_FILES: R2Bucket;
  OPENAI_API_KEY?: string;
}

const encoder = new TextEncoder();
const corsHeaders = {
  'access-control-allow-origin': '*',
  'access-control-allow-headers': 'authorization, content-type, x-file-name',
  'access-control-allow-methods': 'GET, POST, PUT, DELETE, OPTIONS',
};

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'content-type': 'application/json; charset=utf-8' },
  });
}

function toHex(bytes: ArrayBuffer): string {
  return [...new Uint8Array(bytes)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

function fromHex(value: string): Uint8Array {
  return new Uint8Array(value.match(/.{1,2}/g)?.map((part) => parseInt(part, 16)) ?? []);
}

function bytesToBase64(bytes: Uint8Array): string {
  let binary = '';
  const chunkSize = 0x8000;
  for (let i = 0; i < bytes.length; i += chunkSize) {
    binary += String.fromCharCode(...bytes.subarray(i, Math.min(i + chunkSize, bytes.length)));
  }
  return btoa(binary);
}

async function hashToken(token: string): Promise<string> {
  return toHex(await crypto.subtle.digest('SHA-256', encoder.encode(token)));
}

async function hashPassword(password: string, saltHex?: string): Promise<{ salt: string; hash: string }> {
  const saltBytes = saltHex ? fromHex(saltHex) : crypto.getRandomValues(new Uint8Array(16));
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(password),
    'PBKDF2',
    false,
    ['deriveBits'],
  );
  const bits = await crypto.subtle.deriveBits(
    { name: 'PBKDF2', hash: 'SHA-256', salt: saltBytes, iterations: 120000 },
    key,
    256,
  );
  return { salt: toHex(saltBytes.buffer), hash: toHex(bits) };
}

async function readJson(request: Request): Promise<Record<string, any>> {
  try {
    return (await request.json()) as Record<string, any>;
  } catch {
    throw new Error('Invalid JSON body.');
  }
}

async function issueSession(sql: ReturnType<typeof neon>, userId: string): Promise<string> {
  const token = `${crypto.randomUUID()}${crypto.randomUUID().replaceAll('-', '')}`;
  const tokenHash = await hashToken(token);
  await sql`
    insert into sessions (token_hash, user_id, expires_at)
    values (${tokenHash}, ${userId}, now() + interval '30 days')
  `;
  return token;
}

async function requireUser(request: Request, sql: ReturnType<typeof neon>): Promise<string> {
  const auth = request.headers.get('authorization') ?? '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7).trim() : '';
  if (!token) throw new ResponseError(401, 'Authentication required.');

  const tokenHash = await hashToken(token);
  const rows = await sql`
    select user_id
    from sessions
    where token_hash = ${tokenHash}
      and expires_at > now()
    limit 1
  `;
  if (!rows.length) throw new ResponseError(401, 'Session expired. Sign in again.');
  return rows[0].user_id as string;
}

async function analyzeImage(request: Request, env: Env): Promise<Response> {
  if (!env.OPENAI_API_KEY) {
    throw new ResponseError(503, 'Image intelligence is not configured.');
  }

  const contentType = (request.headers.get('content-type') ?? 'image/png').split(';')[0].trim();
  if (!contentType.startsWith('image/')) {
    throw new ResponseError(400, 'An image is required.');
  }

  const buffer = await request.arrayBuffer();
  if (!buffer.byteLength) throw new ResponseError(400, 'Image was empty.');
  if (buffer.byteLength > 10 * 1024 * 1024) {
    throw new ResponseError(413, 'Image is too large. Keep it under 10 MB.');
  }

  const dataUrl = `data:${contentType};base64,${bytesToBase64(new Uint8Array(buffer))}`;
  const openAiResponse = await fetch('https://api.openai.com/v1/responses', {
    method: 'POST',
    headers: {
      authorization: `Bearer ${env.OPENAI_API_KEY}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-5-mini',
      input: [
        {
          role: 'system',
          content: [
            {
              type: 'input_text',
              text: 'You are the image-understanding layer for Resource Memory, an app that saves coding and learning resources. Inspect screenshots carefully. Identify the actual resource, tool, repository, tutorial, creator, URL/domain, technologies, and practical use case shown in the image. If a visible domain lacks a scheme, return it as https://domain. Do not invent a URL that is not visible or strongly implied by an unmistakable product domain. Keep summaries concise and retrieval-oriented.',
            },
          ],
        },
        {
          role: 'user',
          content: [
            {
              type: 'input_text',
              text: 'Analyze this saved screenshot and return the resource metadata Future Me should be able to search and resurface later.',
            },
            {
              type: 'input_image',
              image_url: dataUrl,
              detail: 'high',
            },
          ],
        },
      ],
      text: {
        format: {
          type: 'json_schema',
          name: 'resource_image_analysis',
          strict: true,
          schema: {
            type: 'object',
            additionalProperties: false,
            required: [
              'title',
              'url',
              'creator',
              'platform',
              'summary',
              'whyUseful',
              'useWhen',
              'topics',
              'technologies',
              'resourceType',
            ],
            properties: {
              title: { type: 'string' },
              url: { type: ['string', 'null'] },
              creator: { type: ['string', 'null'] },
              platform: { type: ['string', 'null'] },
              summary: { type: 'string' },
              whyUseful: { type: 'string' },
              useWhen: { type: 'string' },
              topics: { type: 'array', items: { type: 'string' } },
              technologies: { type: 'array', items: { type: 'string' } },
              resourceType: {
                type: 'string',
                enum: ['website', 'video', 'github', 'screenshot', 'article', 'tool', 'tutorial', 'code', 'other'],
              },
            },
          },
        },
      },
    }),
  });

  const payload = (await openAiResponse.json()) as Record<string, any>;
  if (!openAiResponse.ok) {
    console.error('OpenAI image analysis failed', payload);
    throw new ResponseError(502, 'Could not understand this image right now.');
  }

  const outputText = payload.output_text;
  if (typeof outputText !== 'string' || !outputText.trim()) {
    throw new ResponseError(502, 'Image analysis returned no result.');
  }

  try {
    return json(JSON.parse(outputText));
  } catch {
    throw new ResponseError(502, 'Image analysis returned an invalid result.');
  }
}

function audioExtension(contentType: string): string {
  if (contentType.includes('wav')) return 'wav';
  if (contentType.includes('mpeg')) return 'mp3';
  if (contentType.includes('mp4') || contentType.includes('m4a')) return 'm4a';
  if (contentType.includes('ogg') || contentType.includes('opus')) return 'ogg';
  if (contentType.includes('webm')) return 'webm';
  return 'wav';
}

async function analyzeAudio(request: Request, env: Env): Promise<Response> {
  if (!env.OPENAI_API_KEY) {
    throw new ResponseError(503, 'Voice intelligence is not configured.');
  }

  const contentType = (request.headers.get('content-type') ?? 'audio/wav').split(';')[0].trim();
  if (!contentType.startsWith('audio/')) {
    throw new ResponseError(400, 'An audio recording is required.');
  }

  const buffer = await request.arrayBuffer();
  if (!buffer.byteLength) throw new ResponseError(400, 'Audio was empty.');
  if (buffer.byteLength > 25 * 1024 * 1024) {
    throw new ResponseError(413, 'Audio is too large. Keep voice notes under 25 MB.');
  }

  const form = new FormData();
  form.append('model', 'gpt-transcribe');
  form.append(
    'file',
    new File([buffer], `voice-note.${audioExtension(contentType)}`, { type: contentType }),
  );

  const transcriptionResponse = await fetch('https://api.openai.com/v1/audio/transcriptions', {
    method: 'POST',
    headers: { authorization: `Bearer ${env.OPENAI_API_KEY}` },
    body: form,
  });
  const transcriptionPayload = (await transcriptionResponse.json()) as Record<string, any>;
  if (!transcriptionResponse.ok) {
    console.error('OpenAI transcription failed', transcriptionPayload);
    throw new ResponseError(502, 'Could not transcribe this voice note right now.');
  }

  const transcript = String(transcriptionPayload.text ?? '').trim();
  if (!transcript) throw new ResponseError(502, 'Voice note produced no transcript.');

  const metadataResponse = await fetch('https://api.openai.com/v1/responses', {
    method: 'POST',
    headers: {
      authorization: `Bearer ${env.OPENAI_API_KEY}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-5-mini',
      input: [
        {
          role: 'system',
          content: [
            {
              type: 'input_text',
              text: 'You are the voice-memory layer for Resource Memory. Convert a spoken note into concise retrieval metadata. Preserve what the speaker actually said. Identify tools, sites, repositories, technologies, people, project context, and any spoken URL. Do not invent URLs or facts. The goal is to make this memory searchable and useful later.',
            },
          ],
        },
        {
          role: 'user',
          content: [
            {
              type: 'input_text',
              text: `Turn this voice note into a saved resource. Transcript:\n\n${transcript}`,
            },
          ],
        },
      ],
      text: {
        format: {
          type: 'json_schema',
          name: 'resource_voice_analysis',
          strict: true,
          schema: {
            type: 'object',
            additionalProperties: false,
            required: [
              'title',
              'url',
              'creator',
              'platform',
              'summary',
              'whyUseful',
              'useWhen',
              'topics',
              'technologies',
              'resourceType',
            ],
            properties: {
              title: { type: 'string' },
              url: { type: ['string', 'null'] },
              creator: { type: ['string', 'null'] },
              platform: { type: ['string', 'null'] },
              summary: { type: 'string' },
              whyUseful: { type: 'string' },
              useWhen: { type: 'string' },
              topics: { type: 'array', items: { type: 'string' } },
              technologies: { type: 'array', items: { type: 'string' } },
              resourceType: {
                type: 'string',
                enum: ['website', 'video', 'github', 'article', 'tool', 'tutorial', 'code', 'other'],
              },
            },
          },
        },
      },
    }),
  });

  const metadataPayload = (await metadataResponse.json()) as Record<string, any>;
  if (!metadataResponse.ok) {
    console.error('OpenAI voice metadata failed', metadataPayload);
    throw new ResponseError(502, 'Could not understand this voice note right now.');
  }

  const outputText = metadataPayload.output_text;
  if (typeof outputText !== 'string' || !outputText.trim()) {
    throw new ResponseError(502, 'Voice analysis returned no result.');
  }

  try {
    return json({ ...JSON.parse(outputText), transcript });
  } catch {
    throw new ResponseError(502, 'Voice analysis returned an invalid result.');
  }
}

class ResponseError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: corsHeaders });
    if (!env.DATABASE_URL) return json({ error: 'DATABASE_URL is not configured.' }, 503);

    const sql = neon(env.DATABASE_URL);
    const url = new URL(request.url);
    const path = url.pathname.replace(/\/+$/, '') || '/';

    try {
      if (request.method === 'GET' && path === '/health') {
        return json({
          ok: true,
          service: 'resource-memory-api',
          imageIntelligenceConfigured: Boolean(env.OPENAI_API_KEY),
          voiceIntelligenceConfigured: Boolean(env.OPENAI_API_KEY),
        });
      }

      if (request.method === 'POST' && path === '/auth/register') {
        const body = await readJson(request);
        const email = String(body.email ?? '').trim().toLowerCase();
        const password = String(body.password ?? '');
        if (!email.includes('@')) throw new ResponseError(400, 'Enter a valid email address.');
        if (password.length < 8) throw new ResponseError(400, 'Password must be at least 8 characters.');

        const existing = await sql`select id from users where email = ${email} limit 1`;
        if (existing.length) throw new ResponseError(409, 'An account with that email already exists.');

        const userId = crypto.randomUUID();
        const passwordRecord = await hashPassword(password);
        await sql`
          insert into users (id, email, password_salt, password_hash)
          values (${userId}, ${email}, ${passwordRecord.salt}, ${passwordRecord.hash})
        `;
        const token = await issueSession(sql, userId);
        return json({ token, email }, 201);
      }

      if (request.method === 'POST' && path === '/auth/login') {
        const body = await readJson(request);
        const email = String(body.email ?? '').trim().toLowerCase();
        const password = String(body.password ?? '');
        const rows = await sql`
          select id, email, password_salt, password_hash
          from users
          where email = ${email}
          limit 1
        `;
        if (!rows.length) throw new ResponseError(401, 'Email or password is incorrect.');

        const check = await hashPassword(password, rows[0].password_salt as string);
        if (check.hash !== rows[0].password_hash) {
          throw new ResponseError(401, 'Email or password is incorrect.');
        }
        const token = await issueSession(sql, rows[0].id as string);
        return json({ token, email: rows[0].email });
      }

      if (request.method === 'POST' && path === '/auth/logout') {
        const auth = request.headers.get('authorization') ?? '';
        const token = auth.startsWith('Bearer ') ? auth.slice(7).trim() : '';
        if (token) {
          const tokenHash = await hashToken(token);
          await sql`delete from sessions where token_hash = ${tokenHash}`;
        }
        return json({ ok: true });
      }

      if (request.method === 'POST' && path === '/analyze-image') {
        await requireUser(request, sql);
        return analyzeImage(request, env);
      }

      if (request.method === 'POST' && path === '/analyze-audio') {
        await requireUser(request, sql);
        return analyzeAudio(request, env);
      }

      if (request.method === 'GET' && path === '/resources') {
        const userId = await requireUser(request, sql);
        const rows = await sql`
          select data
          from resources
          where user_id = ${userId}
          order by updated_at desc
        `;
        return json({ resources: rows.map((row) => row.data) });
      }

      if (request.method === 'POST' && path === '/sync') {
        const userId = await requireUser(request, sql);
        const body = await readJson(request);
        const resources = Array.isArray(body.resources) ? body.resources : [];
        for (const item of resources) {
          const id = String(item?.id ?? '');
          if (!id) continue;
          await sql`
            insert into resources (user_id, id, data, updated_at)
            values (${userId}, ${id}, ${JSON.stringify(item)}::jsonb, now())
            on conflict (user_id, id)
            do update set data = excluded.data, updated_at = now()
          `;
        }
        return json({ ok: true, count: resources.length });
      }

      const resourceMatch = path.match(/^\/resources\/([^/]+)$/);
      if (resourceMatch && request.method === 'PUT') {
        const userId = await requireUser(request, sql);
        const id = decodeURIComponent(resourceMatch[1]);
        const body = await readJson(request);
        const data = body.data;
        if (!data || typeof data !== 'object') throw new ResponseError(400, 'Resource data is required.');
        await sql`
          insert into resources (user_id, id, data, updated_at)
          values (${userId}, ${id}, ${JSON.stringify(data)}::jsonb, now())
          on conflict (user_id, id)
          do update set data = excluded.data, updated_at = now()
        `;
        return json({ ok: true });
      }

      if (resourceMatch && request.method === 'DELETE') {
        const userId = await requireUser(request, sql);
        const id = decodeURIComponent(resourceMatch[1]);
        await sql`delete from resources where user_id = ${userId} and id = ${id}`;
        const objects = await env.RESOURCE_FILES.list({ prefix: `${userId}/${id}/` });
        await Promise.all(objects.objects.map((object) => env.RESOURCE_FILES.delete(object.key)));
        return json({ ok: true });
      }

      const uploadMatch = path.match(/^\/uploads\/([^/]+)$/);
      if (uploadMatch && request.method === 'POST') {
        const userId = await requireUser(request, sql);
        const resourceId = decodeURIComponent(uploadMatch[1]);
        const fileName = request.headers.get('x-file-name') || 'resource-file';
        const safeName = fileName.replace(/[^a-zA-Z0-9._-]/g, '_');
        const key = `${userId}/${resourceId}/${crypto.randomUUID()}-${safeName}`;
        await env.RESOURCE_FILES.put(key, request.body, {
          httpMetadata: { contentType: request.headers.get('content-type') ?? 'application/octet-stream' },
          customMetadata: { userId, resourceId, fileName },
        });
        return json({ ok: true, assetPath: `/assets/${encodeURIComponent(resourceId)}` }, 201);
      }

      const assetMatch = path.match(/^\/assets\/([^/]+)$/);
      if (assetMatch && request.method === 'GET') {
        const userId = await requireUser(request, sql);
        const resourceId = decodeURIComponent(assetMatch[1]);
        const list = await env.RESOURCE_FILES.list({ prefix: `${userId}/${resourceId}/`, limit: 1 });
        if (!list.objects.length) throw new ResponseError(404, 'File not found.');
        const object = await env.RESOURCE_FILES.get(list.objects[0].key);
        if (!object) throw new ResponseError(404, 'File not found.');
        const headers = new Headers(corsHeaders);
        object.writeHttpMetadata(headers);
        headers.set('etag', object.httpEtag);
        return new Response(object.body, { headers });
      }

      return json({ error: 'Not found.' }, 404);
    } catch (error) {
      if (error instanceof ResponseError) return json({ error: error.message }, error.status);
      console.error(error);
      return json({ error: 'Unexpected server error.' }, 500);
    }
  },
};
