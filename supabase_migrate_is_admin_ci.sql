-- is_admin(): comparación insensible a mayúsculas/espacios en user_profiles.rol
-- Alinear con la consola admin (normalizeSesionRol).
--
-- IMPORTANTE (RLS): la política up_self_read usa (auth.uid() = id OR is_admin()).
-- Si is_admin() hace SELECT en user_profiles con row_security ON, Postgres puede
-- re-evaluar la misma política de forma recursiva y el cliente ve timeouts.
-- Solución: SECURITY DEFINER + SET LOCAL row_security = off solo dentro de estas funciones.
--
-- Debe ser VOLATILE: PostgreSQL no permite SET LOCAL dentro de funciones STABLE/IMMUTABLE
-- (error: «SET is not allowed in a non-volatile function»).

create or replace function public.is_admin()
returns boolean
language plpgsql
volatile
security definer
set search_path to 'public'
as $$
declare
  r text;
begin
  set local row_security = off;
  select rol into r from public.user_profiles where id = auth.uid();
  return coalesce(lower(trim(r)) = 'admin', false);
end;
$$;

create or replace function public.current_rol()
returns text
language plpgsql
volatile
security definer
set search_path to 'public'
as $$
declare
  r text;
begin
  set local row_security = off;
  select rol into r from public.user_profiles where id = auth.uid();
  return r;
end;
$$;
