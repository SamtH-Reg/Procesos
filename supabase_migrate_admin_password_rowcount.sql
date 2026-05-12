-- ══════════════════════════════════════════════════════════════════
-- FRIOSUR · rpc_admin_set_user_password: comprobar filas con ROW_COUNT
-- Reemplaza `IF NOT FOUND` tras UPDATE (poco claro en algunas versiones).
-- Ejecutar en SQL Editor (o apply_migration) si «Cambiar contraseña» falla
-- con «Usuario no encontrado» aunque el usuario exista.
-- ══════════════════════════════════════════════════════════════════

create or replace function public.rpc_admin_set_user_password(
  p_user_id uuid,
  p_password text
) returns void
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
declare
  n int;
begin
  if not public.is_admin() then
    raise exception 'forbidden';
  end if;
  if p_password is null or length(trim(p_password)) < 6 then
    raise exception 'La contraseña debe tener al menos 6 caracteres';
  end if;
  update auth.users
  set encrypted_password = extensions.crypt(trim(p_password), extensions.gen_salt('bf'::text)),
      updated_at = now()
  where id = p_user_id;
  get diagnostics n = row_count;
  if n = 0 then
    raise exception 'Usuario no encontrado';
  end if;
end;
$$;

grant execute on function public.rpc_admin_set_user_password(uuid, text) to authenticated;
