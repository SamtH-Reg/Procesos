-- ═══════════════════════════════════════════════════════════════════════════
-- Reparación armado_lineas (Supabase SQL Editor · ejecutar en PRODUCCIÓN con cuidado)
-- ═══════════════════════════════════════════════════════════════════════════
-- Objetivos:
--   - Normalizar linea / turno / area
--   - Eliminar filas con linea inválida (no L1…L999)
--   - Eliminar duplicados (misma linea+turno+fecha+area), conservando updated_at más reciente
--
-- Requisitos: tabla public.armado_lineas; columna updated_at (ver supabase_migrate_armado_lineas_scope.sql).
-- Hacer backup o export antes si hay dudas.
-- ═══════════════════════════════════════════════════════════════════════════

BEGIN;

-- 1) Normalización superficial
UPDATE public.armado_lineas
SET linea = trim(upper(linea::text)),
    turno = lower(trim(turno::text)),
    area = CASE
      WHEN lower(trim(coalesce(area, 'moldes')::text)) = 'pesaje' THEN 'pesaje'
      ELSE 'moldes'
    END
WHERE linea IS NOT NULL;

-- 2) Turnos equivalentes comunes → dia / noche (ajusta si usas otros códigos)
UPDATE public.armado_lineas SET turno = 'dia'
WHERE lower(trim(turno::text)) IN ('día', 'day');

UPDATE public.armado_lineas SET turno = 'noche'
WHERE lower(trim(turno::text)) IN ('night');

-- 3) Borrar filas con linea inválida (evita tarjetas «Linea» sin número en la tablet)
DELETE FROM public.armado_lineas
WHERE linea IS NULL
   OR trim(linea::text) = ''
   OR trim(upper(linea::text)) !~ '^L[0-9]{1,3}$';

-- 4) Duplicados: quedarse con una fila por (linea, turno, fecha, area) — la de updated_at más reciente
WITH ranked AS (
  SELECT
    ctid,
    row_number() OVER (
      PARTITION BY
        trim(upper(linea::text)),
        lower(trim(turno::text)),
        fecha::date,
        lower(trim(coalesce(area, 'moldes')::text))
      ORDER BY coalesce(updated_at, 'epoch'::timestamptz) DESC NULLS LAST
    ) AS rn
  FROM public.armado_lineas
)
DELETE FROM public.armado_lineas AS t
WHERE t.ctid IN (SELECT ctid FROM ranked WHERE rn > 1);

COMMIT;

-- Verificación rápida
-- SELECT linea, turno, fecha, area, updated_at FROM public.armado_lineas ORDER BY fecha DESC, linea, area LIMIT 50;
