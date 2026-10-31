-- Ejecuta después de schema.sql y observaciones_cliente.sql.
-- Protege funciones administrativas con usuarios autenticados de Supabase Auth.
create table if not exists public.staff_profiles (
 user_id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null default '',
 role text not null check(role in ('admin','cashier')),
 created_at timestamptz not null default now()
);
alter table public.staff_profiles enable row level security;
create or replace function public.staff_has_role(p_user_id uuid,p_roles text[])
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.staff_profiles where user_id=p_user_id and role=any(p_roles));
$$;
drop policy if exists staff_self_or_admin_read on public.staff_profiles;
drop policy if exists staff_admin_write on public.staff_profiles;
create policy staff_self_or_admin_read on public.staff_profiles for select to authenticated using(user_id=auth.uid() or public.staff_has_role(auth.uid(),array['admin']));
create policy staff_admin_write on public.staff_profiles for all to authenticated using(public.staff_has_role(auth.uid(),array['admin'])) with check(public.staff_has_role(auth.uid(),array['admin']));

-- Retira las políticas abiertas de prototipo y permite lecturas al cajero.
do $$ declare t text; op text; begin
 foreach t in array array['products','product_flavors','stock_movements','sales','sale_items'] loop
  foreach op in array array['select','insert','update','delete'] loop
   execute format('drop policy if exists anon_%s_%s on public.%s',op,t,t);
  end loop;
 end loop;
end $$;
drop policy if exists public_products_read on public.products;
drop policy if exists public_flavors_read on public.product_flavors;
drop policy if exists admin_products_all on public.products;
drop policy if exists admin_flavors_all on public.product_flavors;
drop policy if exists admin_movements_read on public.stock_movements;
drop policy if exists staff_sales_read on public.sales;
drop policy if exists staff_sale_items_read on public.sale_items;
create policy public_products_read on public.products for select to anon,authenticated using(active or public.staff_has_role(auth.uid(),array['admin']));
create policy public_flavors_read on public.product_flavors for select to anon,authenticated using(true);
create policy admin_products_all on public.products for all to authenticated using(public.staff_has_role(auth.uid(),array['admin'])) with check(public.staff_has_role(auth.uid(),array['admin']));
create policy admin_flavors_all on public.product_flavors for all to authenticated using(public.staff_has_role(auth.uid(),array['admin'])) with check(public.staff_has_role(auth.uid(),array['admin']));
create policy admin_movements_read on public.stock_movements for select to authenticated using(public.staff_has_role(auth.uid(),array['admin','cashier']));
create policy staff_sales_read on public.sales for select to authenticated using(public.staff_has_role(auth.uid(),array['admin','cashier']));
create policy staff_sale_items_read on public.sale_items for select to authenticated using(public.staff_has_role(auth.uid(),array['admin','cashier']));

create or replace function public.adjust_stock(p_flavor_id uuid,p_type text,p_quantity integer,p_note text default '') returns public.stock_movements
language plpgsql security definer set search_path=public as $$
declare f public.product_flavors; before_stock integer; after_stock integer; result public.stock_movements;
begin
 if not public.staff_has_role(auth.uid(),array['admin']) then raise exception 'Solo un administrador puede modificar el inventario'; end if;
 if p_type not in ('entrada','salida','ajuste','merma') then raise exception 'Tipo de movimiento inválido'; end if;
 if p_quantity<0 then raise exception 'La cantidad debe ser mayor o igual a cero'; end if;
 select * into f from public.product_flavors where id=p_flavor_id for update;
 if not found then raise exception 'Sabor no encontrado'; end if;
 before_stock:=f.stock;
 after_stock:=case when p_type='entrada' then before_stock+p_quantity when p_type='ajuste' then p_quantity else before_stock-p_quantity end;
 if after_stock<0 then raise exception 'El stock no puede quedar negativo'; end if;
 update public.product_flavors set stock=after_stock where id=p_flavor_id;
 insert into public.stock_movements(product_id,flavor_id,type,quantity,stock_before,stock_after,note)
 values(f.product_id,f.id,p_type,case when p_type='ajuste' then abs(after_stock-before_stock) else p_quantity end,before_stock,after_stock,coalesce(p_note,'')) returning * into result;
 return result;
end; $$;

create or replace function public.register_sale(p_payment_method text,p_items jsonb)
returns uuid language plpgsql security definer set search_path=public as $$
declare sale_id uuid:=gen_random_uuid(); line jsonb; f public.product_flavors; p public.products; before_stock integer; qty integer; sale_total numeric(12,2):=0;
begin
 if not public.staff_has_role(auth.uid(),array['admin','cashier']) then raise exception 'Inicia sesión como personal autorizado para registrar ventas'; end if;
 if p_payment_method not in ('efectivo','qr') then raise exception 'Método de pago no válido'; end if;
 if jsonb_typeof(p_items)<>'array' or jsonb_array_length(p_items)=0 then raise exception 'La venta no tiene productos'; end if;
 insert into public.sales(id,payment_method,total) values(sale_id,p_payment_method,0);
 for line in select value from jsonb_array_elements(p_items) loop
  qty:=(line->>'quantity')::integer;
  if qty<1 then raise exception 'La cantidad debe ser positiva'; end if;
  select * into f from public.product_flavors where id=(line->>'flavor_id')::uuid for update;
  if not found then raise exception 'Sabor no encontrado'; end if;
  select * into p from public.products where id=f.product_id and active=true;
  if not found then raise exception 'Producto no disponible'; end if;
  if p.expires_at is not null and p.expires_at<current_date then raise exception 'Producto vencido: %',p.name; end if;
  if f.stock<qty then raise exception 'Stock insuficiente para % · %',p.name,f.name; end if;
  before_stock:=f.stock;
  update public.product_flavors set stock=stock-qty where id=f.id;
  insert into public.sale_items(sale_id,product_id,product_name,flavor_id,flavor_name,quantity,unit_price) values(sale_id,p.id,p.name,f.id,f.name,qty,p.price);
  insert into public.stock_movements(product_id,flavor_id,type,quantity,stock_before,stock_after,note) values(p.id,f.id,'salida',qty,before_stock,before_stock-qty,'Venta '||sale_id::text);
  sale_total:=sale_total+p.price*qty;
 end loop;
 update public.sales set total=sale_total where id=sale_id;
 return sale_id;
end; $$;
revoke all on function public.adjust_stock(uuid,text,integer,text) from anon;
revoke all on function public.register_sale(text,jsonb) from anon;
grant execute on function public.adjust_stock(uuid,text,integer,text) to authenticated;
grant execute on function public.register_sale(text,jsonb) to authenticated;
revoke all on public.products,public.product_flavors,public.stock_movements,public.sales,public.sale_items from anon;
grant select on public.products,public.product_flavors to anon;
grant select,insert,update,delete on public.products,public.product_flavors to authenticated;
grant select on public.stock_movements,public.sales,public.sale_items to authenticated;

-- Las imágenes siguen siendo públicas para mostrarlas en caja. Solo los admins suben o cambian fotos.
drop policy if exists product_images_anon_upload on storage.objects;
drop policy if exists product_images_anon_update on storage.objects;
drop policy if exists product_images_public_read on storage.objects;
drop policy if exists product_images_admin_read on storage.objects;
drop policy if exists product_images_admin_insert on storage.objects;
drop policy if exists product_images_admin_update on storage.objects;
drop policy if exists product_images_admin_delete on storage.objects;
create policy product_images_admin_read on storage.objects for select to anon,authenticated using(bucket_id='product-images');
create policy product_images_admin_insert on storage.objects for insert to authenticated with check(bucket_id='product-images' and public.staff_has_role(auth.uid(),array['admin']));
create policy product_images_admin_update on storage.objects for update to authenticated using(bucket_id='product-images' and public.staff_has_role(auth.uid(),array['admin'])) with check(bucket_id='product-images' and public.staff_has_role(auth.uid(),array['admin']));
create policy product_images_admin_delete on storage.objects for delete to authenticated using(bucket_id='product-images' and public.staff_has_role(auth.uid(),array['admin']));

-- Después de crear el primer usuario en Authentication → Users, ejecuta una vez:
-- insert into public.staff_profiles(user_id,display_name,role) values ('UUID_DEL_USUARIO','Administrador','admin');
