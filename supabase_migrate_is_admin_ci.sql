-- is_admin(): comparación insensible a mayúsculas/espacios en user_profiles.rol
-- Alinear con la consola admin (normalizeSesionRol).
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    lower(trim((select rol from public.user_profiles where id = auth.uid()))) = 'admin',
    false
  );
$$;
