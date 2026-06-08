-- ═══════════════════════════════════════════════════════════════════════════
-- Soltar FK preset_id en moldes y generales (resiliencia local-first)
-- ═══════════════════════════════════════════════════════════════════════════
-- Aplicado en producción 2026-06-08 vía MCP. Archivo histórico/idempotente.
--
-- CAUSA RAÍZ del bug 'Por subir' pegado:
--   moldes.preset_id y generales.preset_id tenían FK a presets(id). Si una tablet
--   sube una fila operativa que referencia un preset creado/editado en otra tablet
--   o en admin que aún NO sincronizó a la nube, el upsert del BATCH COMPLETO falla
--   con violación de foreign key. moldes/generales quedaban atrapados localmente.
--
--   pesajes.trab_id NO sufría esto porque trabajadores es un catálogo estable
--   sincronizado desde UCO (sus ids siempre existen en la nube). Por eso los
--   pesajes SÍ subían y moldes/generales NO — patrón diagnóstico clave.
--
-- DECISIÓN: en un sistema local-first donde data operativa y catálogo de presets
-- sincronizan de forma independiente, preset_id es una referencia BLANDA. Cada
-- fila ya denormaliza producto/especie/calibre/destino, así que el FK no aporta
-- integridad útil y sí fragilidad. La UI ya tolera preset_id null / preset faltante.
-- ═══════════════════════════════════════════════════════════════════════════

alter table public.moldes drop constraint if exists moldes_preset_id_fkey;
alter table public.generales drop constraint if exists generales_preset_id_fkey;

comment on column public.moldes.preset_id is
  'Referencia BLANDA a presets.id (sin FK). Lookup de conveniencia; la fila ya denormaliza producto/especie/calibre/destino.';
comment on column public.generales.preset_id is
  'Referencia BLANDA a presets.id (sin FK). Lookup de conveniencia; la fila ya denormaliza producto/especie/calibre/destino.';

-- Verificación: no deben quedar FK preset_id
-- select conname from pg_constraint
-- where conname in ('moldes_preset_id_fkey','generales_preset_id_fkey');  -- → 0 filas
