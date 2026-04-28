-- ══════════════════════════════════════════════════════════════════
-- DEV: RLS permisivo para admin.html + index.html (anon Y authenticated)
-- ══════════════════════════════════════════════════════════════════
--
-- Con solo "TO anon" falla si el usuario inició sesión en Admin/Tablet:
--   PostgREST usa rol "authenticated", no "anon".
-- Policies sin "TO rol" aplican a TODOS los roles (Postgres).
--
-- RIESGO: intranet / desarrollo. Producción: service_role en backend o RLS fino.
-- ══════════════════════════════════════════════════════════════════

alter table if exists public.presets        enable row level security;
alter table if exists public.trabajadores   enable row level security;
alter table if exists public.turnos         enable row level security;
alter table if exists public.equipos        enable row level security;
alter table if exists public.roles          enable row level security;
alter table if exists public.moldes         enable row level security;

drop policy if exists "anon_dev_presets_all" on public.presets;
drop policy if exists "dev_presets_all_roles" on public.presets;
drop policy if exists "dev_rls_presets" on public.presets;
create policy "dev_rls_presets" on public.presets for all using (true) with check (true);

drop policy if exists "anon_dev_trabajadores_all" on public.trabajadores;
drop policy if exists "dev_rls_trabajadores" on public.trabajadores;
create policy "dev_rls_trabajadores" on public.trabajadores for all using (true) with check (true);

drop policy if exists "anon_dev_turnos_all" on public.turnos;
drop policy if exists "dev_rls_turnos" on public.turnos;
create policy "dev_rls_turnos" on public.turnos for all using (true) with check (true);

drop policy if exists "anon_dev_equipos_all" on public.equipos;
drop policy if exists "dev_rls_equipos" on public.equipos;
create policy "dev_rls_equipos" on public.equipos for all using (true) with check (true);

drop policy if exists "anon_dev_roles_all" on public.roles;
drop policy if exists "dev_rls_roles" on public.roles;
create policy "dev_rls_roles" on public.roles for all using (true) with check (true);

drop policy if exists "anon_dev_moldes_all" on public.moldes;
drop policy if exists "dev_rls_moldes" on public.moldes;
create policy "dev_rls_moldes" on public.moldes for all using (true) with check (true);

do $$
begin
  if exists (select 1 from information_schema.tables where table_schema='public' and table_name='pesajes') then
    execute 'alter table public.pesajes enable row level security';
    execute 'drop policy if exists "anon_dev_pesajes_all" on public.pesajes';
    execute 'drop policy if exists "dev_rls_pesajes" on public.pesajes';
    execute 'create policy "dev_rls_pesajes" on public.pesajes for all using (true) with check (true)';
  end if;
end $$;

do $$
begin
  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'armado_lineas'
  ) then
    execute 'alter table public.armado_lineas enable row level security';
    execute 'drop policy if exists "anon_dev_armado_lineas_all" on public.armado_lineas';
    execute 'drop policy if exists "dev_rls_armado_lineas" on public.armado_lineas';
    execute 'create policy "dev_rls_armado_lineas" on public.armado_lineas for all using (true) with check (true)';
  end if;
end $$;
