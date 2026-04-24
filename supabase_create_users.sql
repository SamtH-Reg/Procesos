-- ══════════════════════════════════════════════════════════════════
-- FRIOSUR · Crear usuarios automáticamente
-- Ejecuta en SQL Editor (requiere pgcrypto, ya instalado)
-- ══════════════════════════════════════════════════════════════════

-- Habilitar pgcrypto si no está
create extension if not exists pgcrypto;

-- Función helper: crea usuario en auth.users + auth.identities + perfil
create or replace function crear_usuario_friosur(
  p_email text,
  p_password text,
  p_rol text,
  p_nombre text
) returns uuid
language plpgsql
security definer
as $$
declare
  v_uid uuid;
begin
  -- Si el email ya existe, solo actualiza el perfil
  select id into v_uid from auth.users where email = p_email;
  if v_uid is not null then
    update user_profiles set rol = p_rol, nombre = p_nombre where id = v_uid;
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
    p_email,
    crypt(p_password, gen_salt('bf')),
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

  -- Crear identidad email (requerido por Supabase Auth)
  insert into auth.identities (
    id, user_id, identity_data, provider, provider_id,
    last_sign_in_at, created_at, updated_at
  ) values (
    gen_random_uuid(),
    v_uid,
    jsonb_build_object('sub', v_uid::text, 'email', p_email, 'email_verified', true),
    'email',
    v_uid::text,
    now(), now(), now()
  );

  -- Actualizar perfil con rol correcto (el trigger ya lo creó con rol='operario')
  update user_profiles set rol = p_rol, nombre = p_nombre where id = v_uid;

  return v_uid;
end;
$$;

-- ─── CREAR LOS 4 USUARIOS ─────────────────────────────────────────
select crear_usuario_friosur('admin@friosur.cl',      'Admin2026!',  'admin',      'Administrador');
select crear_usuario_friosur('supervisor@friosur.cl', 'Super2026!',  'supervisor', 'Supervisor');
select crear_usuario_friosur('planillero@friosur.cl', 'Planil2026!', 'planillero', 'Planillero');
select crear_usuario_friosur('operario@friosur.cl',   'Oper2026!',   'operario',   'Operario');

-- ─── VERIFICACIÓN ─────────────────────────────────────────────────
select u.email, p.rol, p.nombre, u.email_confirmed_at is not null as confirmado
from auth.users u
left join user_profiles p on p.id = u.id
where u.email like '%@friosur.cl'
order by p.rol;

-- ─── Eliminar la función helper (opcional, por seguridad) ─────────
-- drop function crear_usuario_friosur(text,text,text,text);
