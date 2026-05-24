-- ═══════════════════════════════════════════════════════════════════════════
-- AUDITORÍA BACKEND · 2026-05-24
-- ═══════════════════════════════════════════════════════════════════════════
-- Aplicada en producción vía MCP Supabase. Este archivo es histórico/idempotente.
-- Si necesitas re-aplicarla en otro entorno, ejecuta este bloque completo en
-- Supabase → SQL Editor.
--
-- Hallazgos cubiertos:
--   1) 8 políticas dev_rls_* permisivas anulaban RLS estricto (CRÍTICO)
--   2) 4 políticas duplicadas en roles (CRÍTICO)
--   3) Tabla armado_linea (singular) deprecada
--   4) 2 funciones SECURITY DEFINER sin search_path fijo
--   5) rpc_admin_* exposed a anon
--   6) 10 políticas con auth.uid()/auth.role() per-row (perf)
--   7) FKs sin índice (moldes/generales.preset_id)
--   8) armado_lineas sin PRIMARY KEY
--   9) 2 presets duplicados reales (FILETE FAM y FILETE ESTUCHE B)
-- ═══════════════════════════════════════════════════════════════════════════

-- ─── 1) Drop políticas dev_rls_* y duplicadas en roles ────────────────────
do $$
declare pol record;
begin
  for pol in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname='public' and policyname like 'dev_rls_%'
  loop
    execute format('DROP POLICY IF EXISTS %I ON %I.%I', pol.policyname, pol.schemaname, pol.tablename);
  end loop;
  drop policy if exists roles_delete_authenticated on public.roles;
  drop policy if exists roles_insert_authenticated on public.roles;
  drop policy if exists roles_update_authenticated on public.roles;
  drop policy if exists roles_select_authenticated on public.roles;
  if exists(select 1 from information_schema.tables where table_schema='public' and table_name='armado_linea') then
    if (select count(*) from public.armado_linea) = 0 then
      drop table public.armado_linea cascade;
    end if;
  end if;
end$$;

-- ─── 2) Índices FK + PK armado_lineas + optimización RLS ─────────────────
create index if not exists idx_moldes_preset_id on public.moldes(preset_id);
create index if not exists idx_generales_preset_id on public.generales(preset_id);

do $$
begin
  if not exists(
    select 1 from pg_constraint c
    join pg_class t on t.oid=c.conrelid
    where c.contype='p' and t.relname='armado_lineas'
      and t.relnamespace=(select oid from pg_namespace where nspname='public')
  ) then
    drop index if exists public.armado_lineas_linea_turno_fecha_area_uid;
    alter table public.armado_lineas
      add constraint armado_lineas_pkey primary key (linea, turno, fecha, area);
  end if;
end$$;

-- Optimizar RLS: auth.uid()/auth.role() envuelto en (select ...) para caché
drop policy if exists moldes_read on public.moldes;
create policy moldes_read on public.moldes for select to authenticated using ((select auth.role()) = 'authenticated');
drop policy if exists moldes_write on public.moldes;
create policy moldes_write on public.moldes for all to authenticated using (can_write()) with check (can_write());

drop policy if exists pesajes_read on public.pesajes;
create policy pesajes_read on public.pesajes for select to authenticated using ((select auth.role()) = 'authenticated');
drop policy if exists pesajes_write on public.pesajes;
create policy pesajes_write on public.pesajes for all to authenticated using (can_write()) with check (can_write());

drop policy if exists generales_read on public.generales;
create policy generales_read on public.generales for select to authenticated using ((select auth.role()) = 'authenticated');
drop policy if exists generales_write on public.generales;
create policy generales_write on public.generales for all to authenticated using (can_write()) with check (can_write());

drop policy if exists presets_read on public.presets;
create policy presets_read on public.presets for select to authenticated using ((select auth.role()) = 'authenticated');
drop policy if exists presets_write on public.presets;
create policy presets_write on public.presets for all to authenticated using (is_admin()) with check (is_admin());

drop policy if exists trab_read on public.trabajadores;
create policy trab_read on public.trabajadores for select to authenticated using ((select auth.role()) = 'authenticated');
drop policy if exists trab_write on public.trabajadores;
create policy trab_write on public.trabajadores for all to authenticated using (is_admin()) with check (is_admin());

drop policy if exists turnos_read on public.turnos;
create policy turnos_read on public.turnos for select to authenticated using ((select auth.role()) = 'authenticated');
drop policy if exists turnos_write on public.turnos;
create policy turnos_write on public.turnos for all to authenticated using (is_admin()) with check (is_admin());

drop policy if exists equipos_read on public.equipos;
create policy equipos_read on public.equipos for select to authenticated using ((select auth.role()) = 'authenticated');
drop policy if exists equipos_write on public.equipos;
create policy equipos_write on public.equipos for all to authenticated using (is_admin()) with check (is_admin());

drop policy if exists roles_read on public.roles;
create policy roles_read on public.roles for select to authenticated using ((select auth.role()) = 'authenticated');
drop policy if exists roles_write on public.roles;
create policy roles_write on public.roles for all to authenticated using (is_admin()) with check (is_admin());

drop policy if exists up_self_read on public.user_profiles;
create policy up_self_read on public.user_profiles for select to authenticated using ((select auth.uid()) = id or is_admin());

-- ─── 3) Hardening SECURITY DEFINER functions ─────────────────────────────
do $$
begin
  if exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
            where n.nspname='public' and p.proname='set_updated_at') then
    execute 'alter function public.set_updated_at() set search_path = public, pg_catalog';
    execute 'revoke execute on function public.set_updated_at() from anon, public';
  end if;
  if exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
            where n.nspname='public' and p.proname='handle_new_user') then
    execute 'alter function public.handle_new_user() set search_path = public, auth, pg_catalog';
    execute 'revoke execute on function public.handle_new_user() from anon, authenticated, public';
  end if;
end$$;

revoke execute on function public.rpc_admin_create_user(text, text, text, text) from anon, public;
revoke execute on function public.rpc_admin_delete_user(uuid) from anon, public;
revoke execute on function public.rpc_admin_set_user_password(uuid, text) from anon, public;

-- ─── 4) Consolidar presets duplicados reales ─────────────────────────────
-- FILETE FAM · MERLUZA DE COLA · S/C: canon=13, dup=33
update public.generales set preset_id=13 where preset_id=33;
update public.moldes set preset_id=13 where preset_id=33;
update public.presets set activo=false where id=33;

-- FILETE ESTUCHE B (F18) · MERLUZA AUSTRAL · 300-UP: canon=17, dup=29
update public.generales set preset_id=17 where preset_id=29;
update public.moldes set preset_id=17 where preset_id=29;
update public.presets set activo=false where id=29;

-- ═══════════════════════════════════════════════════════════════════════════
-- NOTA OPERATIVA (no aplicable por SQL):
-- En Supabase Dashboard → Auth → Settings, habilita
--   "Leaked password protection" (HaveIBeenPwned)
-- para bloquear contraseñas comprometidas al registrar usuarios.
-- ═══════════════════════════════════════════════════════════════════════════
