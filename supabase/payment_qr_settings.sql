-- Permite que el admin cambie el QR de cobro sin desplegar de nuevo la aplicación.
-- Ejecutar después de admin_access.sql.
create table if not exists public.app_settings (
 key text primary key,
 value text not null,
 updated_at timestamptz not null default now()
);
alter table public.app_settings enable row level security;
drop policy if exists public_read_payment_qr on public.app_settings;
drop policy if exists admin_manage_app_settings on public.app_settings;
create policy public_read_payment_qr on public.app_settings for select to anon,authenticated using(key='payment_qr_image_url');
create policy admin_manage_app_settings on public.app_settings for all to authenticated using(public.staff_has_role(auth.uid(),array['admin'])) with check(public.staff_has_role(auth.uid(),array['admin']));
revoke all on public.app_settings from anon;
grant select on public.app_settings to anon,authenticated;
grant insert,update,delete on public.app_settings to authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('payment-assets','payment-assets',true,3145728,array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set public=true,file_size_limit=3145728,allowed_mime_types=array['image/jpeg','image/png','image/webp'];
drop policy if exists payment_assets_public_read on storage.objects;
drop policy if exists payment_assets_admin_manage on storage.objects;
create policy payment_assets_public_read on storage.objects for select to anon,authenticated using(bucket_id='payment-assets');
create policy payment_assets_admin_manage on storage.objects for all to authenticated using(bucket_id='payment-assets' and public.staff_has_role(auth.uid(),array['admin'])) with check(bucket_id='payment-assets' and public.staff_has_role(auth.uid(),array['admin']));
