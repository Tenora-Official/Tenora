-- TENORA: editable gift collections (run ONCE in Supabase -> SQL Editor -> New query -> Run)
-- After this, open admin.html -> "Gift collections" to change titles, add items, upload photos, and mark items for Girl / Boy.

create table if not exists collections(
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  title text not null,
  subtitle text,
  description text,
  image_url text,
  active boolean default true,
  sort_order int default 0,
  created_at timestamptz default now());

create table if not exists collection_items(
  id uuid primary key default gen_random_uuid(),
  collection_id uuid not null references collections(id) on delete cascade,
  name text not null,
  detail text,
  image_url text,
  gender text not null default 'any' check (gender in ('any','girl','boy')),
  sort_order int default 0,
  created_at timestamptz default now());

alter table collections enable row level security;
alter table collection_items enable row level security;

drop policy if exists "public read collections" on collections;
drop policy if exists "public read collection items" on collection_items;
drop policy if exists "admin all collections" on collections;
drop policy if exists "admin all collection items" on collection_items;
create policy "public read collections" on collections for select using (active = true);
create policy "public read collection items" on collection_items for select using (true);
create policy "admin all collections" on collections for all to authenticated using (true) with check (true);
create policy "admin all collection items" on collection_items for all to authenticated using (true) with check (true);

-- Starter content (same as what the site shows today). Safe to re-run.

insert into collections(slug,title,subtitle,description,sort_order) values('newborn','For a newborn','First arrivals','A gentle first wardrobe idea for the earliest days, with soft pieces that are easy to wear and easy to gift.',1) on conflict (slug) do nothing;
insert into collection_items(collection_id,name,detail,gender,sort_order) select c.id,'Soft bodysuit','Everyday essential','any',1 from collections c where c.slug='newborn' and not exists (select 1 from collection_items i where i.collection_id=c.id and i.name='Soft bodysuit');
insert into collection_items(collection_id,name,detail,gender,sort_order) select c.id,'Easy romper','Comfort first','any',2 from collections c where c.slug='newborn' and not exists (select 1 from collection_items i where i.collection_id=c.id and i.name='Easy romper');
insert into collection_items(collection_id,name,detail,gender,sort_order) select c.id,'Welcome card','Gift-ready detail','any',3 from collections c where c.slug='newborn' and not exists (select 1 from collection_items i where i.collection_id=c.id and i.name='Welcome card');
insert into collections(slug,title,subtitle,description,sort_order) values('birthday','First birthday','One candle','A simple first-birthday edit built around comfort and celebration.',2) on conflict (slug) do nothing;
insert into collection_items(collection_id,name,detail,gender,sort_order) select c.id,'Birthday outfit','Special day','any',1 from collections c where c.slug='birthday' and not exists (select 1 from collection_items i where i.collection_id=c.id and i.name='Birthday outfit');
insert into collection_items(collection_id,name,detail,gender,sort_order) select c.id,'Soft accessory','Little detail','any',2 from collections c where c.slug='birthday' and not exists (select 1 from collection_items i where i.collection_id=c.id and i.name='Soft accessory');
insert into collection_items(collection_id,name,detail,gender,sort_order) select c.id,'Message card','For the moment','any',3 from collections c where c.slug='birthday' and not exists (select 1 from collection_items i where i.collection_id=c.id and i.name='Message card');
insert into collections(slug,title,subtitle,description,sort_order) values('shower','Baby shower','Before they arrive','A ready-to-give shower collection for welcoming the little one.',3) on conflict (slug) do nothing;
insert into collection_items(collection_id,name,detail,gender,sort_order) select c.id,'Newborn set','Starter pieces','any',1 from collections c where c.slug='shower' and not exists (select 1 from collection_items i where i.collection_id=c.id and i.name='Newborn set');
insert into collection_items(collection_id,name,detail,gender,sort_order) select c.id,'Gift box','Ready to give','any',2 from collections c where c.slug='shower' and not exists (select 1 from collection_items i where i.collection_id=c.id and i.name='Gift box');
insert into collection_items(collection_id,name,detail,gender,sort_order) select c.id,'Welcome note','Thoughtful detail','any',3 from collections c where c.slug='shower' and not exists (select 1 from collection_items i where i.collection_id=c.id and i.name='Welcome note');
insert into collections(slug,title,subtitle,description,sort_order) values('christmas','First Christmas','Season''s warmest','A warm little first-Christmas edit for a new family memory.',4) on conflict (slug) do nothing;
insert into collection_items(collection_id,name,detail,gender,sort_order) select c.id,'Festive outfit','Seasonal piece','any',1 from collections c where c.slug='christmas' and not exists (select 1 from collection_items i where i.collection_id=c.id and i.name='Festive outfit');
insert into collection_items(collection_id,name,detail,gender,sort_order) select c.id,'Soft accessory','Cozy detail','any',2 from collections c where c.slug='christmas' and not exists (select 1 from collection_items i where i.collection_id=c.id and i.name='Soft accessory');
insert into collection_items(collection_id,name,detail,gender,sort_order) select c.id,'Keepsake card','First Christmas','any',3 from collections c where c.slug='christmas' and not exists (select 1 from collection_items i where i.collection_id=c.id and i.name='Keepsake card');
insert into collections(slug,title,subtitle,description,sort_order) values('mother-baby','Mother & baby','Matching sets','A matching-set idea that brings mother and baby together.',5) on conflict (slug) do nothing;
insert into collection_items(collection_id,name,detail,gender,sort_order) select c.id,'Baby piece','Soft essential','any',1 from collections c where c.slug='mother-baby' and not exists (select 1 from collection_items i where i.collection_id=c.id and i.name='Baby piece');
insert into collection_items(collection_id,name,detail,gender,sort_order) select c.id,'Mother piece','Matching detail','any',2 from collections c where c.slug='mother-baby' and not exists (select 1 from collection_items i where i.collection_id=c.id and i.name='Mother piece');
insert into collection_items(collection_id,name,detail,gender,sort_order) select c.id,'Gift card','A shared moment','any',3 from collections c where c.slug='mother-baby' and not exists (select 1 from collection_items i where i.collection_id=c.id and i.name='Gift card');
insert into collections(slug,title,subtitle,description,sort_order) values('new-dad','New Dad','Welcome to it','A small welcome-to-dad gift idea made for a brand-new chapter.',6) on conflict (slug) do nothing;
insert into collection_items(collection_id,name,detail,gender,sort_order) select c.id,'Dad piece','Everyday wear','any',1 from collections c where c.slug='new-dad' and not exists (select 1 from collection_items i where i.collection_id=c.id and i.name='Dad piece');
insert into collection_items(collection_id,name,detail,gender,sort_order) select c.id,'Baby note','Little memory','any',2 from collections c where c.slug='new-dad' and not exists (select 1 from collection_items i where i.collection_id=c.id and i.name='Baby note');
insert into collection_items(collection_id,name,detail,gender,sort_order) select c.id,'Gift card','Personal touch','any',3 from collections c where c.slug='new-dad' and not exists (select 1 from collection_items i where i.collection_id=c.id and i.name='Gift card');
