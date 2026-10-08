-- TENORA: orders + dashboard (run ONCE in Supabase -> SQL Editor -> New query -> Run)
create table if not exists orders(
  id uuid primary key default gen_random_uuid(),
  order_no bigint generated always as identity,
  customer_name text not null,
  phone text,
  pay_method text not null default 'cod' check (pay_method in ('cod','bank')),
  paid boolean not null default false,
  status text not null default 'new' check (status in ('new','confirmed','packed','delivered','cancelled')),
  items jsonb not null default '[]',
  total numeric not null default 0,
  created_at timestamptz default now());
alter table orders enable row level security;
drop policy if exists "admin all orders" on orders;
create policy "admin all orders" on orders for all to authenticated using (true) with check (true);

-- keeps older/partial orders tables working
alter table orders add column if not exists order_no bigint generated always as identity;
alter table orders add column if not exists customer_name text;
alter table orders add column if not exists phone text;
alter table orders add column if not exists address text;
alter table orders add column if not exists pay_method text not null default 'cod';
alter table orders add column if not exists paid boolean not null default false;
alter table orders add column if not exists status text not null default 'new';
alter table orders add column if not exists items jsonb not null default '[]'::jsonb;
alter table orders add column if not exists total numeric not null default 0;
alter table orders add column if not exists created_at timestamptz default now();
notify pgrst, 'reload schema';
