# Cloud sync setup

Resource Memory is local-first: Hive remains the fast offline cache on each device. Cross-device sync uses a Cloudflare Worker API, Neon Postgres for canonical resource data, Cloudflare R2 for uploaded files, and optional OpenAI understanding behind the Worker for screenshots and voice notes.

## Architecture

```text
Flutter web / desktop / mobile
        |
        v
Cloudflare Worker API
   |         |          |
   v         v          v
Neon       R2         OpenAI
metadata   files      image + voice understanding
```

The Flutter client never receives the Neon database connection string or OpenAI API key.

## 1. Create Neon

Create a Neon project and copy its Postgres connection string.

Run `worker/schema.sql` against the Neon database. It creates:

- `users`
- `sessions`
- `resources`

Then run `worker/migrations/002_memory_search.sql` against the same database. It enables the
`pgvector` extension and adds the semantic-search columns (`search_text`, `source_type`,
`resource_type`, `event_at`, `event_confidence`, `embedding_model`, `embedding`) plus the
full-text and vector indexes the `/search` endpoint needs.

## 2. Create the R2 bucket

Create an R2 bucket named:

```text
resource-memory-files
```

`worker/wrangler.jsonc` already declares it as the `RESOURCE_FILES` binding.

## 3. Configure and deploy the Worker

From the `worker` directory:

```bash
npm install
npx wrangler secret put DATABASE_URL
npx wrangler secret put OPENAI_API_KEY
npm run deploy
```

Enter the Neon connection string for `DATABASE_URL` and your OpenAI API key for `OPENAI_API_KEY`.

`OPENAI_API_KEY` is optional for basic local saving and sync. Without it, screenshots and voice notes still save, but Resource Memory cannot automatically understand screenshots or transcribe and organize voice notes.

The Worker exposes:

```text
POST   /auth/register
POST   /auth/login
POST   /auth/logout
POST   /analyze-image
POST   /analyze-audio
POST   /analyze-session
GET    /resources
PUT    /resources/:id
DELETE /resources/:id
POST   /sync
POST   /search
POST   /reindex
POST   /uploads/:resourceId
GET    /assets/:resourceId
GET    /health
```

`POST /analyze-image` is authenticated. It sends the screenshot to OpenAI through the Worker and returns structured resource metadata: title, visible URL when present, creator, platform, summary, why-useful, use-when, topics, technologies, and resource type.

`POST /analyze-audio` is authenticated. It transcribes the audio with OpenAI speech-to-text, then turns the transcript into the same retrieval-oriented metadata. The original audio file is stored separately in R2 when sync is connected, while the transcript and metadata are stored with the Resource in Neon.

## Semantic search

Every `PUT /resources/:id` and `POST /sync` write builds a `search_text` field from the resource
(title, creator, platform, summary, why-useful, use-when, transcript, topics, technologies, URL,
and tab-session contents). When `OPENAI_API_KEY` is configured, the Worker also generates a
`text-embedding-3-small` vector for new or changed resources. Embeddings are only regenerated
when the searchable text changes, and `/sync` batches them into a single OpenAI call.

`POST /search` (body: `{ "query": "...", "limit": 10, "types": ["session"] }`) returns hybrid
results: full-text rank plus vector similarity, reranked with a light recency boost. Each result
includes the resource, a 0-1 score, a highlighted snippet, the matched terms, and a plain-language
`why` list explaining the match. Without an OpenAI key it falls back to full-text search and
reports `"semantic": false`.

`POST /reindex` backfills `search_text` and embeddings for existing rows (100 per call; repeat
until `pendingSearchText` and `pendingEmbeddings` are both 0). Run it once after applying
migration 002 to make previously saved resources searchable.

If migration 002 has not been applied, writes keep working in their original shape and `/search`
falls back to simple keyword matching, so deploying the Worker before running the migration does
not break existing clients.

Passwords are derived with PBKDF2-SHA256 in the Worker. Session tokens are hashed before being stored in Neon.

Password hashing uses Workers' native `node:crypto` PBKDF2-SHA256. Original bare-hex
hashes still verify with their original 120,000 iterations, so existing users keep their
passwords. New hashes record the count as `pbkdf2-sha256$120000$<hex>`. The 100,000-iteration
format written by the reset script is also accepted and upgraded after successful login.
Malformed records return a reset message instead of crashing authentication.

### Update an existing Worker

Run these from your local repository root (the folder containing `worker`):

```bash
git pull --ff-only origin main
git log -1 --oneline
cd worker
npm ci
npm test
npx wrangler login
npm run deploy
npm run check:health
```

Sign into the Cloudflare account that owns `resource-memory-api` when Wrangler opens the
browser. A normal update preserves its existing Worker secrets and R2 binding; you do not
need to reset your password or recreate the database.

`check:health` checks the current deployment at
`https://resource-memory-api.madincrease.workers.dev`. For another deployment, use
`npm run check:health -- https://YOUR-WORKER.workers.dev`.
It fails if the Worker is still serving old code or real password hashing fails.

### Deploy automatically from GitHub

`.github/workflows/deploy-worker.yml` tests and deploys the Worker on `main` changes under
`worker/`. It also has a manual **Run workflow** button. The Pages workflow deploys only
the Flutter front end; it does not update the Worker.

Add these repository Actions secrets once:

- `CLOUDFLARE_API_TOKEN`: a Cloudflare **Edit Cloudflare Workers** API token scoped to the
  account that owns the existing Worker and R2 bucket.
- `CLOUDFLARE_ACCOUNT_ID`: that account's ID from the Cloudflare dashboard.

Keep `DATABASE_URL` and `OPENAI_API_KEY` as Cloudflare Worker secrets. Do not put their
values in the repository. If the deploy workflow reports missing credentials, add the two
Actions secrets and rerun it, or use the local deployment commands above.

The reset SQL script is only a recovery option for malformed password records:

```bash
node worker/scripts/reset-password-sql.mjs you@example.com 'new password'
```

Paste the printed `update` statement into the Neon SQL editor. Normal legacy accounts do
not need this step.

## 4. Connect the Flutter deployment

After deploying the Worker, copy its public URL.

In GitHub repository Settings → Secrets and variables → Actions, add:

```text
RESOURCE_API_URL=https://resource-memory-api.YOUR-SUBDOMAIN.workers.dev
```

The GitHub Pages workflow passes this value to Flutter with `--dart-define`.

For local/native Flutter builds:

```bash
flutter run \
  --dart-define=RESOURCE_API_URL=https://resource-memory-api.YOUR-SUBDOMAIN.workers.dev
```

## Sync, image, and voice behavior

- Hive remains the local/offline copy.
- A Resource Memory email/password account can be used on desktop, web, Android, and iOS.
- Saving or deleting while signed in mirrors resource metadata through the Worker into Neon.
- `Sync now` uploads the local library and pulls the canonical library back down.
- Dropped, uploaded, and pasted screenshots can be analyzed before saving when the user is signed in and `OPENAI_API_KEY` is configured.
- The image analysis can extract a visible website/domain and make it the Resource link rather than treating the screenshot itself as the only resource.
- Voice Memory can record directly from the microphone or import an existing voice memo.
- Voice notes are limited to five minutes for direct recording in the current UI.
- Voice notes are transcribed, summarized, tagged with topics/technologies, and given a `useWhen` retrieval trigger.
- Spoken URLs can become clickable Resource links when they are confidently present in the transcript.
- Android accepts shared `audio/*` files into Resource Memory. iOS Share Extension file support can pass voice memo files once the native Share Extension target is configured.
- Screenshot, file, and voice-note bytes upload to R2 when sync is connected.
- Each synced file Resource stores an `assetPath` that points to its authenticated R2 endpoint.
- The Worker can return the original bytes through `GET /assets/:resourceId` on another signed-in device.
- The Neon credential and OpenAI API key stay only in Cloudflare Worker secrets.

## Health check

Open:

```text
https://YOUR-WORKER.workers.dev/health
```

A configured deployment returns an object containing:

```json
{
  "ok": true,
  "service": "resource-memory-api",
  "imageIntelligenceConfigured": true,
  "voiceIntelligenceConfigured": true,
  "semanticSearchConfigured": true,
  "passwordCryptoOk": true,
  "build": "password-compat-v2"
}
```
