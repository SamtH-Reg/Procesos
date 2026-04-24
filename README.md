# Control de Producción — Friosur SpA

Sistema web para control de producción en planta procesadora de pescado.

## Apps

- **`index.html`** — Tablet para planilleros (Moldes, Pesaje, Túneles/Placas)
- **`admin.html`** — Consola de administración (Dashboard, reportes, catálogos, usuarios)

## Backend

- Supabase (PostgreSQL + Auth + Realtime)
- Schema en `supabase_schema.sql`
- Auth + RLS en `supabase_auth.sql`
- Crear usuarios en `supabase_create_users.sql`

## URL

- Tablet: `https://USUARIO.github.io/REPO/`
- Admin: `https://USUARIO.github.io/REPO/admin.html`

## Roles

| Rol | Acceso |
|---|---|
| admin | Todo |
| supervisor | Operación + catálogos (lectura) |
| planillero | Moldes, pesaje, armado de líneas |
| operario | Solo lectura dashboards |
