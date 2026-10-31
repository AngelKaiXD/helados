-- Habilita la caja pública y consultas de reportes sin credenciales.
-- Las operaciones de administrador siguen requiriendo Supabase Auth y admin_access.sql.
-- Ejecuta después de admin_access.sql.
drop policy if exists public_movements_read on public.stock_movements;
drop policy if exists public_sales_read on public.sales;
drop policy if exists public_sale_items_read on public.sale_items;
create policy public_movements_read on public.stock_movements for select to anon,authenticated using(true);
create policy public_sales_read on public.sales for select to anon,authenticated using(true);
create policy public_sale_items_read on public.sale_items for select to anon,authenticated using(true);
grant select on public.stock_movements,public.sales,public.sale_items to anon;

create or replace function public.register_sale(p_payment_method text,p_items jsonb)
returns uuid language plpgsql security definer set search_path=public as $$
declare sale_id uuid:=gen_random_uuid(); line jsonb; f public.product_flavors; p public.products; before_stock integer; qty integer; sale_total numeric(12,2):=0;
begin
 if auth.uid() is not null and not public.staff_has_role(auth.uid(),array['admin','cashier']) then raise exception 'Esta cuenta no tiene permiso para registrar ventas'; end if;
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
grant execute on function public.register_sale(text,jsonb) to anon,authenticated;
