/* ══════════════════════════════════════════════════════════════════════════
   Service Worker Friosur — subida de pesajes en segundo plano (Background Sync)

   POR QUÉ EXISTE: Chrome congela el JavaScript de una pestaña oculta/bloqueada,
   y con eso mueren los reintentos de subida de la página. Este worker corre en
   un hilo APARTE: cuando la página registra el sync 'obx-sync', el navegador lo
   despierta (aunque la pestaña esté congelada, e incluso al volver la conexión)
   y sube lo pendiente del outbox directo al REST de Supabase.

   - Lee el MISMO outbox IndexedDB de la página (friosur_outbox/pesajes), sin
     versión fija para no chocar con la página.
   - Credenciales+token: la página los espeja en friosur_sw_meta/meta (el worker
     no puede leer localStorage).
   - Subida idempotente: upsert on_conflict=id + return=minimal (egress ≈ 0).
     Borra del outbox SOLO las filas confirmadas.
   - Error de red/5xx → throw → el navegador reintenta el sync con backoff.
   - 401/403 (token vencido) → throw también: la página renueva sesión al volver
     al foco y el reintento usa el token fresco del espejo.
   - 4xx de datos → intenta fila por fila y deja las malas (no borra datos).
   ══════════════════════════════════════════════════════════════════════════ */
'use strict';
const OBX_DB='friosur_outbox', OBX_STORE='pesajes';
const META_DB='friosur_sw_meta', META_STORE='meta';

self.addEventListener('install',e=>{self.skipWaiting();});
self.addEventListener('activate',e=>{e.waitUntil(self.clients.claim());});

function _open(name){
  // Sin versión: abre la que exista (no dispara upgrades que bloqueen a la página).
  return new Promise((res,rej)=>{
    let r;try{r=indexedDB.open(name);}catch(e){return rej(e);}
    r.onsuccess=()=>res(r.result);
    r.onerror=()=>rej(r.error);
  });
}
function _getAll(db,store){
  return new Promise((res,rej)=>{
    if(!db.objectStoreNames.contains(store))return res([]);
    let tx;try{tx=db.transaction(store,'readonly');}catch(e){return res([]);}
    const q=tx.objectStore(store).getAll();
    q.onsuccess=()=>res(q.result||[]);
    q.onerror=()=>rej(q.error);
  });
}
function _delMany(db,store,ids){
  return new Promise((res,rej)=>{
    if(!ids.length||!db.objectStoreNames.contains(store))return res();
    let tx;try{tx=db.transaction(store,'readwrite');}catch(e){return res();}
    const st=tx.objectStore(store);
    ids.forEach(id=>{try{st.delete(id);}catch(_){}});
    tx.oncomplete=()=>res();
    tx.onerror=()=>rej(tx.error);
    tx.onabort=()=>res();
  });
}
async function _meta(){
  try{
    const db=await _open(META_DB);
    const rows=await _getAll(db,META_STORE);
    try{db.close();}catch(_){}
    return rows.find(r=>r&&r.k==='sb')||null;
  }catch(_){return null;}
}
function _post(meta,rows){
  return fetch(meta.url+'/rest/v1/pesajes?on_conflict=id',{
    method:'POST',
    headers:{'Content-Type':'application/json','apikey':meta.key,
      'Authorization':'Bearer '+meta.tok,
      'Prefer':'resolution=merge-duplicates,return=minimal'},
    body:JSON.stringify(rows)
  });
}
async function drainOutbox(){
  const meta=await _meta();
  if(!meta||!meta.url||!meta.key||!meta.tok)return;
  const db=await _open(OBX_DB);
  try{
    const rows=(await _getAll(db,OBX_STORE)).filter(r=>r&&r.id!=null);
    if(!rows.length)return;
    for(let i=0;i<rows.length;i+=100){
      const batch=rows.slice(i,i+100);
      const res=await _post(meta,batch);
      if(res.ok){await _delMany(db,OBX_STORE,batch.map(b=>b.id));continue;}
      if(res.status===401||res.status===403)throw new Error('auth '+res.status); // token vencido → backoff, reintenta con token renovado
      if(res.status>=500||res.status===429)throw new Error('HTTP '+res.status);  // servidor/red → backoff
      // 4xx de datos: fila por fila; las buenas suben, las malas quedan (no se borra nada).
      for(const row of batch){
        try{const r1=await _post(meta,[row]);if(r1.ok)await _delMany(db,OBX_STORE,[row.id]);}catch(_){}
      }
    }
  }finally{try{db.close();}catch(_){}}
}
self.addEventListener('sync',e=>{
  if(e.tag!=='obx-sync')return;
  e.waitUntil((async()=>{
    try{
      await drainOutbox();   // red/5xx/auth → throw → backoff del navegador
      // Drenó sin error pero ¿quedaron filas (p.ej. token recién renovado)?
      // Re-registrar para otro ciclo apenas haya señal.
      try{
        const db=await _open(OBX_DB);
        const n=(await _getAll(db,OBX_STORE)).length;
        try{db.close();}catch(_){}
        if(n>0&&self.registration.sync)await self.registration.sync.register('obx-sync');
      }catch(_){}
    }catch(err){
      // lastChance = el navegador agotó sus ~3 reintentos y va a ABANDONAR el
      // sync. Sin esto, los pendientes quedaban esperando a que alguien abra
      // la app. Re-registrando un sync NUEVO el ciclo renace: reintentos
      // eternos espaciados, y sube apenas la tablet tenga señal.
      if(e.lastChance){
        try{if(self.registration.sync)await self.registration.sync.register('obx-sync');}catch(_){}
      }
      throw err;
    }
  })());
});
self.addEventListener('message',e=>{
  // Fallback para navegadores sin Background Sync: la página pide drenar directo.
  if(e.data&&e.data.type==='obx-drain'&&e.waitUntil)e.waitUntil(drainOutbox());
});
