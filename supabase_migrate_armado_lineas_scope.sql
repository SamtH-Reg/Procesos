-- ═══════════════════════════════════════════════════════════════════════════
-- armado_lineas: índice único (linea, turno, fecha) para upsert desde index.html
-- ═══════════════════════════════════════════════════════════════════════════
-- Error en consola: "there is no unique or exclusion constraint matching the
-- ON CONFLICT specification" → PostgREST necesita UNIQUE o PK sobre esas columnas.
--
-- Ejecutar en Supabase → SQL Editor → Run (una vez). Si falla, lee el mensaje:
-- puede haber filas duplicadas (misma línea+turno+fecha) que hay que limpiar antes.
--
-- ERROR 55000 "does not have a replica identity and publishes updates":
-- La tabla está en una publicación (p. ej. Realtime). Tras quitar la PK solo en
-- `linea`, el REPLICA IDENTITY DEFAULT deja de tener clave. Se fuerza FULL antes
-- de tocar constraints y luego USING INDEX sobre el índice compuesto.

-- 0) Réplica lógica / Realtime: evita 55000 al alterar la tabla sin PK temporalmente
ALTER TABLE public.armado_lineas REPLICA IDENTITY FULL;

-- 1) Quitar PK o UNIQUE que sea solo sobre "linea" (impide día+noche en la misma línea)
DO $$
DECLARE
  r RECORD;
  linea_attnum smallint;
BEGIN
  SELECT a.attnum INTO linea_attnum
  FROM pg_class t
  JOIN pg_namespace n ON n.oid = t.relnamespace
  JOIN pg_attribute a ON a.attrelid = t.oid
  WHERE n.nspname = 'public' AND t.relname = 'armado_lineas'
    AND a.attname = 'linea' AND a.attnum > 0 AND NOT a.attisdropped;
  IF linea_attnum IS NULL THEN
    RAISE EXCEPTION 'Tabla public.armado_lineas o columna linea no encontrada';
  END IF;
  FOR r IN
    SELECT c.conname, c.contype
    FROM pg_constraint c
    JOIN pg_class t ON c.conrelid = t.oid
    JOIN pg_namespace n ON t.relnamespace = n.oid
    WHERE n.nspname = 'public' AND t.relname = 'armado_lineas'
      AND c.contype IN ('p','u')
      AND cardinality(c.conkey) = 1
      AND c.conkey[1] = linea_attnum
  LOOP
    EXECUTE format('ALTER TABLE public.armado_lineas DROP CONSTRAINT %I', r.conname);
    RAISE NOTICE 'Eliminado constraint % (solo linea)', r.conname;
  END LOOP;
END $$;

-- 2) turno / fecha NOT NULL (requerido para clave única compuesta)
ALTER TABLE public.armado_lineas ALTER COLUMN turno SET DEFAULT 'dia';
UPDATE public.armado_lineas SET turno = 'dia' WHERE turno IS NULL OR trim(turno::text) = '';
ALTER TABLE public.armado_lineas ALTER COLUMN turno SET NOT NULL;

UPDATE public.armado_lineas SET fecha = CURRENT_DATE WHERE fecha IS NULL;
ALTER TABLE public.armado_lineas ALTER COLUMN fecha SET NOT NULL;

UPDATE public.armado_lineas SET linea = trim(upper(linea::text)) WHERE linea IS NOT NULL;
ALTER TABLE public.armado_lineas ALTER COLUMN linea SET NOT NULL;

-- 3) Unicidad que usa la tablet: onConflict 'linea,turno,fecha'
CREATE UNIQUE INDEX IF NOT EXISTS armado_lineas_linea_turno_fecha_uid
  ON public.armado_lineas (linea, turno, fecha);

-- 3b) Sustituir FULL por identidad basada en el índice (menos ancho de banda en réplica)
ALTER TABLE public.armado_lineas REPLICA IDENTITY USING INDEX armado_lineas_linea_turno_fecha_uid;

-- 4) Columna updated_at (evita 400 si PostgREST espera el campo en el esquema)
ALTER TABLE public.armado_lineas
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

COMMENT ON INDEX public.armado_lineas_linea_turno_fecha_uid IS
  'Usado por index.html pushAll upsert armado_lineas (linea+turno+fecha).';
