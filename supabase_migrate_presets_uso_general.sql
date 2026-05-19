-- Permite uso_equipo = 'general' (Registro general en tablet, sin túnel/placa manual).
-- Error previo: presets_uso_equipo_check solo aceptaba tunel | placa | ambos.

alter table public.presets add column if not exists uso_equipo text;

alter table public.presets drop constraint if exists presets_uso_equipo_check;

alter table public.presets add constraint presets_uso_equipo_check
  check (uso_equipo is null or uso_equipo in ('tunel', 'placa', 'ambos', 'general'));
