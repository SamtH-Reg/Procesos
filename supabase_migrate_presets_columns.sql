-- ══════════════════════════════════════════════════════════════════
-- Alinear tabla public.presets con lo que envía admin.html (upsert)
-- Tu tabla solo tenía id, nombre, tipo, formato, destino → faltan columnas.
-- Ejecutar una vez en SQL Editor del MISMO proyecto que usa el admin.
-- ══════════════════════════════════════════════════════════════════

alter table public.presets add column if not exists especie text;
alter table public.presets add column if not exists calibre text;
alter table public.presets add column if not exists kg_ref numeric;
alter table public.presets add column if not exists horas_tunel numeric;
alter table public.presets add column if not exists horas_placa numeric;
alter table public.presets add column if not exists temp_obj numeric;
alter table public.presets add column if not exists activo boolean default true;
alter table public.presets add column if not exists created_at timestamptz default now();
alter table public.presets add column if not exists updated_at timestamptz default now();

-- Verificar columnas
select column_name, data_type
from information_schema.columns
where table_schema = 'public' and table_name = 'presets'
order by ordinal_position;
