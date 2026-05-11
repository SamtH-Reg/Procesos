-- Ejecutar en SQL Editor si el proyecto aún no tiene RLS en `roles`.
-- Tras esto, la tablet solo puede leer `roles` con sesión Supabase (JWT authenticated).

alter table if exists public.roles enable row level security;

drop policy if exists "roles_select_authenticated" on public.roles;
drop policy if exists "roles_insert_authenticated" on public.roles;
drop policy if exists "roles_update_authenticated" on public.roles;
drop policy if exists "roles_delete_authenticated" on public.roles;

create policy "roles_select_authenticated" on public.roles
  for select to authenticated using (true);

create policy "roles_insert_authenticated" on public.roles
  for insert to authenticated with check (true);

create policy "roles_update_authenticated" on public.roles
  for update to authenticated using (true) with check (true);

create policy "roles_delete_authenticated" on public.roles
  for delete to authenticated using (true);
