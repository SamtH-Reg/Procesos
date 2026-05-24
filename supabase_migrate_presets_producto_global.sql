-- ═══════════════════════════════════════════════════════════════════════════
-- Migración · public.presets: agregar columna producto_global
-- ═══════════════════════════════════════════════════════════════════════════
-- Permite clasificar cada preset por el "producto global" final
-- (Filete, Porción, Lomo, HG, IQF, Bloque, MC, Entero, Pulpa, etc.) para
-- agregaciones y reportes transversales por familia de producto.
--
-- Idempotente. Ejecutar una vez en Supabase → SQL Editor.
-- ═══════════════════════════════════════════════════════════════════════════

alter table public.presets
  add column if not exists producto_global text;

comment on column public.presets.producto_global is
  'Producto global / familia (Filete, Porción, Lomo, HG, IQF, Bloque, MC, Entero, Pulpa, …).';

-- Verificación opcional:
-- select producto_global, count(*) from public.presets group by producto_global order by 1;
