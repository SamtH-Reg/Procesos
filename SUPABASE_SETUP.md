# 🗄 FRIOSUR SpA — Guía Detallada de Integración con Supabase

Esta guía te lleva paso a paso desde crear el proyecto en Supabase hasta tener la aplicación (Tablet + Admin) sincronizando datos en la nube, con multi-usuario, backups automáticos y acceso seguro.

---

## 📋 Tabla de Contenidos

1. [Crear proyecto Supabase](#1-crear-proyecto-supabase)
2. [Ejecutar el schema SQL](#2-ejecutar-el-schema-sql)
3. [Conectar la aplicación (Admin)](#3-conectar-la-aplicación-admin)
4. [Primera sincronización (Push / Pull)](#4-primera-sincronización-push--pull)
5. [Autenticación de usuarios](#5-autenticación-de-usuarios)
6. [Row Level Security (RLS)](#6-row-level-security-rls)
7. [Tiempo real (Realtime)](#7-tiempo-real-realtime)
8. [Storage (archivos, fotos, Excel)](#8-storage-archivos-fotos-excel)
9. [Edge Functions (lógica servidor)](#9-edge-functions-lógica-servidor)
10. [Backups y replicación](#10-backups-y-replicación)
11. [Despliegue GitHub Pages + Supabase](#11-despliegue-github-pages--supabase)
12. [Checklist producción](#12-checklist-producción)
13. [Costos estimados](#13-costos-estimados)
14. [Troubleshooting](#14-troubleshooting)

---

## 1. Crear proyecto Supabase

### Paso a paso

1. Ir a **https://supabase.com** → **Start your project** → login con GitHub
2. **New project**:
   - **Organization**: crea o elige una (p.ej. "Friosur")
   - **Name**: `friosur-produccion`
   - **Database password**: genera una fuerte y **guárdala** (la vas a necesitar)
   - **Region**: **South America (São Paulo)** — la más cercana a Chile
   - **Pricing plan**: Free (es suficiente para empezar: 500 MB DB, 1 GB storage, 2 GB bandwidth/mes)
3. Espera 1–2 minutos a que provisione
4. Guarda dos valores de **Settings → API**:
   - **Project URL**: `https://<ref>.supabase.co`
   - **anon (public) key**: `eyJhbGc...` — este es el que usa el cliente JS

> ⚠️ Nunca subas la **service_role key** al front-end. Solo `anon` va en el cliente.

---

## 2. Ejecutar el schema SQL

1. En el dashboard de Supabase → **SQL Editor** → **New query**
2. Abre `supabase_schema.sql` de tu repo (el archivo está en la raíz del proyecto)
3. Copia **todo** el contenido y pégalo en el editor
4. Pulsa **Run** (o Ctrl+Enter)

Esto crea:

| Tabla | Descripción |
|---|---|
| `presets` | Catálogo de productos/presets |
| `trabajadores` | Maestro de personal (ficha, área, rol, turno) |
| `turnos` | Horarios — códigos `dia` / `noche` / ... |
| `equipos` | Túneles y placas |
| `roles` | Permisos por módulo (JSONB) |
| `moldes` | Registros de conteo de moldes |
| `pesajes` | Registros de pesaje individual |
| `armado_linea` | Esquema antiguo / doc (PK incluye `area`: moldes o pesaje) |
| `armado_lineas` | Lo que usa **tablet** `index.html`: planillero+trabajadores; ejecuta `supabase_migrate_armado_lineas_scope.sql` y luego **`supabase_migrate_armado_lineas_area.sql`** (columna `area`: `moldes` vs `pesaje`, misma línea/turno/fecha puede tener dos filas). **RLS:** tras `supabase_auth.sql` (perfiles), ejecuta **`supabase_rls_armado_lineas_policies.sql`** para que admin/planillero/supervisor puedan borrar filas (sin esto el DELETE falla y la línea vuelve al sincronizar). |

Además:
- **Índices** en fecha, línea+turno, especie, trab_id
- **Trigger `set_updated_at`** en las 6 tablas de catálogo
- **Políticas RLS comentadas** (activar en paso 6)
- **Seed opcional** comentado para turnos y roles

Verifica en **Table Editor** que ves las 8 tablas. Si algo falla, el error suele ser por reejecutar: es seguro, todos los `create` usan `if not exists`.

---

## 3. Conectar la aplicación (Admin)

### Desde la consola Admin

1. Abre `admin.html` en el navegador
2. Click en **"Conectar Supabase"** (arriba a la derecha), o ve a la sección **Supabase** en el menú lateral
3. Pega:
   - **URL del proyecto**: `https://<ref>.supabase.co`
   - **Anon key**: `eyJhbGc...`
4. **Conectar** → deberías ver el chip superior pasar a verde "Supabase: conectado"
5. **Probar** → hace un `select count(*) from presets` para validar

Las credenciales se guardan en `localStorage` bajo la clave `friosur_sb`. Para desconectar, borra esa clave o usa el botón de reset.

### Verificar conexión desde la consola del navegador

```js
// En DevTools → Console:
const { data, error } = await window.supabase.from('presets').select('*').limit(1);
console.log(data, error);
```

---

## 4. Primera sincronización (Push / Pull)

### Push (subir datos locales → Supabase)

En la consola Admin → **Supabase** → **⬆ Subir datos**

Qué hace `pushAll()` internamente:
```js
for (const tabla of ['presets','trabajadores','turnos','equipos','roles','moldes','pesajes','armado_linea']) {
  await supabase.from(tabla).upsert(DB.data[tabla] || RT.data[tabla], { onConflict: 'id' });
}
```

- **Upsert por PK** (`id` o `codigo`, según la tabla)
- Los duplicados se actualizan, los nuevos se insertan
- Si una fila falla (FK inválida, tipo incorrecto) se loguea y continúa con la siguiente
- Ver el panel de log en la misma página para ver conteos

### Pull (descargar de Supabase → local)

**⬇ Descargar** ejecuta:
```js
for (const tabla of [...]) {
  const { data } = await supabase.from(tabla).select('*');
  DB.data[tabla] = data; // o RT.data[tabla] según corresponda
}
DB.save(); RT.save();
```

⚠️ **Cuidado**: esto **sobrescribe** los datos locales. Haz un push primero si tienes cambios sin sincronizar.

### Estrategia recomendada

| Caso | Acción |
|---|---|
| Primer arranque (datos solo locales) | Push |
| Dispositivo nuevo (no tiene datos) | Pull |
| Cambios en ambos lados | Pull + resolver manualmente + Push |
| Turno cerrado (consolidar) | Push al final del turno |

---

## 5. Autenticación de usuarios

Supabase Auth soporta email/password, magic-link, OAuth (Google, GitHub), y SSO.

### 5.1. Activar Email/Password

1. **Authentication → Providers → Email** → Enable
2. Opcional: **Authentication → Settings** → desactiva "Enable email confirmations" mientras estás en desarrollo (para saltarte el click en el correo)
3. Crea el primer usuario admin en **Authentication → Users → Add user → Create new user**:
   - Email: `admin@friosur.cl`
   - Password: (fuerte)

### 5.2. Login desde la app (agregar a admin.html)

Añade un modal de login antes del `renderDashboard()` inicial:

```html
<!-- Modal de login -->
<div id="loginModal" class="modal-backdrop" style="display:none;">
  <div class="modal">
    <div class="modal-hdr"><div class="modal-title">Iniciar sesión</div></div>
    <div class="modal-body">
      <div class="form-field"><label class="form-label">Email</label><input class="input" id="loginEmail" type="email"></div>
      <div class="form-field"><label class="form-label">Contraseña</label><input class="input" id="loginPass" type="password"></div>
    </div>
    <div class="modal-ftr"><button class="btn" onclick="doLogin()">Entrar</button></div>
  </div>
</div>

<script>
async function doLogin() {
  const email = document.getElementById('loginEmail').value;
  const password = document.getElementById('loginPass').value;
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) { toast(error.message, 'err'); return; }
  document.getElementById('loginModal').style.display = 'none';
  toast('Bienvenido ' + data.user.email, 'success');
  currentUser = data.user;
  renderDashboard();
}

async function checkSession() {
  const { data } = await supabase.auth.getSession();
  if (!data.session) document.getElementById('loginModal').style.display = 'flex';
  else currentUser = data.session.user;
}

// En vez de renderDashboard() directo:
checkSession().then(() => renderDashboard());
</script>
```

### 5.3. Logout

```js
async function doLogout() {
  await supabase.auth.signOut();
  currentUser = null;
  location.reload();
}
```

### 5.4. Obtener rol / permisos tras login

Guarda el rol en una tabla `user_profiles`:

```sql
create table if not exists user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nombre text,
  rol text default 'operario',  -- 'admin' | 'supervisor' | 'planillero' | 'operario'
  created_at timestamptz default now()
);

-- Trigger: al crear un usuario, crear profile automáticamente
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.user_profiles (id, nombre, rol)
  values (new.id, coalesce(new.raw_user_meta_data->>'nombre', new.email), 'operario');
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
```

Luego desde la app:
```js
const { data: profile } = await supabase
  .from('user_profiles')
  .select('*')
  .eq('id', currentUser.id)
  .single();
console.log('Tu rol:', profile.rol);
```

---

## 6. Row Level Security (RLS)

**Obligatorio** antes de ir a producción. Sin RLS, cualquiera con la anon key puede leer/escribir todo.

### 6.1. Activar RLS

Descomenta las líneas en `supabase_schema.sql` (o ejecútalas directo):

```sql
alter table presets        enable row level security;
alter table trabajadores   enable row level security;
alter table turnos         enable row level security;
alter table equipos        enable row level security;
alter table roles          enable row level security;
alter table moldes         enable row level security;
alter table pesajes        enable row level security;
alter table armado_linea   enable row level security;
alter table user_profiles  enable row level security;
```

### 6.2. Políticas por rol

**Catálogos** (solo lectura pública, escritura autenticada):

```sql
-- Presets: todos pueden leer
create policy "presets_read" on presets for select using (true);
-- Solo admin/supervisor pueden modificar
create policy "presets_write" on presets for all using (
  exists (select 1 from user_profiles where id=auth.uid() and rol in ('admin','supervisor'))
);
```

**Registros operativos** (leer todo autenticado, escribir lo propio):

```sql
-- Moldes: leer si estás autenticado
create policy "moldes_read" on moldes for select
  using (auth.role() = 'authenticated');

-- Moldes: insertar solo si estás autenticado
create policy "moldes_insert" on moldes for insert
  with check (auth.role() = 'authenticated');

-- Moldes: editar/borrar solo admin/supervisor
create policy "moldes_edit" on moldes for update
  using (exists (select 1 from user_profiles where id=auth.uid() and rol in ('admin','supervisor')));
create policy "moldes_delete" on moldes for delete
  using (exists (select 1 from user_profiles where id=auth.uid() and rol='admin'));
```

Repite el patrón para `pesajes`, `armado_linea`.

**User profiles** (cada usuario ve/edita el suyo):

```sql
create policy "profile_self_read" on user_profiles for select
  using (auth.uid() = id);
create policy "profile_admin_all" on user_profiles for all
  using (exists (select 1 from user_profiles where id=auth.uid() and rol='admin'));
```

### 6.3. Probar RLS

En **SQL Editor**, cambia el rol para simular:

```sql
-- Como anónimo (sin login)
set role anon;
select * from moldes;  -- debería fallar o no devolver nada

-- Como autenticado de prueba
set role authenticated;
select set_config('request.jwt.claims', '{"sub":"<user-uuid>"}', true);
select * from moldes;  -- debería funcionar

reset role;
```

---

## 7. Tiempo real (Realtime)

Para que los cambios en un dispositivo (tablet) aparezcan automáticamente en otro (admin) sin recargar.

### 7.1. Activar Realtime por tabla

**Database → Replication → supabase_realtime** → activa toggles en:
- `moldes`, `pesajes`, `armado_linea`, `equipos` (los que cambian en vivo)

### 7.2. Suscribirse en el cliente

```js
// Escuchar nuevos moldes
const channel = supabase
  .channel('moldes-live')
  .on('postgres_changes', {
    event: '*',            // 'INSERT' | 'UPDATE' | 'DELETE' | '*'
    schema: 'public',
    table: 'moldes'
  }, payload => {
    console.log('Cambio en moldes:', payload);
    // Actualizar el estado local:
    if (payload.eventType === 'INSERT') RT.data.moldes.push(payload.new);
    if (payload.eventType === 'UPDATE') {
      const i = RT.data.moldes.findIndex(r => r.id === payload.new.id);
      if (i >= 0) RT.data.moldes[i] = payload.new;
    }
    if (payload.eventType === 'DELETE') {
      RT.data.moldes = RT.data.moldes.filter(r => r.id !== payload.old.id);
    }
    RT.save();
    renderDashboard();
  })
  .subscribe();

// Cerrar cuando ya no necesites:
// supabase.removeChannel(channel);
```

### 7.3. Filtrar por línea o turno

```js
.on('postgres_changes', {
  event: 'INSERT',
  schema: 'public',
  table: 'moldes',
  filter: 'linea=eq.L2'   // solo L2
}, ...)
```

---

## 8. Storage (archivos, fotos, Excel)

Para guardar backups Excel, fotos de guías, PDFs.

### 8.1. Crear bucket

**Storage → New bucket**:
- **Name**: `exports`
- **Public**: no (mantener privado)

### 8.2. Política de acceso

```sql
-- Usuarios autenticados pueden subir a "exports/"
create policy "auth_upload" on storage.objects for insert
  to authenticated
  with check (bucket_id = 'exports');

-- Autenticados pueden descargar lo propio
create policy "auth_read" on storage.objects for select
  to authenticated
  using (bucket_id = 'exports');
```

### 8.3. Subir un Excel desde la app

```js
async function uploadBackupExcel() {
  const wb = XLSX.utils.book_new();
  // ... arma el libro con los datos
  const blob = new Blob([XLSX.write(wb, { type: 'array', bookType: 'xlsx' })]);
  const path = `backups/${new Date().toISOString().slice(0,10)}_${Date.now()}.xlsx`;
  const { data, error } = await supabase.storage
    .from('exports')
    .upload(path, blob);
  if (error) toast(error.message, 'err');
  else toast('Backup subido: ' + data.path, 'success');
}
```

### 8.4. Descargar con signed URL

```js
const { data } = await supabase.storage
  .from('exports')
  .createSignedUrl('backups/2026-04-24_xxx.xlsx', 3600); // 1h
window.open(data.signedUrl);
```

---

## 9. Edge Functions (lógica servidor)

Para tareas que no deben correr en el cliente:
- Enviar correos (reporte diario)
- Consolidar turno y cerrar el día automáticamente a las 08:00
- Webhooks a sistemas ERP externos

### Ejemplo: consolidar turno al finalizar

`supabase/functions/cerrar-turno/index.ts`:

```ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  const { fecha, turno } = await req.json();

  const { data: moldes } = await supabase.from('moldes')
    .select('*').eq('fecha', fecha).eq('turno', turno);
  const { data: pesajes } = await supabase.from('pesajes')
    .select('*').eq('fecha', fecha).eq('turno', turno);

  const totalKg = [...moldes, ...pesajes].reduce((s, r) => s + (r.kg || 0), 0);

  await supabase.from('turno_consolidado').insert({
    fecha, turno, total_kg: totalKg,
    moldes: moldes.length, pesajes: pesajes.length,
    cerrado_at: new Date().toISOString()
  });

  return new Response(JSON.stringify({ ok: true, totalKg }), {
    headers: { 'Content-Type': 'application/json' }
  });
});
```

Deploy: `supabase functions deploy cerrar-turno`

Invocar desde la app:
```js
const { data } = await supabase.functions.invoke('cerrar-turno', {
  body: { fecha: '2026-04-24', turno: 'dia' }
});
```

### Cron (programado)

En `supabase/config.toml`:
```toml
[functions.cerrar-turno]
schedule = "0 8,20 * * *"  # 08:00 y 20:00 todos los días
```

---

## 10. Backups y replicación

### 10.1. Backups automáticos

Free tier: backup diario retenido 7 días.
Pro tier: 30 días + PITR (point-in-time recovery).

**Database → Backups** → ver histórico y restaurar.

### 10.2. Backup manual a JSON/Excel

Desde la app Admin:
- **Supabase → ⬇ Descargar** → trae todo el estado
- **Exportar → JSON completo** (en `localStorage`) → guarda todos los datos locales

Recomendado: script cron que llame a una Edge Function que exporte a Storage como JSON comprimido.

### 10.3. Replicar a PostgreSQL externo

Supabase es Postgres puro, puedes usar:
- `pg_dump` desde una Edge Function
- Logical replication a otra instancia Postgres
- Conectar desde Tableau/PowerBI con connection string

Connection string: **Settings → Database → Connection string → URI**

---

## 11. Despliegue GitHub Pages + Supabase

### 11.1. Preparar repo

Estructura esperada:
```
controd/
├── Control Produccion Tablet.html   → renombrar a index.html
├── admin.html
├── supabase_schema.sql
├── SUPABASE_SETUP.md
└── README.md
```

```bash
cd /c/Users/siste/Desktop/controd
git init
git add .
git commit -m "FRIOSUR producción — v1"
git branch -M main
git remote add origin https://github.com/<tu-usuario>/friosur-produccion.git
git push -u origin main
```

### 11.2. Activar GitHub Pages

1. Repo → **Settings → Pages**
2. **Source**: `main` branch, `/ (root)` folder
3. Save → esperar 1-2 min
4. Tu app estará en `https://<tu-usuario>.github.io/friosur-produccion/`

### 11.3. Configurar CORS en Supabase

Por defecto Supabase acepta peticiones de cualquier origen con la anon key. Si quieres restringir:

**Authentication → URL Configuration**:
- **Site URL**: `https://<tu-usuario>.github.io/friosur-produccion/`
- **Redirect URLs**: agrega la misma + `http://localhost:*` para dev

### 11.4. Variables de entorno

Como es front-end puro, las "variables" van en `localStorage` o hardcoded en un archivo `config.js`:

```js
// config.js — NO COMMITEAR si expone secretos
window.FRIOSUR_CONFIG = {
  SUPABASE_URL: 'https://xxx.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGc...'
};
```

Y en `.gitignore`:
```
config.js
```

Ofrece un `config.example.js` en el repo con valores placeholder.

---

## 12. Checklist producción

Antes de ir a operar 24/7 en planta:

- [ ] Schema SQL ejecutado completo
- [ ] Backup configurado (Pro tier recomendado)
- [ ] **RLS activo** en todas las tablas
- [ ] Políticas RLS probadas con usuarios de prueba
- [ ] Auth email/password activo, email confirmations en producción
- [ ] Mínimo 1 usuario admin creado
- [ ] App desplegada en HTTPS (GitHub Pages, Netlify, Cloudflare Pages)
- [ ] Realtime activo en `moldes`, `pesajes`, `armado_linea`
- [ ] Plan de reconexión si la tablet pierde internet (fallback a `localStorage`, sync cuando vuelva)
- [ ] Tabletas con modo kiosco + auto-login
- [ ] Política de retención de datos definida (¿cuánto tiempo guardamos moldes?)
- [ ] Monitoring: avisos si la DB supera 80% de cuota
- [ ] Documentación de usuarios (supervisor/planillero/operario)

---

## 13. Costos estimados

### Free tier (hasta que lo superes)
- **500 MB database** → ~500.000 registros de moldes+pesajes
- **1 GB storage** → ~100 backups Excel
- **2 GB bandwidth/mes** → ~10.000 pulls completos
- **50.000 MAU** (monthly active users)
- **500.000 Edge Function invocations/mes**
- Backups 7 días

Para una planta con 3 líneas, 2 turnos, ~200 registros/turno → cabe holgado en Free.

### Pro tier ($25/mes)
- **8 GB database**
- **100 GB storage**
- **250 GB bandwidth**
- **Daily backups** 30 días + PITR
- **Soporte por email**

### Team ($599/mes)
- SOC2, SLA, SSO, etc.

---

## 14. Troubleshooting

### "Invalid API key"
La anon key está mal copiada (espacios, caracteres cortados). Cópiala de Settings → API y pégala completa.

### "Row level security policy violated"
RLS está activo pero el usuario no cumple la policy. Revisa:
- ¿Está autenticado? (`await supabase.auth.getSession()`)
- ¿Su rol tiene permiso? (`select * from user_profiles where id=auth.uid()`)

### "could not find the table `public.xxx`"
El schema no se ejecutó o falló. Ve a SQL Editor → History y revisa. Re-ejecuta `supabase_schema.sql`.

### "duplicate key value violates unique constraint"
En `pushAll()` estás intentando insertar IDs que ya existen. Usa `.upsert(..., { onConflict: 'id' })` en vez de `.insert()`.

### "Failed to fetch"
CORS. Revisa Site URL en Auth → URL Configuration.

### La tablet está offline
Diseña fallback:
```js
async function saveRecord(r) {
  RT.data.moldes.push(r); RT.save(); // siempre local primero
  if (navigator.onLine) {
    const { error } = await supabase.from('moldes').insert(r);
    if (error) r._pending = true;
  } else {
    r._pending = true;
  }
}

// Al recuperar conexión
window.addEventListener('online', async () => {
  const pend = RT.data.moldes.filter(r => r._pending);
  for (const r of pend) {
    delete r._pending;
    await supabase.from('moldes').upsert(r);
  }
  RT.save();
});
```

### Quota exceeded
Database llena (>500 MB en free). Opciones:
- Archivar moldes/pesajes viejos a Storage como Excel y borrar de la DB
- Upgrade a Pro

---

## 📞 Referencias

- **Docs oficiales**: https://supabase.com/docs
- **JS SDK**: https://supabase.com/docs/reference/javascript
- **SQL Editor**: https://supabase.com/docs/guides/database
- **Auth**: https://supabase.com/docs/guides/auth
- **RLS**: https://supabase.com/docs/guides/auth/row-level-security
- **Realtime**: https://supabase.com/docs/guides/realtime
- **Storage**: https://supabase.com/docs/guides/storage
- **Edge Functions**: https://supabase.com/docs/guides/functions

---

**Último paso antes de conectar**: avísame cuando tengas la URL y anon key listas y yo agrego los hooks finales (auth modal + realtime subscriptions + offline fallback) en `admin.html` y la tablet.
