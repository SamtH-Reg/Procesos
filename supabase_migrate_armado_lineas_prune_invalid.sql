-- Filas inválidas en armado_lineas (línea vacía o fecha vacía) rompen pull/merge y llenan la consola de avisos.
-- Ejecutar en Supabase SQL Editor (una vez). No borra filas con L1+L2+fecha válida.

delete from public.armado_lineas
where trim(coalesce(linea::text, '')) = ''
   or trim(coalesce(fecha::text, '')) = '';
