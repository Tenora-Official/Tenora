-- TENORA: orders + gift box prices (run ONCE in Supabase -> SQL Editor)
alter table collections add column if not exists price numeric;

create table if not exists orders(
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  customer_name text not null,
  phone text not null,
  address text,
  payment_method text not null check (payment_method in ('cod','bank')),
  items jsonb not null,
  total numeric,
  status text default 'new',
  notes text);

alter table orders enable row level security;
drop policy if exists "anyone place order" on orders;
drop policy if exists "admin read orders" on orders;
drop policy if exists "admin update orders" on orders;
create policy "anyone place order" on orders for insert to anon, authenticated with check (true);
create policy "admin read orders" on orders for select to authenticated using (true);
create policy "admin update orders" on orders for update to authenticated using (true) with check (true);
