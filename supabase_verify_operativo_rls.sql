-- ══════════════════════════════════════════════════════════════════
-- FRIOSUR · Verificación RLS / escritura operativa (moldes, pesajes, …)
-- Ejecuta en Supabase → SQL Editor (como postgres). Solo lectura de catálogo.
-- Objetivo: confirmar que roles tablet (planillero, supervisor, admin)
-- pueden SELECT + UPSERT + DELETE según las políticas vigentes.
-- Orden recomendado en proyecto: supabase_schema.sql → supabase_auth.sql
-- → supabase_rls_armado_lineas_policies.sql (si usáis armado_lineas).
-- ══════════════════════════════════════════════════════════════════


-- ─── 1) RLS activado en tablas operativas ─────────────────────────
select c.relname as table_name,
       c.relrowsecurity as rls_enabled,
       c.relforcerowsecurity as rls_forced
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind = 'r'
  and c.relname in (
    'moldes', 'pesajes', 'generales', 'armado_lineas', 'armado_linea', 'app_kv'
  )
order by 1;


-- ─── 2) Políticas actuales (cmd = ALL incluye DELETE en Postgres) ─
select tablename,
       policyname,
       coalesce(roles::text, '(default)') as policy_roles,
       cmd,
       left(coalesce(qual::text, ''), 120) as using_preview,
       left(coalesce(with_check::text, ''), 120) as with_check_preview
from pg_policies
where schemaname = 'public'
  and tablename in ('moldes', 'pesajes', 'generales', 'armado_lineas', 'armado_linea', 'app_kv')
order by tablename, policyname;
/*
  Esperado con supabase_auth.sql (operativo):
    moldes_read  → SELECT para authenticated
    moldes_write → ALL con using/check = can_write()
  Igual para pesajes_* y generales_*.

  Si aparecen políticas dev_rls_* con qual true, es modo permisivo de desarrollo
  (no bloquea); la tablet con anon podría escribir — revisad antes de producción.
*/


-- ─── 3) Definición de can_write() (debe incluir planillero) ───────
select p.proname as function_name,
       pg_get_functiondef(p.oid) as definition
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in ('can_write', 'current_rol', 'is_admin')
order by 1;
-- En can_write(), la lista de roles debe incluir al menos: admin, supervisor, planillero.


-- ─── 4) Rol en user_profiles para un email (sustituir email) ──────
-- Descomenta y ajusta el email para verificar un usuario concreto:
/*
select id, email, rol, activo
from public.user_profiles
where lower(trim(email)) = lower(trim('planillero@friosur.cl'));
*/


-- ─── 5) Conteo rápido operativo (estado de datos) ─────────────────
select 'moldes' as tbl, count(*)::bigint as rows from public.moldes
union all select 'pesajes', count(*) from public.pesajes
union all select 'generales', count(*) from public.generales;
-- Si existe la tabla (index.html / migraciones recientes):
-- select 'armado_lineas' as tbl, count(*)::bigint as rows from public.armado_lineas;
