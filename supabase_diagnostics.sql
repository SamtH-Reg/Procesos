-- ══════════════════════════════════════════════════════════════════
-- FRIOSUR · Diagnóstico en Supabase SQL Editor
-- Ejecuta por BLOQUES (secciones) y revisa resultados / NOTICE.
-- El SQL Editor corre como superusuario: ve TODAS las filas aunque RLS
-- bloquee al cliente (anon). Si aquí ves datos pero el admin no guarda,
-- el problema casi seguro es RLS + clave anon.
-- ══════════════════════════════════════════════════════════════════


-- ─── 1) ¿Existen las tablas que usa admin.html / index.html? ─────
select table_schema, table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in (
    'presets','trabajadores','turnos','equipos','roles',
    'moldes','pesajes','armado_linea','armado_lineas','user_profiles'
  )
order by table_name;
-- Si falta alguna, ejecuta primero supabase_schema.sql (y migraciones).


-- ─── 2) Conteo de filas (rápido estado de la nube) ─────────────────
select 'presets' as tbl, count(*)::bigint as rows from public.presets
union all select 'trabajadores', count(*) from public.trabajadores
union all select 'turnos', count(*) from public.turnos
union all select 'equipos', count(*) from public.equipos
union all select 'roles', count(*) from public.roles
union all select 'moldes', count(*) from public.moldes
union all select 'pesajes', count(*) from public.pesajes;
-- Si existe armado_lineas (index.html) o armado_linea (schema antiguo), ejecuta aparte:
-- select count(*) from public.armado_lineas;
-- select count(*) from public.armado_linea;


-- ─── 3) Últimos presets ────────────────────────────────────────────
select id, nombre, tipo, formato, destino, especie, calibre, kg_ref, horas_tunel, horas_placa, temp_obj, activo
from public.presets
order by id desc
limit 25;


-- ─── 4) RLS activado y políticas (clave si el admin “no guarda”) ─
select c.relname as table_name,
       c.relrowsecurity as rls_enabled,
       c.relforcerowsecurity as rls_forced
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind = 'r'
  and c.relname in (
    'presets','trabajadores','turnos','equipos','roles',
    'moldes','pesajes','armado_linea','armado_lineas','user_profiles'
  )
order by 1;

select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'public'
  and tablename in (
    'presets','trabajadores','turnos','equipos','roles',
    'moldes','pesajes','armado_linea','armado_lineas','user_profiles'
  )
order by tablename, policyname;
/*
  admin.html usa la clave ANON sin sesión JWT → rol "anon".
  supabase_auth.sql típico usa:
    presets_read  → auth.role() = 'authenticated'
    presets_write → is_admin()
  Eso BLOQUEA anon: el navegador no puede SELECT ni UPSERT.

  Comprueba en Table Editor → presets → si con “anon” no ves filas,
  confirma el diagnóstico.
*/


-- ─── 5) Publicación Realtime (tablet escucha cambios) ─────────────
select pubname, schemaname, tablename
from pg_publication_tables
where pubname = 'supabase_realtime'
  and schemaname = 'public'
order by tablename;


-- ─── 6) Prueba UPSERT (como superusuario; ignora RLS) ─────────────
-- Cambia el id si choca con uno existente, o usa on conflict.
insert into public.presets (
  id, nombre, tipo, formato, destino, especie, calibre,
  kg_ref, horas_tunel, horas_placa, temp_obj, activo
) values (
  999999001,
  'TEST SQL Editor',
  'molde',
  'BLOQUE',
  'TEST',
  'TEST',
  'S/C',
  1.0, 1.0, 1.0, -18, true
)
on conflict (id) do update set
  nombre = excluded.nombre,
  kg_ref = excluded.kg_ref;

select * from public.presets where id = 999999001;

-- Opcional: quitar la fila de prueba
-- delete from public.presets where id = 999999001;


-- ══════════════════════════════════════════════════════════════════
-- 7) OPCIONAL — Arreglo RLS para admin con clave ANON
-- Ver archivo en el repo: supabase_rls_allow_anon_admin.sql
-- (policies para rol anon en presets, catálogos, moldes, pesajes, armado_lineas)
-- ══════════════════════════════════════════════════════════════════


-- ══════════════════════════════════════════════════════════════════
-- 8) Simular acceso como rol anon (respeta RLS) — muy útil ─────────
-- Si falla "permission denied for schema public", ignora este bloque
-- y revisa policies en el Dashboard.
-- ══════════════════════════════════════════════════════════════════
begin;
set local role anon;
select count(*) as presets_visibles_anon from public.presets;
rollback;
-- Si aquí da 0 filas pero el bloque 2 mostró filas → RLS bloquea al cliente anon
-- (típico con supabase_auth.sql: solo "authenticated").


-- ─── 9) Perfiles y admins (si usas Auth en tablet) ─────────────────
select id, email, rol, activo from public.user_profiles order by created_at desc limit 20;


-- ─── 10) CHECKLIST: nombre tabla pesajes vs pasajes + columnas presets ─
-- La app (admin/index) llama SIEMPRE a public.pesajes (con E).
select case
  when exists (select 1 from information_schema.tables t where t.table_schema='public' and t.table_name='pesajes')
    then 'OK: existe public.pesajes'
  else 'FALTA: public.pesajes — el push/pull de pesajes fallará'
end as check_pesajes,
case
  when exists (select 1 from information_schema.tables t where t.table_schema='public' and t.table_name='pasajes')
    then 'AVISO: existe public.pasajes (nombre distinto a la app; renombra o crea vista pesajes)'
  else 'OK: no hay tabla pasajes (evita confusión)'
end as check_pasajes_typo;

-- Columnas que admin.html envía al upsert de presets (deben existir o PostgREST rechaza):
select string_agg(column_name, ', ' order by ordinal_position) as columnas_actuales
from information_schema.columns
where table_schema='public' and table_name='presets';

-- Comparación explícita (faltantes respecto al código):
with expected(c) as (
  values ('id'),('nombre'),('tipo'),('formato'),('destino'),('especie'),('calibre'),
         ('kg_ref'),('horas_tunel'),('horas_placa'),('temp_obj'),('activo')
),
have as (
  select column_name as c from information_schema.columns
  where table_schema='public' and table_name='presets'
)
select e.c as columna_faltante_en_presets
from expected e left join have h on h.c = e.c
where h.c is null;
-- Si el SELECT anterior devuelve filas, añade columnas (ejemplo; ajusta tipos):
/*
alter table public.presets add column if not exists especie text;
alter table public.presets add column if not exists calibre text;
alter table public.presets add column if not exists kg_ref numeric;
alter table public.presets add column if not exists horas_tunel numeric;
alter table public.presets add column if not exists horas_placa numeric;
alter table public.presets add column if not exists temp_obj numeric;
alter table public.presets add column if not exists activo boolean default true;
alter table public.presets add column if not exists created_at timestamptz default now();
alter table public.presets add column if not exists updated_at timestamptz default now();
*/

-- Si en el dashboard la tabla se llama pasajes: la app espera pesajes.
--   alter table public.pasajes rename to pesajes;
-- (Comprueba FKs/triggers antes de renombrar en producción.)
