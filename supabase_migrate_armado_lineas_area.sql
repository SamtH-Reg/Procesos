-- ═══════════════════════════════════════════════════════════════════════════
-- armado_lineas: columna `area` (moldes | pesaje) + unicidad compuesta
-- ═══════════════════════════════════════════════════════════════════════════
-- La tablet guardaba en Supabase solo el armado de MOLDES (RT.armadoMolde).
-- El armado de PESAJE (RT.armadoPesaje) quedaba solo en localStorage → se
-- «perdía» al borrar datos del sitio o usar otro navegador.
--
-- Ejecutar en Supabase → SQL Editor (después de supabase_migrate_armado_lineas_scope.sql).
-- Luego el upsert de index.html usa onConflict: 'linea,turno,fecha,area'.

ALTER TABLE public.armado_lineas REPLICA IDENTITY FULL;

DROP INDEX IF EXISTS public.armado_lineas_linea_turno_fecha_uid;

ALTER TABLE public.armado_lineas
  ADD COLUMN IF NOT EXISTS area text NOT NULL DEFAULT 'moldes';

UPDATE public.armado_lineas SET area = lower(trim(area));
UPDATE public.armado_lineas SET area = 'moldes' WHERE area IS NULL OR area NOT IN ('moldes', 'pesaje');

CREATE UNIQUE INDEX IF NOT EXISTS armado_lineas_linea_turno_fecha_area_uid
  ON public.armado_lineas (linea, turno, fecha, area);

ALTER TABLE public.armado_lineas REPLICA IDENTITY USING INDEX armado_lineas_linea_turno_fecha_area_uid;

COMMENT ON COLUMN public.armado_lineas.area IS
  'moldes = RT.armadoMolde; pesaje = RT.armadoPesaje (index.html).';
