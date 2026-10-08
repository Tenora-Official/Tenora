-- TENORA: lets the cart accept the built-in gift boxes too (run in Supabase -> SQL Editor -> New query -> Run). Safe to run again.
-- Run setup-orders.sql and setup-cart.sql first.
create or replace function place_order(p_name text, p_phone text, p_address text, p_pay text, p_items jsonb)
returns bigint language plpgsql security definer set search_path = public as $$
declare it jsonb; pr record; cr record; tot numeric := 0; res jsonb := '[]'::jsonb; q int; n bigint;
begin
  if coalesce(trim(p_name),'') = '' or coalesce(trim(p_phone),'') = '' then raise exception 'Name and phone are required'; end if;
  if p_pay not in ('cod','bank') then raise exception 'Invalid payment method'; end if;
  for it in select * from jsonb_array_elements(p_items) loop
    q := greatest(1, least(50, coalesce((it->>'qty')::int, 1)));
    if coalesce(it->>'collection','') <> '' then
      select id, slug, title, price into cr from collections where slug = it->>'collection' and active;
      if not found then continue; end if;
      tot := tot + coalesce(cr.price,0) * q;
      res := res || jsonb_build_object('collection', cr.slug, 'name', cr.title || ' (gift box)', 'qty', q, 'price', coalesce(cr.price,0), 'size', left(coalesce(it->>'size',''),30), 'color', left(coalesce(it->>'color',''),30), 'for', left(coalesce(it->>'for',''),20));
    elsif coalesce(it->>'custom','') <> '' then
      -- built-in gift box (not in the database yet): price is confirmed on WhatsApp
      res := res || jsonb_build_object('name', left(it->>'custom',120), 'qty', q, 'price', 0, 'size', left(coalesce(it->>'size',''),30), 'color', left(coalesce(it->>'color',''),30), 'for', left(coalesce(it->>'for',''),20));
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
