// VERUS ERP - service worker (network-first)
// Sempre busca da rede quando online -> novas versoes aparecem na hora.
// Usa cache apenas como fallback offline.
const CACHE = 'verus-cache-v1';

self.addEventListener('install', function(e){
  self.skipWaiting(); // ativa a nova versao imediatamente
});

self.addEventListener('activate', function(e){
  e.waitUntil(
    caches.keys()
      .then(function(keys){ return Promise.all(keys.map(function(k){ return caches.delete(k); })); })
      .then(function(){ return self.clients.claim(); }) // assume controle das abas abertas
  );
});

self.addEventListener('fetch', function(e){
  var req = e.request;
  if(req.method !== 'GET'){ return; } // nao mexe em POST/PUT (Supabase etc.)
  e.respondWith(
    fetch(req)
      .then(function(resp){
        try{
          var copy = resp.clone();
          caches.open(CACHE).then(function(c){ c.put(req, copy); }).catch(function(){});
        }catch(_){}
        return resp;
      })
      .catch(function(){ return caches.match(req); }) // offline -> cache
  );
});
