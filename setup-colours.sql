-- TENORA: colours with their own photos (run ONCE in Supabase -> SQL Editor -> New query -> Run)
alter table products add column if not exists variants jsonb not null default '[]'::jsonb;
