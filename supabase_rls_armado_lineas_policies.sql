-- ═══════════════════════════════════════════════════════════════════════════
-- RLS · public.armado_lineas (tablet index.html + admin en vivo)
-- ═══════════════════════════════════════════════════════════════════════════
-- La tablet borra filas con .delete() tras quitar la línea en RT; si RLS no
-- permite DELETE, el upsert siguiente no elimina la fila y la línea "vuelve"
-- al hacer pull o Realtime.
--
-- Misma regla que moldes/pesajes en supabase_auth.sql: lectura para cualquier
-- usuario autenticado; INSERT/UPDATE/DELETE solo admin, supervisor y planillero.
-- (Expresión equivalente a can_write(); si ya existe can_write(), se puede
-- sustituir por using (can_write()) with check (can_write()).)
--
-- Ejecutar en Supabase → SQL Editor (una vez, idempotente).
-- Requiere: tabla public.user_profiles con columna rol (text).
-- ═══════════════════════════════════════════════════════════════════════════

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'armado_lineas'
  ) THEN
    RAISE NOTICE 'Omitido: no existe public.armado_lineas';
    RETURN;
  END IF;

  EXECUTE 'ALTER TABLE public.armado_lineas ENABLE ROW LEVEL SECURITY';

  -- Quitar políticas permisivas de desarrollo o nombres antiguos
  EXECUTE 'DROP POLICY IF EXISTS "dev_rls_armado_lineas" ON public.armado_lineas';
  EXECUTE 'DROP POLICY IF EXISTS "anon_dev_armado_lineas_all" ON public.armado_lineas';
  EXECUTE 'DROP POLICY IF EXISTS "armado_lineas_read" ON public.armado_lineas';
  EXECUTE 'DROP POLICY IF EXISTS "armado_lineas_write" ON public.armado_lineas';
  EXECUTE 'DROP POLICY IF EXISTS "armado_lineas_select_authenticated" ON public.armado_lineas';
  EXECUTE 'DROP POLICY IF EXISTS "armado_lineas_mutate_can_write" ON public.armado_lineas';

  EXECUTE $p$
    CREATE POLICY "armado_lineas_select_authenticated" ON public.armado_lineas
      FOR SELECT TO authenticated
      USING (true)
  $p$;

  EXECUTE $p$
    CREATE POLICY "armado_lineas_mutate_can_write" ON public.armado_lineas
      FOR ALL TO authenticated
      USING (
        COALESCE(
          (
            SELECT up.rol FROM public.user_profiles up
            WHERE up.id = auth.uid()
          ) IN ('admin', 'supervisor', 'planillero'),
          false
        )
      )
      WITH CHECK (
        COALESCE(
          (
            SELECT up.rol FROM public.user_profiles up
            WHERE up.id = auth.uid()
          ) IN ('admin', 'supervisor', 'planillero'),
          false
        )
      )
  $p$;
END $$;

COMMENT ON TABLE public.armado_lineas IS
  'Armado por línea/turno/fecha/área. RLS: supabase_rls_armado_lineas_policies.sql';
