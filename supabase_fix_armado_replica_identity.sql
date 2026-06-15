-- ═══════════════════════════════════════════════════════════════════════════
-- Fix REPLICA IDENTITY de armado_lineas (DELETE fallaba en Realtime)
-- ═══════════════════════════════════════════════════════════════════════════
-- Aplicado en producción 2026-06-15 vía MCP. Histórico/idempotente.
--
-- SÍNTOMA en tablet (Pesaje › Armado, al borrar/editar línea):
--   "Armado línea: cannot delete from table 'armado_lineas' because it does
--    not have a replica identity and publishes deletes"
--   → la línea se borraba localmente pero NO en la nube (podía reaparecer).
--
-- CAUSA: en la auditoría previa (supabase_audit_2026-05-24.sql) se promovió el
-- índice único a PRIMARY KEY:
--   drop index armado_lineas_linea_turno_fecha_area_uid;
--   alter table armado_lineas add constraint armado_lineas_pkey primary key (...);
-- Pero la REPLICA IDENTITY de la tabla seguía configurada como INDEX apuntando
-- al índice viejo (ya dropeado). Sin una identidad de réplica válida, la
-- publicación supabase_realtime (que replica DELETEs) rechaza los borrados.
--
-- FIX: usar REPLICA IDENTITY DEFAULT → la PRIMARY KEY (linea,turno,fecha,area),
-- igual que moldes/generales/pesajes. Todas las columnas de la PK son NOT NULL,
-- así que sirve como identidad de réplica.
-- ═══════════════════════════════════════════════════════════════════════════

alter table public.armado_lineas replica identity default;

-- Verificación:
-- select relreplident from pg_class where relname='armado_lineas';  -- → 'd' (DEFAULT)
