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
GET    /resources
PUT    /resources/:id
DELETE /resources/:id
POST   /sync
POST   /uploads/:resourceId
GET    /assets/:resourceId
GET    /health
```

`POST /analyze-image` is authenticated. It sends the screenshot to OpenAI through the Worker and returns structured resource metadata: title, visible URL when present, creator, platform, summary, why-useful, use-when, topics, technologies, and resource type.

`POST /analyze-audio` is authenticated. It transcribes the audio with OpenAI speech-to-text, then turns the transcript into the same retrieval-oriented metadata. The original audio file is stored separately in R2 when sync is connected, while the transcript and metadata are stored with the Resource in Neon.

Passwords are derived with PBKDF2 in the Worker. Session tokens are hashed before being stored in Neon.

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
  "voiceIntelligenceConfigured": true
}
```
