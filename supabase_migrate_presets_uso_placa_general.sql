-- Permite uso_equipo = 'placa_general' (preset que aparece en Placa Y en Registro general).
-- Error previo: presets_uso_equipo_check rechazaba 'placa_general' con
--   "new row for relation 'presets' violates check constraint 'presets_uso_equipo_check'"
--
-- Ejecutar en Supabase SQL Editor del proyecto Procesos.

alter table public.presets drop constraint if exists presets_uso_equipo_check;

alter table public.presets add constraint presets_uso_equipo_check
  check (uso_equipo is null or uso_equipo in ('tunel', 'placa', 'ambos', 'general', 'placa_general'));

-- Verificación opcional: cuántos presets están en cada uso_equipo actualmente
-- select uso_equipo, count(*) from public.presets group by uso_equipo order by 1;
