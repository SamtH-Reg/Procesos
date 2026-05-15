-- Añade tablas a la publicación `supabase_realtime` para que los canales
-- `postgres_changes` sobre ellas funcionen (index/admin ya filtran por `key` en app_kv).
--
-- Síntoma si falta: dashboard en vivo (app_kv) o tablet `tb-eq-runtime-kv` / planilleros
-- no reciben eventos WS; solo HTTP pull.
--
-- Ejecutar una vez en Supabase → SQL Editor.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'app_kv'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.app_kv;
    RAISE NOTICE 'Publicación supabase_realtime: añadida tabla app_kv';
  ELSE
    RAISE NOTICE 'app_kv ya estaba en supabase_realtime';
  END IF;
END $$;

-- Opcional: registros generales (tablet push REST; Realtime si querés reflejo admin sin poll)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='generales')
     AND NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'generales'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.generales;
    RAISE NOTICE 'Publicación supabase_realtime: añadida tabla generales';
  END IF;
END $$;
