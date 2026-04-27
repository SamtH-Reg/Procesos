# Continuidad del proyecto (handoff para nuevos chats)

Copia este archivo o su resumen al inicio de un chat nuevo y adjunta `@index.html` y/o `@admin.html` según lo que vayas a tocar.

## Proyecto

- **Nombre:** FRIOSUR — control de producción (planta).
- **Repo remoto:** `SamtH-Reg/Procesos`, rama **`main`**.
- **Apps:** `index.html` (tablet) · `admin.html` (consola).
- **Backend:** Supabase (JS en cliente); datos locales en `localStorage`.

## Convención de trabajo

- Cambios **acotados** al pedido; al terminar: **`git commit` + `git push`** a `main` (sin pedir permiso).

## Estado reciente (últimos commits útiles)

Revisar `git log` para el detalle; referencia aproximada:

- **Pesaje / picker iOS:** dos líneas — arriba `Ficha:` + valor; abajo nombre y `Código:` en la misma fila; búsqueda por nombre, código y nº ficha.
- **`pRegFicha`:** solo lectura, estilo verde; la ficha efectiva prioriza **armado de línea** y datos del picker (`data-ficha`).
- **`_getPRegPickerPlanilleros` / `_getPRegPickerWorkers`:** mezclan ficha del armado con el maestro `DB`; código sigue siendo el del maestro.
- **`regPesaje`:** aviso de discrepancia compara contra ficha de selección/armado, no solo contra el maestro.
- **Admin:** tabla trabajadores con columna **Ficha**; búsqueda incluye ficha.

## Riesgos / deuda conocida (auditoría previa)

- **Schema vs tablet:** en tablet aún puede usarse `armado_lineas` mientras el SQL define `armado_linea` — revisar consistencia antes de producción.
- **Secretos:** han existido keys en HTML/SQL/config local; conviene **rotar** anon keys y no commitear secretos nuevos.

## Arranque local

- Ver `.claude/launch.json` (servidor estático Python puerto 5500) o abrir los HTML directamente.
