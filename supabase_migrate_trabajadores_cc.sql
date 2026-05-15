-- Campos de Asistencia (centro de costo, tipo contrato) para sync multi-equipo.
alter table if exists public.trabajadores
  add column if not exists centro_costo text,
  add column if not exists contrato text;

comment on column public.trabajadores.centro_costo is 'Centro de costo (origen proyecto Asistencia)';
comment on column public.trabajadores.contrato is 'Tipo contrato, ej. Indefinido / Temporeros';
