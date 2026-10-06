-- NanyNany semantic-memory foundation.
-- Run after enabling the pgvector extension in Neon.

create extension if not exists vector;

alter table resources
  add column if not exists search_text text,
  add column if not exists source_type text,
  add column if not exists resource_type text,
  add column if not exists event_at timestamptz,
  add column if not exists event_confidence real,
  add column if not exists embedding_model text,
  add column if not exists embedding vector(1536);

create index if not exists resources_user_source_idx
  on resources(user_id, source_type);

create index if not exists resources_user_event_idx
  on resources(user_id, event_at)
  where event_at is not null;

create index if not exists resources_search_text_idx
  on resources using gin (to_tsvector('english', coalesce(search_text, '')));

-- Keep semantic search scoped to the authenticated user in application queries.
-- Add HNSW once the library is large enough to justify approximate search.
create index if not exists resources_embedding_hnsw_idx
  on resources using hnsw (embedding vector_cosine_ops)
  where embedding is not null;
