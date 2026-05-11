-- ══════════════════════════════════════════════════════════════════
-- FRIOSUR SpA · Control de Producción
-- Schema Supabase (PostgreSQL)
-- ──────────────────────────────────────────────────────────────────
-- Ejecutar en SQL Editor de Supabase antes de sincronizar.
-- Las operaciones admin.html → pushAll() usan upsert por PK.
-- ══════════════════════════════════════════════════════════════════

-- ─── Extensiones ──────────────────────────────────────────────────
create extension if not exists "pgcrypto";

-- ═══════════════ CATÁLOGOS (menús desplegables) ══════════════════

create table if not exists presets(
  id           bigint primary key,
  nombre       text not null,
  tipo         text,
  formato      text,
  destino      text,
  especie      text,
  calibre      text,
  kg_ref       numeric,
  horas_tunel  numeric,
  horas_placa  numeric,
  temp_obj     numeric,
  activo       boolean default true,
  created_at   timestamptz default now(),
  updated_at   timestamptz default now()
);

create table if not exists trabajadores(
  id         bigint primary key,
  codigo     text,
  nombre     text not null,
  ficha      text,
  area       text,        -- 'moldes' | 'pesaje' | 'tuneles' | 'placas' | ...
  rol        text,        -- 'operario' | 'planillero' | 'supervisor' | ...
  turno      text,        -- 'dia' | 'noche'
  linea      text,        -- 'L1' | 'L2' | 'L3' | null
  activo     boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists turnos(
  codigo     text primary key,   -- 'dia' | 'noche' | ...
  nombre     text,
  inicio     time,
  fin        time,
  activo     boolean default true,
  updated_at timestamptz default now()
);

create table if not exists equipos(
  codigo     text primary key,   -- 'T1', 'P1', ...
  nombre     text,
  tipo       text,               -- 'tunel' | 'placa' | ...
  capacidad  int,
  activo     boolean default true,
  updated_at timestamptz default now()
);

create table if not exists roles(
  id         bigint primary key,
  nombre     text not null,
  codigo     text,  -- identificador estable (user_profiles.rol, trabajadores.rol); ej. admin, planillero, tunelero
  permisos   jsonb not null default '{}'::jsonb,  -- flags tablet + admin (moldes, tuneles, dashboard, …)
  updated_at timestamptz default now()
);

-- ═══════════════ OPERACIÓN (registros de planilla) ═══════════════

create table if not exists moldes(
  id         bigint primary key,
  hora       text,
  turno      text,
  linea      text,
  codigo     text,
  nombre     text,
  ficha      text,
  producto   text,
  preset_id  bigint references presets(id) on delete set null,
  destino    text,
  calibre    text,
  especie    text,
  cant       int,
  pendiente  int,
  kg         numeric,
  guia       text,
  fecha      date default current_date,
  created_at timestamptz default now()
);

create table if not exists pesajes(
  id         bigint primary key,
  hora       text,
  turno      text,
  linea      text,
  trab_id    bigint references trabajadores(id) on delete set null,
  codigo     text,
  nombre     text,
  ficha      text,
  especie    text,
  tipo       text,
  kg         numeric,
  guia       text,
  fecha      date default current_date,
  created_at timestamptz default now()
);

-- Registro general (pallet / carro / castillo) — sin operario; sync vía REST desde index/admin.
-- No añadir a publication supabase_realtime si quieres ahorrar cuota de mensajes Realtime.
create table if not exists generales(
  id         bigint primary key,
  hora       text,
  turno      text,
  linea      text,
  producto   text,
  preset_id  bigint references presets(id) on delete set null,
  destino    text,
  calibre    text,
  especie    text,
  tipo       text,
  cant       int,
  pendiente  int,
  kg         numeric,
  guia       text,
  fecha      date default current_date,
  created_at timestamptz default now()
);

-- Armado de línea (planillero + trabajadores por turno/línea/área)
create table if not exists armado_linea(
  area         text  not null,   -- 'moldes' | 'pesaje'
  linea        text  not null,   -- 'L1' | 'L2' | 'L3'
  turno        text  not null,   -- 'dia' | 'noche'
  planillero   jsonb,            -- {trabId, nombre, ficha?}
  trabajadores jsonb,            -- [{trabId, nombre, ficha?}, ...]
  producto     text,
  fecha        date default current_date,
  updated_at   timestamptz default now(),
  primary key(area, linea, fecha, turno)
);

-- ═══════════════ ÍNDICES ═════════════════════════════════════════

create index if not exists idx_moldes_fecha       on moldes(fecha);
create index if not exists idx_moldes_linea_turno on moldes(linea, turno);
create index if not exists idx_moldes_especie     on moldes(especie);
create index if not exists idx_pesajes_fecha      on pesajes(fecha);
create index if not exists idx_pesajes_linea_turno on pesajes(linea, turno);
create index if not exists idx_pesajes_trab       on pesajes(trab_id);
create index if not exists idx_pesajes_especie    on pesajes(especie);
create index if not exists idx_generales_fecha    on generales(fecha);
create index if not exists idx_generales_linea_turno on generales(linea, turno);
create index if not exists idx_trab_area          on trabajadores(area);
create index if not exists idx_trab_turno_linea   on trabajadores(turno, linea);

-- ═══════════════ TRIGGER updated_at ══════════════════════════════

create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$
declare t text;
begin
  for t in
    select unnest(array['presets','trabajadores','turnos','equipos','roles','armado_linea'])
  loop
    execute format(
      'drop trigger if exists trg_%1$s_updated on %1$s;
       create trigger trg_%1$s_updated before update on %1$s
       for each row execute function set_updated_at();', t);
  end loop;
end $$;

-- ═══════════════ ROW LEVEL SECURITY (opcional) ═══════════════════
-- Descomenta cuando tengas Auth habilitada.
--
-- alter table presets        enable row level security;
-- alter table trabajadores   enable row level security;
-- alter table turnos         enable row level security;
-- alter table equipos        enable row level security;
-- alter table roles          enable row level security;
-- alter table moldes         enable row level security;
-- alter table pesajes        enable row level security;
-- alter table armado_linea   enable row level security;
--
-- -- Lectura pública (ajusta según necesidad):
-- create policy "read_all_presets"      on presets      for select using (true);
-- create policy "read_all_trabajadores" on trabajadores for select using (true);
-- create policy "read_all_turnos"       on turnos       for select using (true);
-- create policy "read_all_equipos"      on equipos      for select using (true);
-- create policy "read_all_roles"        on roles        for select using (true);
-- create policy "read_all_moldes"       on moldes       for select using (true);
-- create policy "read_all_pesajes"      on pesajes      for select using (true);
-- create policy "read_all_armado"       on armado_linea for select using (true);
--
-- -- Escritura solo usuarios autenticados:
-- create policy "auth_write_presets"      on presets      for all using (auth.role()='authenticated');
-- create policy "auth_write_trabajadores" on trabajadores for all using (auth.role()='authenticated');
-- create policy "auth_write_turnos"       on turnos       for all using (auth.role()='authenticated');
-- create policy "auth_write_equipos"      on equipos      for all using (auth.role()='authenticated');
-- create policy "auth_write_roles"        on roles        for all using (auth.role()='authenticated');
-- create policy "auth_write_moldes"       on moldes       for all using (auth.role()='authenticated');
-- create policy "auth_write_pesajes"      on pesajes      for all using (auth.role()='authenticated');
-- create policy "auth_write_armado"       on armado_linea for all using (auth.role()='authenticated');

-- ═══════════════ SEED MÍNIMO (opcional) ══════════════════════════
-- insert into turnos(codigo,nombre,inicio,fin) values
--   ('dia',   'Día',   '08:00', '20:00'),
--   ('noche', 'Noche', '20:00', '08:00')
-- on conflict (codigo) do nothing;
--
-- insert into roles(id,nombre,permisos) values
--   (1,'admin',       '{"all":{"read":true,"write":true}}'),
--   (2,'supervisor',  '{"moldes":{"read":true,"write":true},"pesaje":{"read":true,"write":true}}'),
--   (3,'planillero',  '{"moldes":{"read":true,"write":true},"pesaje":{"read":true,"write":true}}'),
--   (4,'operario',    '{"moldes":{"read":true,"write":false},"pesaje":{"read":true,"write":false}}')
-- on conflict (id) do nothing;

-- ═══════════════ CONFIG COMPARTIDA (dashboard admin, etc.) ═══════

create table if not exists app_kv(
  key        text primary key,
  value      jsonb not null default '{}'::jsonb,
  updated_at timestamptz default now()
);

drop trigger if exists trg_app_kv_updated on app_kv;
create trigger trg_app_kv_updated before update on app_kv
  for each row execute function set_updated_at();

-- RLS app_kv (evita 403 en upsert desde admin autenticado). Idempotente.
alter table app_kv enable row level security;
drop policy if exists "app_kv_select_authenticated" on app_kv;
drop policy if exists "app_kv_insert_authenticated" on app_kv;
drop policy if exists "app_kv_update_authenticated" on app_kv;
drop policy if exists "app_kv_delete_authenticated" on app_kv;
drop policy if exists "app_kv_read" on app_kv;
drop policy if exists "app_kv_write" on app_kv;
drop policy if exists "app_kv_update" on app_kv;
create policy "app_kv_select_authenticated" on app_kv for select to authenticated using (true);
create policy "app_kv_insert_authenticated" on app_kv for insert to authenticated with check (true);
create policy "app_kv_update_authenticated" on app_kv for update to authenticated using (true) with check (true);

-- RLS `roles`: la tablet (index) lee esta tabla tras login; sin sesión JWT no hay SELECT.
-- Ver también `supabase_migrate_roles_rls.sql` (misma lógica, idempotente).
alter table if exists public.roles enable row level security;
drop policy if exists "roles_select_authenticated" on public.roles;
drop policy if exists "roles_insert_authenticated" on public.roles;
drop policy if exists "roles_update_authenticated" on public.roles;
drop policy if exists "roles_delete_authenticated" on public.roles;
create policy "roles_select_authenticated" on public.roles for select to authenticated using (true);
create policy "roles_insert_authenticated" on public.roles for insert to authenticated with check (true);
create policy "roles_update_authenticated" on public.roles for update to authenticated using (true) with check (true);
create policy "roles_delete_authenticated" on public.roles for delete to authenticated using (true);

-- ═══════════════ REALTIME (index.html escucha cambios del admin) ══
-- En Dashboard → Database → Publications → supabase_realtime, añadir tablas,
-- o ejecutar (idempotente si ya están):
--   alter publication supabase_realtime add table presets;
--   alter publication supabase_realtime add table trabajadores;
--   alter publication supabase_realtime add table turnos;
--   alter publication supabase_realtime add table equipos;
--   alter publication supabase_realtime add table roles;
-- Sin esto, la tablet sigue actualizando al volver a la pestaña (pull cada ~15s)
-- y al abrir la app; el push en vivo requiere Realtime + RLS que permita SELECT al rol que use el cliente.
