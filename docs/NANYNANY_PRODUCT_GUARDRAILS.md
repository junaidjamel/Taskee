# NanyNany product guardrails

## Promise

**You do not have to remember to remember.**

NanyNany is a resource-memory layer, not a second-brain dashboard or general task manager. It should accept useful information with minimal friction, understand enough context to store it intelligently, and bring it back when it becomes useful.

## Core loop

**Capture → Understand → Remember → Resurface → Act**

Every feature must improve at least one step in this loop without making another step harder.

## Keep central

1. Native/share-sheet capture of links, selected text, screenshots, photos, files, and audio.
2. Voice-memory import from the device's existing recording tools; do not require users to learn a proprietary recorder.
3. Automatic lightweight enrichment and classification.
4. Natural-language retrieval across saved resources.
5. Email/calendar/message-derived commitment detection where platform permissions and APIs permit it.
6. Contextual resurfacing of previously saved resources.
7. Audible/persistent reminders for confirmed time-sensitive commitments.
8. Local-first behavior with cloud sync when configured.

## Do not turn NanyNany into

- a project-management suite
- a traditional to-do application
- a folder-management system
- an analytics dashboard
- a gamified habit product
- an AI-chat product whose main value is conversation
- an integration directory with dozens of bespoke screens

Integrations should feed one normalized capture pipeline instead.

## Integration principle

Prefer operating-system and platform pathways over rebuilding mature capabilities:

- iOS/iPadOS: Share Extension, Photos/Files share sheet, Voice Memos sharing, Siri/App Intents where available, local notifications.
- Android: Android Sharesheet / ACTION_SEND and ACTION_SEND_MULTIPLE, system file/photo pickers, Recorder sharing, notification APIs.
- Web: browser share targets where supported plus a lightweight browser extension/bookmark capture pathway.
- External services: use supported OAuth, APIs, webhooks, forwarding/share actions, or user-authorized connectors. Never rely on covert interception of another app's private messages or notifications.

All pathways normalize into the same `MemoryCapture` contract.

## MemoryCapture contract

Each capture should preserve, when available:

- original content or file reference
- canonical URL
- source application/service
- captured text/transcript
- title
- captured timestamp
- event/deadline candidates and timezone evidence
- people/entities/topics
- location evidence when explicitly present in the resource
- user note/context
- provenance and extraction confidence

NanyNany may suggest a commitment automatically, but should distinguish an inferred date from a confirmed commitment.

## Retrieval model

Use hybrid retrieval rather than folders as the primary organizing mechanism:

1. lexical/full-text search for exact names, dates, URLs, and phrases
2. vector similarity for semantic recall
3. structured filters for source, time, resource type, entities, and confirmed commitments
4. lightweight reranking using recency, relevance, explicit user context, and commitment proximity

For the existing Neon/Postgres backend, `pgvector` is the preferred first vector store so resource data and embeddings stay together.

## Cognitive design rules

- Recognition beats recall: show likely relevant memories rather than requiring exact search terms.
- Prospective-memory support matters: a saved item with a future consequence should be eligible to resurface before that consequence.
- Reduce decision count during capture: saving should normally be one action; categorization happens afterward.
- Preserve context: source, sender/service, date, surrounding text, and user annotations are retrieval cues.
- Reminders must be actionable: Done, Snooze, Open source, or Adjust — not notification spam.
- Escalation should be proportional to importance and user choice.

## V1 success test

A user should be able to share a useful item to NanyNany in seconds, forget about it, and later recover it using ordinary language or have NanyNany resurface it at an appropriate time.