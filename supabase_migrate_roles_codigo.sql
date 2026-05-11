-- Idempotente: columna codigo en roles + índice (ya aplicable vía MCP migrate).
alter table if exists public.roles add column if not exists codigo text;
comment on column public.roles.codigo is 'Debe coincidir con user_profiles.rol y trabajadores.rol (minúsculas, sin espacios).';
create index if not exists idx_roles_codigo_lower on public.roles (lower(codigo)) where codigo is not null and btrim(codigo) <> '';
update public.roles r
set codigo = lower(regexp_replace(regexp_replace(trim(r.nombre), '[^a-zA-Z0-9]+', '_', 'g'), '^_+|_+$', '', 'g'))
where (r.codigo is null or btrim(r.codigo) = '') and r.nombre is not null and btrim(r.nombre) <> '';
