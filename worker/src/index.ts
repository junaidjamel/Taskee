import { neon, type NeonQueryFunction } from '@neondatabase/serverless';
import { hashPassword, verifyPassword, passwordCryptoSelfTest } from './password';

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

async function readJson(request: Request): Promise<Record<string, any>> {
  try {
    return (await request.json()) as Record<string, any>;
  } catch {
    throw new Error('Invalid JSON body.');
  }
}

async function issueSession(sql: SqlClient, userId: string): Promise<string> {
  const token = `${crypto.randomUUID()}${crypto.randomUUID().replaceAll('-', '')}`;
  const tokenHash = await hashToken(token);
  await sql`
    insert into sessions (token_hash, user_id, expires_at)
    values (${tokenHash}, ${userId}, now() + interval '30 days')
  `;
  return token;
}

async function requireUser(request: Request, sql: SqlClient): Promise<string> {
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

type SessionTab = {
  title: string;
  url: string;
  windowId?: number;
  groupId?: number;
  lastAccessed?: number | null;
};

function domainLabel(rawUrl: string): string {
  try {
    return new URL(rawUrl).hostname.replace(/^www\./, '') || 'Other';
  } catch {
    return 'Other';
  }
}

function deterministicSessionAnalysis(tabs: SessionTab[]) {
  const buckets = new Map<string, SessionTab[]>();
  for (const tab of tabs) {
    const domain = domainLabel(tab.url);
    const current = buckets.get(domain) ?? [];
    current.push(tab);
    buckets.set(domain, current);
  }

  const groups = [...buckets.entries()]
    .sort((a, b) => b[1].length - a[1].length)
    .slice(0, 6)
    .map(([domain, groupTabs]) => ({
      title: domain,
      whatYouWereDoing: `${groupTabs.length} tab${groupTabs.length === 1 ? '' : 's'} open here`,
      tabs: groupTabs.map(({ title, url }) => ({ title, url })),
    }));

  return {
    title: groups.slice(0, 3).map((group) => group.title).join(', ') || 'Tab session',
    summary: `${groups.length} things in progress across ${tabs.length} tabs`,
    groups,
  };
}

async function analyzeSession(request: Request, env: Env): Promise<Response> {
  const body = await readJson(request);
  const tabs = Array.isArray(body.tabs)
    ? body.tabs
        .map((raw: any) => ({
          title: String(raw?.title ?? '').trim(),
          url: String(raw?.url ?? '').trim(),
          windowId: Number.isFinite(raw?.windowId) ? Number(raw.windowId) : undefined,
          groupId: Number.isFinite(raw?.groupId) ? Number(raw.groupId) : undefined,
          lastAccessed: Number.isFinite(raw?.lastAccessed) ? Number(raw.lastAccessed) : null,
        }))
        .filter((tab: SessionTab) => tab.title && /^https?:\/\//i.test(tab.url))
    : [];

  if (!tabs.length) throw new ResponseError(400, 'At least one browser tab is required.');
  if (tabs.length > 500) throw new ResponseError(413, 'Too many tabs in one session.');

  const fallback = deterministicSessionAnalysis(tabs);
  if (!env.OPENAI_API_KEY) return json(fallback);

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
          content: [{
            type: 'input_text',
            text: 'You group browser tabs into 1 to 6 memory-oriented work contexts for NanyNany. Use only the supplied titles and privacy-safe URLs. Do not infer deadlines, tasks, private facts, or page content. Explain what the user appears to have been doing in concise, neutral language. Every input tab must appear in exactly one group.',
          }],
        },
        {
          role: 'user',
          content: [{
            type: 'input_text',
            text: `Group this browser session for later retrieval:\n\n${JSON.stringify(tabs)}`,
          }],
        },
      ],
      text: {
        format: {
          type: 'json_schema',
          name: 'tab_session_analysis',
          strict: true,
          schema: {
            type: 'object',
            additionalProperties: false,
            required: ['title', 'summary', 'groups'],
            properties: {
              title: { type: 'string' },
              summary: { type: 'string' },
              groups: {
                type: 'array',
                minItems: 1,
                maxItems: 6,
                items: {
                  type: 'object',
                  additionalProperties: false,
                  required: ['title', 'whatYouWereDoing', 'tabs'],
                  properties: {
                    title: { type: 'string' },
                    whatYouWereDoing: { type: 'string' },
                    tabs: {
                      type: 'array',
                      items: {
                        type: 'object',
                        additionalProperties: false,
                        required: ['title', 'url'],
                        properties: {
                          title: { type: 'string' },
                          url: { type: 'string' },
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        },
      },
    }),
  });

  const payload = (await openAiResponse.json()) as Record<string, any>;
  if (!openAiResponse.ok || typeof payload.output_text !== 'string') {
    console.error('OpenAI session analysis failed', payload);
    return json(fallback);
  }

  try {
    const parsed = JSON.parse(payload.output_text);
    if (!Array.isArray(parsed.groups) || !parsed.groups.length) return json(fallback);
    return json(parsed);
  } catch {
    return json(fallback);
  }
}

// ---------------------------------------------------------------------------
// Semantic search: hybrid lexical + vector retrieval over the resources table.
// Writes build search_text and (when an OpenAI key is configured) a pgvector
// embedding. Reads combine full-text rank and vector similarity with a light
// recency rerank. Every step degrades gracefully when the key or the
// 002_memory_search.sql migration is missing.
// ---------------------------------------------------------------------------

const EMBEDDING_MODEL = 'text-embedding-3-small';
const EMBEDDING_DIMS = 1536;
const EMBED_INPUT_CHARS = 6000;

type SqlClient = NeonQueryFunction<false, false>;

function asRows(result: unknown): Record<string, any>[] {
  return (result ?? []) as unknown as Record<string, any>[];
}

export function asText(value: unknown): string {
  if (typeof value === 'string') return value.trim();
  if (Array.isArray(value)) {
    return value
      .map((entry) => (typeof entry === 'string' ? entry.trim() : ''))
      .filter(Boolean)
      .join(' ');
  }
  return '';
}

export function sessionSearchText(session: unknown): string {
  if (!session || typeof session !== 'object') return '';
  const groups = (session as { groups?: unknown }).groups;
  if (!Array.isArray(groups)) return '';
  const parts: string[] = [];
  for (const raw of groups) {
    if (!raw || typeof raw !== 'object') continue;
    const group = raw as { title?: unknown; whatYouWereDoing?: unknown; tabs?: unknown };
    parts.push(asText(group.title), asText(group.whatYouWereDoing));
    if (Array.isArray(group.tabs)) {
      for (const tabRaw of group.tabs) {
        if (!tabRaw || typeof tabRaw !== 'object') continue;
        const tab = tabRaw as { title?: unknown; url?: unknown };
        parts.push(asText(tab.title), asText(tab.url));
      }
    }
  }
  return parts.filter(Boolean).join(' ');
}

// Mirrors the Flutter Resource.searchableText getter so server-side lexical
// search covers the same fields the client used to search locally.
export function buildSearchText(data: Record<string, any>): string {
  return [
    asText(data.title),
    asText(data.creator),
    asText(data.platform),
    asText(data.summary),
    asText(data.whyUseful),
    asText(data.useWhen),
    asText(data.transcript),
    asText(data.topics),
    asText(data.technologies),
    asText(data.url),
    sessionSearchText(data.session),
  ]
    .filter(Boolean)
    .join(' ');
}

export function vectorLiteral(vector: number[]): string {
  return `[${vector.join(',')}]`;
}

async function embedTexts(texts: string[], apiKey: string): Promise<(number[] | null)[]> {
  if (!texts.length) return [];
  const inputs = texts.map((text) => text.slice(0, EMBED_INPUT_CHARS));
  try {
    const response = await fetch('https://api.openai.com/v1/embeddings', {
      method: 'POST',
      headers: {
        authorization: `Bearer ${apiKey}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({ model: EMBEDDING_MODEL, input: inputs }),
    });
    const payload = (await response.json()) as Record<string, any>;
    if (!response.ok || !Array.isArray(payload?.data)) {
      console.error('OpenAI embeddings failed', payload);
      return inputs.map(() => null);
    }
    const byIndex = new Map<number, number[]>();
    for (const row of payload.data) {
      if (
        Number.isInteger(row?.index) &&
        Array.isArray(row?.embedding) &&
        row.embedding.length === EMBEDDING_DIMS
      ) {
        byIndex.set(row.index, row.embedding);
      }
    }
    return inputs.map((_, i) => byIndex.get(i) ?? null);
  } catch (error) {
    console.error('OpenAI embeddings request failed', error);
    return inputs.map(() => null);
  }
}

interface IndexState {
  search_text: string | null;
  has_embedding: boolean;
}

function isMissingSearchColumn(error: unknown): boolean {
  const message = error instanceof Error ? error.message : String(error);
  return message.includes('search_text') && message.includes('does not exist');
}

async function loadExistingIndex(
  sql: SqlClient,
  userId: string,
  ids: string[],
): Promise<Map<string, IndexState> | null> {
  try {
    const rows = await sql`
      select id, search_text, (embedding is not null) as has_embedding
      from resources
      where user_id = ${userId} and id = any(${ids})
    `;
    const map = new Map<string, IndexState>();
    for (const row of asRows(rows)) {
      map.set(String(row.id), {
        search_text: typeof row.search_text === 'string' ? row.search_text : null,
        has_embedding: Boolean(row.has_embedding),
      });
    }
    return map;
  } catch (error) {
    if (isMissingSearchColumn(error)) return null;
    throw error;
  }
}

export interface IndexPlan {
  searchText: string;
  sourceType: string | null;
  resourceType: string | null;
  needsEmbedding: boolean;
  staleEmbedding: boolean;
  vector: string | null;
}

export function planIndex(data: Record<string, any>, existing?: IndexState): IndexPlan {
  const searchText = buildSearchText(data);
  const searchChanged = !existing || (existing.search_text ?? '') !== searchText;
  return {
    searchText,
    sourceType: asText(data.platform) || null,
    resourceType: asText(data.type) || null,
    needsEmbedding: Boolean(searchText) && (searchChanged || !existing?.has_embedding),
    staleEmbedding: searchChanged && Boolean(existing?.has_embedding),
    vector: null,
  };
}

async function fillEmbeddings(plans: IndexPlan[], apiKey: string | undefined): Promise<void> {
  const targets = plans.filter((plan) => plan.needsEmbedding && !plan.vector);
  if (!targets.length || !apiKey) return;
  const vectors = await embedTexts(
    targets.map((plan) => plan.searchText),
    apiKey,
  );
  targets.forEach((plan, i) => {
    const vector = vectors[i];
    if (vector && vector.length === EMBEDDING_DIMS) plan.vector = vectorLiteral(vector);
  });
}

async function writeIndexedResource(
  sql: SqlClient,
  userId: string,
  id: string,
  data: unknown,
  plan: IndexPlan | null,
): Promise<void> {
  const payload = JSON.stringify(data);
  if (!plan) {
    // Migration 002 not applied: keep the legacy write shape working.
    await sql`
      insert into resources (user_id, id, data, updated_at)
      values (${userId}, ${id}, ${payload}::jsonb, now())
      on conflict (user_id, id)
      do update set data = excluded.data, updated_at = now()
    `;
    return;
  }
  await sql`
    insert into resources (user_id, id, data, search_text, source_type, resource_type, updated_at)
    values (${userId}, ${id}, ${payload}::jsonb, ${plan.searchText || null}, ${plan.sourceType}, ${plan.resourceType}, now())
    on conflict (user_id, id)
    do update set
      data = excluded.data,
      search_text = excluded.search_text,
      source_type = excluded.source_type,
      resource_type = excluded.resource_type,
      updated_at = now()
  `;
  if (plan.vector) {
    await sql`
      update resources
      set embedding = ${plan.vector}::vector, embedding_model = ${EMBEDDING_MODEL}
      where user_id = ${userId} and id = ${id}
    `;
  } else if (plan.staleEmbedding) {
    await sql`
      update resources
      set embedding = null, embedding_model = null
      where user_id = ${userId} and id = ${id}
    `;
  }
}

interface SearchHit {
  id: string;
  data: unknown;
  lex: number;
  vec: number;
  ageDays: number;
  snippet: string;
}

function toSearchHit(row: Record<string, any>): SearchHit {
  return {
    id: String(row.id),
    data: row.data,
    lex: Number(row.lex_score) || 0,
    vec: Number(row.vec_score) || 0,
    ageDays: Math.max(0, Number(row.age_days) || 0),
    snippet: String(row.snippet ?? ''),
  };
}

async function hybridSearch(
  sql: SqlClient,
  userId: string,
  query: string,
  queryVec: string,
  types: string[],
): Promise<SearchHit[]> {
  const hasTypes = types.length > 0;
  const rows = await sql`
    with lex_hits as (
      select id,
        ts_rank_cd(
          to_tsvector('english', coalesce(search_text, '')),
          plainto_tsquery('english', ${query})
        ) as lex_score
      from resources
      where user_id = ${userId}
        and coalesce(search_text, '') <> ''
        and to_tsvector('english', coalesce(search_text, '')) @@ plainto_tsquery('english', ${query})
      order by lex_score desc
      limit 100
    ),
    vec_hits as (
      select id, 1 - (embedding <=> ${queryVec}::vector) as vec_score
      from resources
      where user_id = ${userId}
        and embedding is not null
      order by embedding <=> ${queryVec}::vector
      limit 100
    ),
    combined as (
      select coalesce(l.id, v.id) as id,
        coalesce(l.lex_score, 0) as lex_score,
        coalesce(v.vec_score, 0) as vec_score
      from lex_hits l
      full outer join vec_hits v on l.id = v.id
    )
    select r.id, r.data, c.lex_score, c.vec_score,
      extract(epoch from (now() - r.updated_at)) / 86400.0 as age_days,
      ts_headline(
        'english', coalesce(r.search_text, ''),
        plainto_tsquery('english', ${query}),
        'MaxWords=30, MinWords=12, MaxFragments=2'
      ) as snippet
    from combined c
    join resources r on r.user_id = ${userId} and r.id = c.id
    where (${hasTypes} = false or r.resource_type = any(${types}))
  `;
  return asRows(rows).map(toSearchHit);
}

async function lexicalSearch(
  sql: SqlClient,
  userId: string,
  query: string,
  types: string[],
  limit: number,
): Promise<SearchHit[]> {
  const hasTypes = types.length > 0;
  const rows = await sql`
    select r.id, r.data,
      ts_rank_cd(
        to_tsvector('english', coalesce(r.search_text, '')),
        plainto_tsquery('english', ${query})
      ) as lex_score,
      0 as vec_score,
      extract(epoch from (now() - r.updated_at)) / 86400.0 as age_days,
      ts_headline(
        'english', coalesce(r.search_text, ''),
        plainto_tsquery('english', ${query}),
        'MaxWords=30, MinWords=12, MaxFragments=2'
      ) as snippet
    from resources r
    where r.user_id = ${userId}
      and coalesce(r.search_text, '') <> ''
      and to_tsvector('english', coalesce(r.search_text, '')) @@ plainto_tsquery('english', ${query})
      and (${hasTypes} = false or r.resource_type = any(${types}))
    order by lex_score desc
    limit ${limit}
  `;
  return asRows(rows).map(toSearchHit);
}

async function legacyKeywordSearch(
  sql: SqlClient,
  userId: string,
  query: string,
  limit: number,
): Promise<SearchHit[]> {
  const rows = await sql`
    select id, data, 0.4 as lex_score, 0 as vec_score,
      extract(epoch from (now() - updated_at)) / 86400.0 as age_days,
      '' as snippet
    from resources
    where user_id = ${userId} and data::text ilike ${'%' + query + '%'}
    order by updated_at desc
    limit ${limit}
  `;
  return asRows(rows).map(toSearchHit);
}

export function matchedTerms(snippet: string): string[] {
  const terms = new Set<string>();
  const pattern = /<b>(.*?)<\/b>/g;
  let match: RegExpExecArray | null;
  while ((match = pattern.exec(snippet)) !== null) {
    const term = match[1].replace(/<[^>]*>/g, '').trim().toLowerCase();
    if (term) terms.add(term);
    if (terms.size >= 6) break;
  }
  return [...terms];
}

export function explainHit(
  hit: { lex: number; vec: number; ageDays: number; semantic: boolean },
  terms: string[],
): string[] {
  const why: string[] = [];
  if (terms.length) {
    why.push(`Matches: ${terms.slice(0, 4).join(', ')}`);
  } else if (hit.lex >= 0.2) {
    why.push('Matches your search words');
  }
  if (hit.semantic && hit.vec >= 0.55) why.push('Similar in meaning to your search');
  if (hit.ageDays <= 14) why.push('Saved recently');
  return why;
}

async function handleSearch(
  request: Request,
  sql: SqlClient,
  userId: string,
  apiKey: string | undefined,
): Promise<Response> {
  const body = await readJson(request);
  const query = String(body.query ?? '').trim();
  if (!query) throw new ResponseError(400, 'A search query is required.');
  if (query.length > 500) throw new ResponseError(400, 'Search query is too long.');
  const rawLimit = Number(body.limit);
  const limit = Math.min(50, Math.max(1, Number.isFinite(rawLimit) ? Math.floor(rawLimit) : 10));
  const types = (Array.isArray(body.types) ? body.types : [])
    .map((entry) => String(entry).trim())
    .filter(Boolean)
    .slice(0, 10);

  let queryVec: string | null = null;
  if (apiKey) {
    const vectors = await embedTexts([query], apiKey);
    const first = vectors[0];
    if (first && first.length === EMBEDDING_DIMS) queryVec = vectorLiteral(first);
  }

  let hits: SearchHit[];
  let semantic = Boolean(queryVec);
  try {
    hits = queryVec
      ? await hybridSearch(sql, userId, query, queryVec, types)
      : await lexicalSearch(sql, userId, query, types, limit);
  } catch (error) {
    if (!isMissingSearchColumn(error)) throw error;
    semantic = false;
    hits = await legacyKeywordSearch(sql, userId, query, limit);
  }

  const scored = hits
    .map((hit) => {
      const lex = Math.min(1, Math.max(0, hit.lex));
      const vec = Math.min(1, Math.max(0, hit.vec));
      const recency = 1 / (1 + hit.ageDays / 45);
      const score = semantic ? 0.45 * vec + 0.35 * lex + 0.2 * recency : 0.8 * lex + 0.2 * recency;
      const terms = matchedTerms(hit.snippet);
      return {
        hit,
        score,
        terms,
        why: explainHit({ lex, vec, ageDays: hit.ageDays, semantic }, terms),
      };
    })
    .sort((a, b) => b.score - a.score)
    .slice(0, limit);

  return json({
    query,
    semantic,
    count: scored.length,
    results: scored.map((entry) => ({
      resource: entry.hit.data,
      score: Math.round(entry.score * 1000) / 1000,
      snippet: entry.hit.snippet,
      matchedTerms: entry.terms,
      why: entry.why,
    })),
  });
}

async function handleReindex(
  sql: SqlClient,
  userId: string,
  apiKey: string | undefined,
): Promise<Response> {
  let batch: Record<string, any>[];
  try {
    batch = asRows(
      await sql`
        select id, data
        from resources
        where user_id = ${userId} and (search_text is null or embedding is null)
        order by updated_at desc
        limit 100
      `,
    );
  } catch (error) {
    if (isMissingSearchColumn(error)) {
      throw new ResponseError(503, 'Search indexing needs migration 002 applied to the database first.');
    }
    throw error;
  }

  let indexed = 0;
  if (batch.length) {
    const texts = batch.map((row) => buildSearchText((row.data ?? {}) as Record<string, any>));
    const vectors = apiKey ? await embedTexts(texts, apiKey) : [];
    for (let i = 0; i < batch.length; i++) {
      const row = batch[i];
      const data = (row.data ?? {}) as Record<string, any>;
      const vector = vectors[i];
      const literal = vector && vector.length === EMBEDDING_DIMS ? vectorLiteral(vector) : null;
      await sql`
        update resources
        set search_text = ${texts[i] || null},
          source_type = ${asText(data.platform) || null},
          resource_type = ${asText(data.type) || null},
          embedding = coalesce(${literal}::vector, embedding),
          embedding_model = case
            when ${literal}::vector is null then embedding_model
            else ${EMBEDDING_MODEL}
          end,
          updated_at = now()
        where user_id = ${userId} and id = ${String(row.id)}
      `;
      indexed += 1;
    }
  }

  const counts = asRows(
    await sql`
      select
        count(*) filter (where search_text is null)::int as pending_search_text,
        count(*) filter (where embedding is null)::int as pending_embeddings
      from resources
      where user_id = ${userId} and (search_text is null or embedding is null)
    `,
  );
  return json({
    ok: true,
    indexed,
    pendingSearchText: Number(counts[0]?.pending_search_text) || 0,
    pendingEmbeddings: Number(counts[0]?.pending_embeddings) || 0,
  });
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
        const passwordCryptoOk = await passwordCryptoSelfTest();
        return json({
          ok: passwordCryptoOk,
          service: 'resource-memory-api',
          imageIntelligenceConfigured: Boolean(env.OPENAI_API_KEY),
          voiceIntelligenceConfigured: Boolean(env.OPENAI_API_KEY),
          semanticSearchConfigured: Boolean(env.OPENAI_API_KEY),
          passwordCryptoOk,
          build: 'password-compat-v2',
        }, passwordCryptoOk ? 200 : 503);
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

        const check = await verifyPassword(
          password,
          rows[0].password_salt as string,
          rows[0].password_hash as string,
        );
        if (check.needsReset) {
          throw new ResponseError(409, 'This account needs a password reset before it can sign in.');
        }
        if (!check.ok) throw new ResponseError(401, 'Email or password is incorrect.');
        if (check.needsRehash) {
          const upgraded = await hashPassword(password);
          await sql`
            update users
            set password_salt = ${upgraded.salt}, password_hash = ${upgraded.hash}
            where id = ${rows[0].id}
          `;
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

      if (request.method === 'POST' && path === '/analyze-session') {
        await requireUser(request, sql);
        return analyzeSession(request, env);
      }

      if (request.method === 'POST' && path === '/search') {
        const userId = await requireUser(request, sql);
        return await handleSearch(request, sql, userId, env.OPENAI_API_KEY);
      }

      if (request.method === 'POST' && path === '/reindex') {
        const userId = await requireUser(request, sql);
        return await handleReindex(sql, userId, env.OPENAI_API_KEY);
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
        const items = resources
          .map((item) => ({ id: String(item?.id ?? ''), data: item }))
          .filter((item) => item.id);
        const indexable = items.filter((item) => item.data && typeof item.data === 'object');
        const existing =
          indexable.length > 0
            ? await loadExistingIndex(
                sql,
                userId,
                indexable.map((item) => item.id),
              )
            : null;
        const plans = new Map<string, IndexPlan>();
        for (const item of indexable) {
          if (existing) {
            plans.set(item.id, planIndex(item.data as Record<string, any>, existing.get(item.id)));
          }
        }
        await fillEmbeddings([...plans.values()], env.OPENAI_API_KEY);
        for (const item of items) {
          await writeIndexedResource(sql, userId, item.id, item.data, plans.get(item.id) ?? null);
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
        const existing = await loadExistingIndex(sql, userId, [id]);
        const plan = existing ? planIndex(data as Record<string, any>, existing.get(id)) : null;
        if (plan) await fillEmbeddings([plan], env.OPENAI_API_KEY);
        await writeIndexedResource(sql, userId, id, data, plan);
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
