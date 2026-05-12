-- ══════════════════════════════════════════════════════════════════
-- FRIOSUR · RPCs admin para usuarios (Auth) desde admin.html
-- Aplicar con Supabase MCP (apply_migration) o SQL Editor.
-- Requiere: supabase_auth.sql (user_profiles, is_admin), pgcrypto.
-- En Supabase, pgcrypto suele vivir en schema `extensions`; sin él en search_path aparece:
--   function gen_salt(unknown) does not exist
-- ══════════════════════════════════════════════════════════════════

create extension if not exists pgcrypto with schema extensions;

-- Helper interno: inserta en auth.users + identities y actualiza perfil.
-- NO conceder EXECUTE a anon/authenticated; solo lo llaman funciones admin.
create or replace function public.crear_usuario_friosur(
  p_email text,
  p_password text,
  p_rol text,
  p_nombre text
) returns uuid
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
declare
  v_uid uuid;
begin
  select id into v_uid from auth.users where lower(email) = lower(trim(p_email));
  if v_uid is not null then
    update public.user_profiles set rol = p_rol, nombre = p_nombre where id = v_uid;
    return v_uid;
  end if;

  v_uid := gen_random_uuid();

  insert into auth.users (
    instance_id, id, aud, role, email,
    encrypted_password, email_confirmed_at, invited_at,
    confirmation_token, confirmation_sent_at,
    recovery_token, recovery_sent_at,
    email_change_token_new, email_change, email_change_sent_at,
    last_sign_in_at, raw_app_meta_data, raw_user_meta_data,
    is_super_admin, created_at, updated_at, phone,
    phone_confirmed_at, phone_change, phone_change_token,
    phone_change_sent_at, email_change_token_current,
    email_change_confirm_status, banned_until, reauthentication_token,
    reauthentication_sent_at, is_sso_user, deleted_at
  ) values (
    '00000000-0000-0000-0000-000000000000',
    v_uid,
    'authenticated',
    'authenticated',
    trim(p_email),
    extensions.crypt(p_password::text, extensions.gen_salt('bf'::text)),
    now(), null,
    '', null,
    '', null,
    '', '', null,
    null,
    jsonb_build_object('provider','email','providers',jsonb_build_array('email')),
    jsonb_build_object('nombre', p_nombre, 'rol', p_rol),
    false, now(), now(), null,
    null, '', '',
    null, '',
    0, null, '',
    null, false, null
  );

  insert into auth.identities (
    id, user_id, identity_data, provider, provider_id,
    last_sign_in_at, created_at, updated_at
  ) values (
    gen_random_uuid(),
    v_uid,
    jsonb_build_object('sub', v_uid::text, 'email', trim(p_email), 'email_verified', true),
    'email',
    v_uid::text,
    now(), now(), now()
  );

  update public.user_profiles set rol = p_rol, nombre = p_nombre where id = v_uid;

  return v_uid;
end;
$$;

revoke all on function public.crear_usuario_friosur(text, text, text, text) from public;
revoke all on function public.crear_usuario_friosur(text, text, text, text) from anon, authenticated;

-- Crear usuario nuevo (rechaza correo ya registrado; usar rpc_admin_set_user_password).
create or replace function public.rpc_admin_create_user(
  p_email text,
  p_password text,
  p_rol text,
  p_nombre text
) returns uuid
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
declare
  v_email text := trim(p_email);
  v_nom text := nullif(trim(p_nombre), '');
begin
  if not public.is_admin() then
    raise exception 'forbidden';
  end if;
  if v_email is null or v_email = '' then
    raise exception 'Correo obligatorio';
  end if;
  if p_password is null or length(trim(p_password)) < 6 then
    raise exception 'La contraseña debe tener al menos 6 caracteres';
  end if;
  if exists (select 1 from auth.users where lower(email) = lower(v_email)) then
    raise exception 'El correo ya está registrado. Usá «Cambiar contraseña» o eliminá el usuario.';
  end if;
  return public.crear_usuario_friosur(
    v_email,
    trim(p_password),
    trim(p_rol),
    coalesce(v_nom, split_part(v_email, '@', 1))
  );
end;
$$;

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

create or replace function public.rpc_admin_delete_user(p_user_id uuid) returns void
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
  if p_user_id = auth.uid() then
    raise exception 'No podés eliminar tu propia cuenta';
  end if;
  delete from auth.users where id = p_user_id;
  get diagnostics n = row_count;
  if n = 0 then
    raise exception 'Usuario no encontrado';
  end if;
end;
$$;

grant execute on function public.rpc_admin_create_user(text, text, text, text) to authenticated;
grant execute on function public.rpc_admin_set_user_password(uuid, text) to authenticated;
grant execute on function public.rpc_admin_delete_user(uuid) to authenticated;
