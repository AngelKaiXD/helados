-- Agencia Helados Panda Ballivián · PostgreSQL / Supabase
create extension if not exists pgcrypto;
create table if not exists public.products (
 id uuid primary key default gen_random_uuid(), name text not null, description text not null default '',
 category text not null, price numeric(12,2) not null default 0 check(price>=0), unit text not null default 'unidad',
 min_stock integer not null default 5 check(min_stock>=0), image_url text not null default '', active boolean not null default true,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.product_flavors (
 id uuid primary key default gen_random_uuid(), product_id uuid not null references public.products(id) on delete cascade,
 name text not null, stock integer not null default 0 check(stock>=0), unique(product_id,name)
);
create table if not exists public.stock_movements (
 id uuid primary key default gen_random_uuid(), product_id uuid not null references public.products(id) on delete cascade,
 flavor_id uuid not null references public.product_flavors(id) on delete cascade,
 type text not null check(type in ('entrada','salida','ajuste','merma')),
 quantity integer not null check(quantity>=0), stock_before integer not null, stock_after integer not null check(stock_after>=0),
 note text not null default '', created_at timestamptz not null default now()
);
create index if not exists product_flavors_product_id_idx on public.product_flavors(product_id);
create index if not exists stock_movements_created_at_idx on public.stock_movements(created_at desc);
create or replace function public.set_updated_at() returns trigger language plpgsql as $$
begin new.updated_at=now(); return new; end; $$;
drop trigger if exists products_set_updated_at on public.products;
create trigger products_set_updated_at before update on public.products for each row execute function public.set_updated_at();
create or replace function public.adjust_stock(p_flavor_id uuid,p_type text,p_quantity integer,p_note text default '') returns public.stock_movements
language plpgsql security definer set search_path=public as $$
declare f public.product_flavors; before_stock integer; after_stock integer; result public.stock_movements;
begin
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
alter table public.products enable row level security;
alter table public.product_flavors enable row level security;
alter table public.stock_movements enable row level security;
-- TEMPORAL: acceso público sin autenticación para rol anon. Reemplazar por políticas con auth.uid() antes de habilitar usuarios.
do $$ declare t text; op text; begin foreach t in array array['products','product_flavors','stock_movements'] loop
 foreach op in array array['select','insert','update','delete'] loop
 execute format('drop policy if exists anon_%s_%s on public.%s',op,t,t);
 if op='select' or op='delete' then execute format('create policy anon_%s_%s on public.%s for %s to anon using (true)',op,t,t,op);
 elsif op='insert' then execute format('create policy anon_%s_%s on public.%s for insert to anon with check (true)',op,t,t);
 else execute format('create policy anon_%s_%s on public.%s for update to anon using (true) with check (true)',op,t,t); end if;
 end loop; end loop; end $$;
grant execute on function public.adjust_stock(uuid,text,integer,text) to anon, authenticated;
grant select,insert,update,delete on public.products,public.product_flavors,public.stock_movements to anon, authenticated;
