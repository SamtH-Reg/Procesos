-- Clave/valor compartido: `friosur_dashboard` (layout admin), `friosur_eq_runtime` (túneles/placas: eqState+eqHist).
-- Ejecutar en SQL Editor de Supabase (una vez, o reaplicar si cambias RLS).

create table if not exists app_kv(
  key        text primary key,
  value      jsonb not null default '{}'::jsonb,
  updated_at timestamptz default now()
);

-- Requiere la función set_updated_at() de supabase_schema.sql (o equivalente).

drop trigger if exists trg_app_kv_updated on app_kv;
create trigger trg_app_kv_updated
  before update on app_kv
  for each row execute function set_updated_at();

comment on table app_kv is 'KV compartido: friosur_dashboard (widgets admin), friosur_eq_runtime (estado+histórico túneles/placas, JSON eqState/eqHist)';

-- ═══════════════════════════════════════════════════════════════════
-- RLS: sin políticas, un upsert desde el cliente autenticado puede dar 403.
-- Estas políticas permiten SELECT/INSERT/UPDATE a usuarios con sesión Supabase.
-- ═══════════════════════════════════════════════════════════════════

alter table app_kv enable row level security;

drop policy if exists "app_kv_select_authenticated" on app_kv;
drop policy if exists "app_kv_insert_authenticated" on app_kv;
drop policy if exists "app_kv_update_authenticated" on app_kv;
drop policy if exists "app_kv_delete_authenticated" on app_kv;
drop policy if exists "app_kv_read" on app_kv;
drop policy if exists "app_kv_write" on app_kv;
drop policy if exists "app_kv_update" on app_kv;

create policy "app_kv_select_authenticated"
  on app_kv for select
  to authenticated
  using (true);

create policy "app_kv_insert_authenticated"
  on app_kv for insert
  to authenticated
  with check (true);

create policy "app_kv_update_authenticated"
  on app_kv for update
  to authenticated
  using (true)
  with check (true);

-- Realtime (opcional): Dashboard → Database → Publications → supabase_realtime → añadir tabla app_kv
