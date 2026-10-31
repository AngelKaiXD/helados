-- Extensiones para punto de venta, vencimientos y fotos de producto.
-- Ejecutar una sola vez en Supabase SQL Editor después de schema.sql.
alter table public.products add column if not exists expires_at date;

create table if not exists public.sales (
 id uuid primary key default gen_random_uuid(),
 payment_method text not null check (payment_method in ('efectivo','qr')),
 total numeric(12,2) not null check (total >= 0),
 created_at timestamptz not null default now()
);
create table if not exists public.sale_items (
 id uuid primary key default gen_random_uuid(),
 sale_id uuid not null references public.sales(id) on delete cascade,
 product_id uuid not null references public.products(id),
 product_name text not null,
 flavor_id uuid not null references public.product_flavors(id),
 flavor_name text not null,
 quantity integer not null check (quantity > 0),
 unit_price numeric(12,2) not null check (unit_price >= 0)
);
create index if not exists sales_created_at_idx on public.sales(created_at desc);
create index if not exists sale_items_sale_id_idx on public.sale_items(sale_id);
alter table public.sales enable row level security;
alter table public.sale_items enable row level security;
drop policy if exists anon_sales_select on public.sales;
drop policy if exists anon_sales_insert on public.sales;
drop policy if exists anon_sale_items_select on public.sale_items;
drop policy if exists anon_sale_items_insert on public.sale_items;
create policy anon_sales_select on public.sales for select to anon, authenticated using (true);
create policy anon_sales_insert on public.sales for insert to anon, authenticated with check (true);
create policy anon_sale_items_select on public.sale_items for select to anon, authenticated using (true);
create policy anon_sale_items_insert on public.sale_items for insert to anon, authenticated with check (true);
grant select,insert on public.sales,public.sale_items to anon,authenticated;

create or replace function public.register_sale(p_payment_method text, p_items jsonb)
returns uuid language plpgsql security definer set search_path=public as $$
declare
 sale_id uuid := gen_random_uuid();
 line jsonb;
 f public.product_flavors;
 p public.products;
 before_stock integer;
 qty integer;
 sale_total numeric(12,2) := 0;
begin
 if p_payment_method not in ('efectivo','qr') then raise exception 'Método de pago no válido'; end if;
 if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then raise exception 'La venta no tiene productos'; end if;
 insert into public.sales(id,payment_method,total) values(sale_id,p_payment_method,0);
 for line in select value from jsonb_array_elements(p_items) loop
  qty := (line->>'quantity')::integer;
  if qty < 1 then raise exception 'La cantidad debe ser positiva'; end if;
  select * into f from public.product_flavors where id=(line->>'flavor_id')::uuid for update;
  if not found then raise exception 'Sabor no encontrado'; end if;
  select * into p from public.products where id=f.product_id and active=true;
  if not found then raise exception 'Producto no disponible'; end if;
  if p.expires_at is not null and p.expires_at < current_date then raise exception 'Producto vencido: %',p.name; end if;
  if f.stock < qty then raise exception 'Stock insuficiente para % · %',p.name,f.name; end if;
  before_stock := f.stock;
  update public.product_flavors set stock=stock-qty where id=f.id;
  insert into public.sale_items(sale_id,product_id,product_name,flavor_id,flavor_name,quantity,unit_price)
    values(sale_id,p.id,p.name,f.id,f.name,qty,p.price);
  insert into public.stock_movements(product_id,flavor_id,type,quantity,stock_before,stock_after,note)
    values(p.id,f.id,'salida',qty,before_stock,before_stock-qty,'Venta '||sale_id::text);
  sale_total := sale_total + p.price * qty;
 end loop;
 update public.sales set total=sale_total where id=sale_id;
 return sale_id;
end; $$;
grant execute on function public.register_sale(text,jsonb) to anon,authenticated;

-- Bucket público para mostrar imágenes. El acceso de escritura anónimo es temporal
-- y debe cambiarse por políticas ligadas al rol admin cuando se active autenticación.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('product-images','product-images',true,3145728,array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set public=true,file_size_limit=3145728,allowed_mime_types=array['image/jpeg','image/png','image/webp'];
drop policy if exists product_images_public_read on storage.objects;
drop policy if exists product_images_anon_upload on storage.objects;
drop policy if exists product_images_anon_update on storage.objects;
create policy product_images_public_read on storage.objects for select to anon,authenticated using (bucket_id='product-images');
create policy product_images_anon_upload on storage.objects for insert to anon,authenticated with check (bucket_id='product-images');
create policy product_images_anon_update on storage.objects for update to anon,authenticated using (bucket_id='product-images') with check (bucket_id='product-images');
