-- ═══════════════════════════════════════════════════════════════════════════
-- can_write() · permitir operario y tunelero como roles de escritura
-- ═══════════════════════════════════════════════════════════════════════════
-- Síntoma corregido:
--   La tablet logueada como operario@friosur.cl (o cualquier rol distinto de
--   admin/supervisor/planillero) recibía al insertar en moldes/pesajes/generales:
--     "new row violates row-level security policy for table 'generales'"
--   Esto bloqueaba TODOS los reintentos y el badge "Por subir" quedaba pegado.
--
-- Causa raíz:
--   Las políticas RLS de moldes / pesajes / generales / armado_lineas usan
--   can_write() en sus cláusulas USING/WITH CHECK. La función original solo
--   autorizaba admin, supervisor y planillero — operario y tunelero se
--   quedaban fuera aunque son roles legítimos para operar la tablet.
--
-- Fix:
--   Re-crear can_write() incluyendo 'operario' y 'tunelero' en el whitelist.
--   Cambio idempotente — se puede ejecutar varias veces.
-- ═══════════════════════════════════════════════════════════════════════════

create or replace function public.can_write()
  returns boolean
  language sql
  stable
  security definer
  set search_path to 'public'
as $function$
  select coalesce(
    lower(trim((select rol from public.user_profiles where id = auth.uid())))
    in ('admin', 'supervisor', 'planillero', 'operario', 'tunelero'),
    false
  );
$function$;

comment on function public.can_write() is
  'TRUE si el usuario actual tiene rol que permite escribir en tablas operativas: admin, supervisor, planillero, operario, tunelero.';

-- ─── Verificación opcional ────────────────────────────────────────────────
-- select pg_get_functiondef(p.oid) from pg_proc p
-- join pg_namespace n on n.oid=p.pronamespace
-- where n.nspname='public' and p.proname='can_write';
