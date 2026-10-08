-- TENORA: customer reviews (run ONCE in Supabase -> SQL Editor -> New query -> Run)
-- Visitors can submit reviews (saved as NOT approved). Only approved ones show on the site.
-- To approve: Supabase -> Table Editor -> reviews -> tick "approved" on the row.

create table if not exists reviews(
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 60),
  rating int not null check (rating between 1 and 5),
  comment text not null check (char_length(comment) between 1 and 500),
  approved boolean not null default false,
  created_at timestamptz default now());

alter table reviews enable row level security;

drop policy if exists "public read approved reviews" on reviews;
drop policy if exists "public submit review" on reviews;

create policy "public read approved reviews" on reviews for select using (approved = true);
create policy "public submit review" on reviews for insert with check (approved = false);
