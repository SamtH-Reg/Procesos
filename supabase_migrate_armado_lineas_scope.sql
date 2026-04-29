-- Migración opcional: clave única (línea, turno, fecha) para public.armado_lineas
-- ---------------------------------------------------------------------------
-- index.html hace upsert con onConflict: 'linea,turno,fecha' (alcance = _armScopeKey).
-- Si la tabla tenía UNIQUE o PRIMARY KEY solo en "linea", PostgreSQL devolvía:
--   ON CONFLICT DO UPDATE command cannot affect row a second time
-- al subir L1 turno día + L1 turno noche en el mismo batch.
--
-- Pasos: Table Editor → armado_lineas → revisa Constraints / Indexes.
-- Ajusta los nombres de constraint abajo a los que muestre tu proyecto, luego ejecuta.

-- Opción A — PK era solo (linea):
-- alter table public.armado_lineas drop constraint if exists armado_lineas_pkey;
-- alter table public.armado_lineas add primary key (linea, turno, fecha);

-- Opción B — PK es "id" u otra; añadir unicidad del alcance (deja PK como está):
-- create unique index if not exists armado_lineas_linea_turno_fecha_key
--   on public.armado_lineas (linea, turno, fecha);

-- Si ya existe un índice único equivalente, no hace falta ejecutar nada.
