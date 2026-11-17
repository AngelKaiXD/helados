-- Ejecutar una vez en Supabase SQL Editor.
-- Permite borrar productos y sabores del catálogo conservando los renglones
-- históricos de venta (product_name/flavor_name guardan una copia del nombre).
alter table public.sale_items alter column product_id drop not null;
alter table public.sale_items alter column flavor_id drop not null;

alter table public.sale_items drop constraint if exists sale_items_product_id_fkey;
alter table public.sale_items drop constraint if exists sale_items_flavor_id_fkey;

alter table public.sale_items
 add constraint sale_items_product_id_fkey
 foreign key(product_id) references public.products(id) on delete set null;
alter table public.sale_items
 add constraint sale_items_flavor_id_fkey
 foreign key(flavor_id) references public.product_flavors(id) on delete set null;
