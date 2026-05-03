/**
 * Pruebas locales del modelo mental de armado (sin Supabase).
 * Ejecutar: node scripts/verify_armado_logic.mjs
 */
import assert from 'node:assert/strict';

function _tbNormTurnoKey(s) {
  const x = String(s == null || s === '' ? 'dia' : s)
    .trim()
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '');
  return x || 'dia';
}

const ARM_SCOPE_SEP = '@@';
function _armScopeKey(linea, turno, fecha) {
  const m = String(fecha || '').match(/^(\d{4}-\d{2}-\d{2})/);
  const fd = m ? m[1] : '2026-05-03';
  const tk = _tbNormTurnoKey(turno);
  return String(linea || '').trim().toUpperCase() + ARM_SCOPE_SEP + tk + ARM_SCOPE_SEP + fd;
}

assert.equal(_tbNormTurnoKey('Día'), 'dia');
assert.equal(_tbNormTurnoKey('NOCHE'), 'noche');
assert.equal(_armScopeKey('L1', 'Día', '2026-05-03'), 'L1@@dia@@2026-05-03');
assert.equal(_armScopeKey('L1', 'dia', '2026-05-03'), 'L1@@dia@@2026-05-03');

// pushAll: cuando armadoRows queda vacío, la firma debe poder avanzar sin upsert
let lastSig = '{"linea":"L1"}';
const armadoRows = [];
const sigA = JSON.stringify(
  armadoRows.slice().sort((a, b) => {
    const ka = [a.linea, a.turno, a.fecha, a.area].map((x) => String(x || '')).join('\0');
    const kb = [b.linea, b.turno, b.fecha, b.area].map((x) => String(x || '')).join('\0');
    return ka.localeCompare(kb);
  }),
);
assert.equal(sigA, '[]');
if (sigA !== lastSig) {
  if (armadoRows.length) {
    throw new Error('no debería upsert con 0 filas');
  }
  lastSig = sigA;
}
assert.equal(lastSig, '[]');

// tbDelete: no elegir única fila si el turno no coincide (regresión del bug eliminado)
const list = [{ turno: 'noche', fecha: '2026-05-03' }];
const fWant = '2026-05-03';
const tWant = _tbNormTurnoKey('dia');
const rtNorm = (r) => _tbNormTurnoKey(r.turno);
const sameTf = list.find((r) => String(r.fecha).slice(0, 10) === fWant && rtNorm(r) === tWant);
assert.equal(sameTf, undefined);
// Antes existía: if (!row && list.length===1) row=only si misma fecha — borraba noche al pedir dia
let row = sameTf;
if (!row && list.length === 1) {
  const only = list[0];
  if (String(only.fecha).slice(0, 10) === fWant && rtNorm(only) === tWant) row = only;
}
assert.equal(row, undefined);

console.log('verify_armado_logic.mjs: todas las comprobaciones OK');
