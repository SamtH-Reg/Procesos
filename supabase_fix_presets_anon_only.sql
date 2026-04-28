-- ══════════════════════════════════════════════════════════════════
-- PRESETS: permitir guardar desde admin.html (anon Y authenticated)
-- ══════════════════════════════════════════════════════════════════
--
-- Problema A — Solo clave anon, sin login:
--   Policy "TO anon" basta.
--
-- Problema B — Iniciaste sesión en Admin (Supabase Auth):
--   El cliente usa rol "authenticated", NO "anon".
--   supabase_auth.sql → presets_write pide is_admin(); si tu usuario no
--   es admin en user_profiles, el upsert falla aunque exista policy TO anon.
--
-- Solución robusta (dev / intranet): una policy SIN "TO rol" aplica a
-- TODOS los roles (anon + authenticated). Riesgo: quien tenga acceso API.
-- ══════════════════════════════════════════════════════════════════

alter table public.presets enable row level security;

drop policy if exists "anon_dev_presets_all" on public.presets;
drop policy if exists "dev_presets_all_roles" on public.presets;
drop policy if exists "dev_rls_presets" on public.presets;

-- Sin TO → aplica a anon, authenticated, etc. (Postgres)
create policy "dev_rls_presets" on public.presets
  for all
  using (true)
  with check (true);
