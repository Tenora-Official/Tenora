-- TENORA: outfit items with fabric / colour / size choices (run ONCE in Supabase -> SQL Editor -> New query -> Run). Safe to run again.
-- Run AFTER setup-collections.sql, setup-orders.sql and setup-cart.sql.
-- Then in admin.html -> Gift collections -> "Items & photos": tick "This item is an outfit" on an item,
-- choose its sizes, give each fabric its own price, and untick "Available" when a fabric is out of stock.
-- Gift cards / accessories stay unticked: no choices, they just come in the box.

alter table collection_items add column if not exists outfit boolean not null default false;
alter table collection_items add column if not exists size_type text not null default 'baby';
alter table collection_items add column if not exists fabrics jsonb not null default '[]'::jsonb;

create or replace function place_order(p_name text, p_phone text, p_address text, p_pay text, p_items jsonb)
returns bigint language plpgsql security definer set search_path = public as $$
declare it jsonb; sl jsonb; fb jsonb; pr record; cr record; ci record; tot numeric := 0; res jsonb := '[]'::jsonb; q int; n bigint; fp numeric; det text;
begin
  if coalesce(trim(p_name),'') = '' or coalesce(trim(p_phone),'') = '' then raise exception 'Name and phone are required'; end if;
  if p_pay not in ('cod','bank') then raise exception 'Invalid payment method'; end if;
  for it in select * from jsonb_array_elements(p_items) loop
    q := greatest(1, least(50, coalesce((it->>'qty')::int, 1)));
    if coalesce(it->>'collection','') <> '' then
      select id, slug, title, price into cr from collections where slug = it->>'collection' and active;
      if not found then continue; end if;
      -- gift box base price + the price of each chosen fabric (always re-checked here on the server)
      fp := coalesce(cr.price, 0); det := '';
      if jsonb_typeof(it->'sel') = 'array' then
        for sl in select * from jsonb_array_elements(it->'sel') loop
          select * into ci from collection_items where collection_id = cr.id and name = sl->>'item' limit 1;
          if not found or not ci.outfit then continue; end if;
          fb := null;
          if coalesce(sl->>'fabric','') <> '' and jsonb_typeof(ci.fabrics) = 'array' then
            select f into fb from jsonb_array_elements(ci.fabrics) f where f->>'name' = sl->>'fabric' limit 1;
          end if;
          if fb is not null then
            if coalesce((fb->>'available')::boolean, true) = false then
              raise exception '% (%) is not available right now', ci.name, sl->>'fabric';
            end if;
            fp := fp + coalesce((fb->>'price')::numeric, 0);
          end if;
          det := det || case when det <> '' then '; ' else '' end || left(ci.name,40) || ': ' ||
                 concat_ws(', ', nullif(left(sl->>'fabric',30),''), nullif(left(sl->>'color',30),''), nullif(left(sl->>'size',30),''));
        end loop;
      end if;
      tot := tot + fp * q;
      res := res || jsonb_build_object('collection', cr.slug, 'name', cr.title || ' (gift box)', 'qty', q, 'price', fp, 'detail', left(det,600), 'size', left(coalesce(it->>'size',''),30), 'color', left(coalesce(it->>'color',''),30), 'for', left(coalesce(it->>'for',''),20));
    else
      select id, name, price into pr from products where id = (it->>'product_id')::uuid and active;
      if not found then continue; end if;
      tot := tot + coalesce(pr.price,0) * q;
      res := res || jsonb_build_object('product_id', pr.id, 'name', pr.name, 'qty', q, 'price', coalesce(pr.price,0), 'size', left(coalesce(it->>'size',''),30), 'color', left(coalesce(it->>'color',''),30));
    end if;
  end loop;
  if jsonb_array_length(res) = 0 then raise exception 'Cart is empty'; end if;
  insert into orders(customer_name, phone, address, pay_method, items, total)
  values (left(trim(p_name),100), left(trim(p_phone),30), left(coalesce(p_address,''),300), p_pay, res, tot) returning order_no into n;
  return n;
end $$;
grant execute on function place_order(text,text,text,text,jsonb) to anon, authenticated;
notify pgrst, 'reload schema';
