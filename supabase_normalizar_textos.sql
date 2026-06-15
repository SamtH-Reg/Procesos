-- ═══════════════════════════════════════════════════════════════════════════
-- Normalizar especie/calibre/producto/destino en datos operativos y presets
-- ═══════════════════════════════════════════════════════════════════════════
-- Aplicado en producción 2026-06-13 vía MCP. Histórico/idempotente.
--
-- PROBLEMA (auditoría de flujos): variaciones de capitalización/espacios
-- fragmentaban los reportes que agrupan por texto exacto. La especie
-- "MERLUZA DE COLA" existía como 3 textos distintos:
--   "MERLUZA DE COLA" · "MERLUZA DE COLA " (espacio) · "Merluza de Cola" (pesajes)
-- → los 331 kg de pesaje y 180 kg de generales NO se sumaban con los moldes
--   en los dashboards (aparecían en grupos separados / "invisibles" al consolidar).
-- También 137 moldes con calibre " 100-300 " (espacios) se separaban del resto.
-- Origen: 1 preset con calibre " 100-300 " y 1 con especie "MERLUZA DE COLA ".
--
-- FIX: normalizar in-place (especie UPPER+TRIM, resto TRIM) en datos y presets.
-- Prevención en código (index.html _rowsForCloudPush + admin SB_MAP.presets.out):
-- toda escritura a la nube ya normaliza, así que no vuelve a ensuciarse.
-- ═══════════════════════════════════════════════════════════════════════════

-- Datos operativos
update public.moldes    set especie = upper(trim(especie)) where especie is not null and especie <> upper(trim(especie));
update public.generales set especie = upper(trim(especie)) where especie is not null and especie <> upper(trim(especie));
update public.pesajes   set especie = upper(trim(especie)) where especie is not null and especie <> upper(trim(especie));

update public.moldes    set calibre = trim(calibre) where calibre is not null and calibre <> trim(calibre);
update public.generales set calibre = trim(calibre) where calibre is not null and calibre <> trim(calibre);

update public.moldes    set producto = trim(producto) where producto is not null and producto <> trim(producto);
update public.generales set producto = trim(producto) where producto is not null and producto <> trim(producto);
update public.moldes    set destino = trim(destino) where destino is not null and destino <> trim(destino);
update public.generales set destino = trim(destino) where destino is not null and destino <> trim(destino);

-- Catálogo de presets (fuente)
update public.presets set especie = upper(trim(especie)) where especie is not null and especie <> upper(trim(especie));
update public.presets set calibre = trim(calibre) where calibre is not null and calibre <> trim(calibre);
update public.presets set nombre  = trim(nombre)  where nombre is not null and nombre <> trim(nombre);
update public.presets set destino = trim(destino) where destino is not null and destino <> trim(destino);
update public.presets set producto_global = trim(producto_global) where producto_global is not null and producto_global <> trim(producto_global);

-- Verificación: no deben quedar variantes de especie
-- with a as (select especie from moldes union all select especie from generales union all select especie from pesajes)
-- select upper(trim(especie)), count(distinct especie) from a where especie is not null
-- group by 1 having count(distinct especie)>1;  -- → 0 filas
