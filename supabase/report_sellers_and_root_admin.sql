-- Ejecutar una vez en Supabase SQL Editor en proyectos ya configurados.
-- Las ventas anónimas se identifican como vendedor_panda; las autenticadas
-- guardan el nombre y UUID del perfil de personal que realizó el cobro.
alter table public.sales add column if not exists seller_name text not null default 'vendedor_panda';
alter table public.sales add column if not exists seller_user_id uuid references auth.users(id) on delete set null;

create or replace function public.register_sale(p_payment_method text,p_items jsonb)
returns uuid language plpgsql security definer set search_path=public as $$
declare
 sale_id uuid:=gen_random_uuid(); line jsonb; f public.product_flavors; p public.products;
 before_stock integer; qty integer; sale_total numeric(12,2):=0;
 v_seller_name text:='vendedor_panda'; v_seller_user_id uuid:=auth.uid();
begin
 if auth.uid() is not null then
  if not public.staff_has_role(auth.uid(),array['admin','cashier']) then
   raise exception 'Esta cuenta no tiene permiso para registrar ventas';
  end if;
  select coalesce(nullif(display_name,''), (select email from auth.users where id=auth.uid()), 'Personal')
    into v_seller_name from public.staff_profiles where user_id=auth.uid();
  if v_seller_name is null then raise exception 'El usuario no tiene un perfil de personal'; end if;
 end if;
 if p_payment_method not in ('efectivo','qr') then raise exception 'Método de pago no válido'; end if;
 if jsonb_typeof(p_items)<>'array' or jsonb_array_length(p_items)=0 then raise exception 'La venta no tiene productos'; end if;
 insert into public.sales(id,payment_method,total,seller_name,seller_user_id)
 values(sale_id,p_payment_method,0,v_seller_name,v_seller_user_id);
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
  insert into public.sale_items(sale_id,product_id,product_name,flavor_id,flavor_name,quantity,unit_price)
   values(sale_id,p.id,p.name,f.id,f.name,qty,p.price);
  insert into public.stock_movements(product_id,flavor_id,type,quantity,stock_before,stock_after,note)
   values(p.id,f.id,'salida',qty,before_stock,before_stock-qty,'Venta '||sale_id::text);
  sale_total:=sale_total+p.price*qty;
 end loop;
 update public.sales set total=sale_total where id=sale_id;
 return sale_id;
end; $$;
grant execute on function public.register_sale(text,jsonb) to anon,authenticated;

-- Solo el endpoint de servidor con la clave secreta puede administrar perfiles.
-- La cuenta principal heladosdepanda@gmail.com opera ese endpoint; otros admins
-- conservan su acceso administrativo funcional, pero no pueden gestionar usuarios.
drop policy if exists staff_admin_write on public.staff_profiles;
