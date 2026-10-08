-- TENORA: repair the orders table (run in Supabase -> SQL Editor -> New query -> Run). Safe to run again.
-- Use this when you see: column "pay_method" of relation "orders" does not exist
create table if not exists orders(id uuid primary key default gen_random_uuid());
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
alter table orders enable row level security;
drop policy if exists "admin all orders" on orders;
create policy "admin all orders" on orders for all to authenticated using (true) with check (true);
-- older orders tables can have extra required columns (e.g. payment_method); make them optional
do $$ declare c record; begin
  for c in select column_name from information_schema.columns
    where table_schema='public' and table_name='orders' and is_nullable='NO' and is_identity='NO' and column_default is null
      and column_name not in ('id','order_no') loop
    execute format('alter table public.orders alter column %I drop not null', c.column_name);
  end loop;
end $$;
notify pgrst, 'reload schema';
