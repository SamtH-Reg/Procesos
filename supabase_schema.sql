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
  permisos   jsonb not null default '{}'::jsonb,  -- {modulo: {read:bool, write:bool}}
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


https://etiltewnmupnifedhyld.supabase.co/rest/v1/

eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0aWx0ZXdubXVwbmlmZWRoeWxkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5OTU0NzAsImV4cCI6MjA5MjU3MTQ3MH0.Ur2c_S7kJomTKn39cnUcGQ4bu_-I7fq9hgvVTB5dMKQ


