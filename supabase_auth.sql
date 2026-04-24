-- ══════════════════════════════════════════════════════════════════
-- FRIOSUR · AUTH + RLS
-- Ejecuta DESPUÉS de supabase_schema.sql en el SQL Editor
-- ══════════════════════════════════════════════════════════════════

-- ─── Tabla de perfiles vinculada a auth.users ─────────────────────
create table if not exists user_profiles(
  id         uuid primary key references auth.users(id) on delete cascade,
  email      text unique,
  rol        text not null default 'operario',  -- admin | supervisor | planillero | operario
  nombre     text,
  area       text,        -- 'moldes' | 'pesaje' | 'tuneles' | ...
  activo     boolean default true,
  created_at timestamptz default now()
);

-- Trigger: al crearse un usuario en auth.users, crea perfil operario
create or replace function handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into user_profiles(id, email, rol)
  values (new.id, new.email, 'operario')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ─── Helper: obtener rol del usuario actual ────────────────────────
create or replace function current_rol()
returns text language sql stable security definer as $$
  select rol from user_profiles where id = auth.uid();
$$;

create or replace function is_admin()
returns boolean language sql stable security definer as $$
  select coalesce((select rol from user_profiles where id = auth.uid()) in ('admin'), false);
$$;

create or replace function can_write()
returns boolean language sql stable security definer as $$
  select coalesce((select rol from user_profiles where id = auth.uid()) in ('admin','supervisor','planillero'), false);
$$;

-- ═══════════════ ACTIVAR RLS ═══════════════════════════════════════
alter table presets        enable row level security;
alter table trabajadores   enable row level security;
alter table turnos         enable row level security;
alter table equipos        enable row level security;
alter table roles          enable row level security;
alter table moldes         enable row level security;
alter table pesajes        enable row level security;
alter table armado_linea   enable row level security;
alter table user_profiles  enable row level security;

-- ─── POLICIES ──────────────────────────────────────────────────────
-- Lectura: cualquier usuario autenticado
-- Escritura catálogos: solo admin
-- Escritura moldes/pesajes/armado: admin + supervisor + planillero

-- Limpiar policies anteriores si existen
do $$ declare p record;
begin
  for p in select policyname, tablename from pg_policies
           where schemaname='public' and tablename in
           ('presets','trabajadores','turnos','equipos','roles','moldes','pesajes','armado_linea','user_profiles')
  loop execute format('drop policy if exists %I on public.%I', p.policyname, p.tablename);
  end loop;
end $$;

-- user_profiles: cada uno ve su propio perfil; admin ve todos
create policy up_self_read   on user_profiles for select using (auth.uid() = id or is_admin());
create policy up_admin_write on user_profiles for all    using (is_admin()) with check (is_admin());

-- CATÁLOGOS (lectura todos autenticados, escritura solo admin)
create policy presets_read      on presets      for select using (auth.role()='authenticated');
create policy presets_write     on presets      for all    using (is_admin())  with check (is_admin());

create policy trab_read         on trabajadores for select using (auth.role()='authenticated');
create policy trab_write        on trabajadores for all    using (is_admin())  with check (is_admin());

create policy turnos_read       on turnos       for select using (auth.role()='authenticated');
create policy turnos_write      on turnos       for all    using (is_admin())  with check (is_admin());

create policy equipos_read      on equipos      for select using (auth.role()='authenticated');
create policy equipos_write     on equipos      for all    using (is_admin())  with check (is_admin());

create policy roles_read        on roles        for select using (auth.role()='authenticated');
create policy roles_write       on roles        for all    using (is_admin())  with check (is_admin());

-- OPERACIONAL (lectura todos, escritura planillero+supervisor+admin)
create policy moldes_read       on moldes       for select using (auth.role()='authenticated');
create policy moldes_write      on moldes       for all    using (can_write()) with check (can_write());

create policy pesajes_read      on pesajes      for select using (auth.role()='authenticated');
create policy pesajes_write     on pesajes      for all    using (can_write()) with check (can_write());

create policy armado_read       on armado_linea for select using (auth.role()='authenticated');
create policy armado_write      on armado_linea for all    using (can_write()) with check (can_write());

-- ─── Crear usuario admin inicial (opcional) ───────────────────────
-- Después de crear el primer usuario vía Dashboard → Authentication → Users,
-- ejecuta esto cambiando el email por el tuyo:
--
-- update user_profiles set rol='admin'      where email='admin@friosur.cl';
-- update user_profiles set rol='supervisor' where email='supervisor@friosur.cl';
-- update user_profiles set rol='planillero' where email='planillero@friosur.cl';
