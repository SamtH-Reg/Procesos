-- ══════════════════════════════════════════════════════════════════
-- FRIOSUR · Revocar EXECUTE a anon (y handle_new_user a authenticated)
-- en helpers SECURITY DEFINER expuestos por PostgREST.
-- Corrige avisos Supabase linter 0028 / endurece search_path (0011) en can_write/current_rol.
-- Aplicar con MCP apply_migration o SQL Editor.
-- ══════════════════════════════════════════════════════════════════

-- Comparación de roles alineada con is_admin() (lower + trim).
create or replace function public.can_write()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    lower(trim((select rol from public.user_profiles where id = auth.uid())))
    in ('admin', 'supervisor', 'planillero'),
    false
  );
$$;

create or replace function public.current_rol()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select rol from public.user_profiles where id = auth.uid();
$$;

revoke execute on function public.is_admin() from anon;
revoke execute on function public.can_write() from anon;
revoke execute on function public.current_rol() from anon;
revoke execute on function public.handle_new_user() from anon;
revoke execute on function public.handle_new_user() from authenticated;

revoke execute on function public.rpc_admin_create_user(text, text, text, text) from anon;
revoke execute on function public.rpc_admin_set_user_password(uuid, text) from anon;
revoke execute on function public.rpc_admin_delete_user(uuid) from anon;
