-- ═══════════════════════════════════════════════════════════════════════════
-- RLS · public.generales (Registro general — tablet index.html + admin)
-- ═══════════════════════════════════════════════════════════════════════════
-- Síntoma:
--   La tablet muestra "Por subir" mucho tiempo y aparece en consola/toast:
--     "new row violates row-level security policy for table 'generales'"
--   Esto bloquea TODOS los reintentos (2s + 5s + 15s + 45s) y se ven 67 s.
--
-- Causa típica:
--   La tabla `generales` no tiene política RLS para INSERT/UPDATE, o tiene
--   una `dev_rls_*` permisiva que se quitó sin reemplazar, o `can_write()`
--   no incluye al rol `planillero`.
--
-- Misma regla que moldes/pesajes en supabase_auth.sql:
--   - SELECT  → cualquier usuario authenticated
--   - ALL     → solo admin, supervisor y planillero
--
-- Idempotente. Ejecutar una vez en Supabase → SQL Editor.
-- Requiere: tabla public.user_profiles con columna rol (text).
-- ═══════════════════════════════════════════════════════════════════════════

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'generales'
  ) THEN
    RAISE NOTICE 'Omitido: no existe public.generales';
    RETURN;
  END IF;

  EXECUTE 'ALTER TABLE public.generales ENABLE ROW LEVEL SECURITY';

  -- Quitar políticas permisivas de desarrollo o nombres antiguos
  EXECUTE 'DROP POLICY IF EXISTS "dev_rls_generales" ON public.generales';
  EXECUTE 'DROP POLICY IF EXISTS "anon_dev_generales_all" ON public.generales';
  EXECUTE 'DROP POLICY IF EXISTS "generales_read" ON public.generales';
  EXECUTE 'DROP POLICY IF EXISTS "generales_write" ON public.generales';
  EXECUTE 'DROP POLICY IF EXISTS "generales_select_authenticated" ON public.generales';
  EXECUTE 'DROP POLICY IF EXISTS "generales_mutate_can_write" ON public.generales';

  EXECUTE $p$
    CREATE POLICY "generales_select_authenticated" ON public.generales
      FOR SELECT TO authenticated
      USING (true)
  $p$;

  EXECUTE $p$
    CREATE POLICY "generales_mutate_can_write" ON public.generales
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

COMMENT ON TABLE public.generales IS
  'Registro general (placa + tablet sin túnel). RLS: supabase_rls_generales_policies.sql';

-- ─── Verificación rápida ──────────────────────────────────────────────────
-- select policyname, cmd, roles::text
-- from pg_policies
-- where schemaname = 'public' and tablename = 'generales'
-- order by policyname;
--
-- Esperado:
--   generales_select_authenticated | SELECT | {authenticated}
--   generales_mutate_can_write     | ALL    | {authenticated}
