const CACHE_NAME = 'reparto-manager-v1.0.5';
const ASSETS = [
    './',
    './index.html',
    './manifest.json',
    './styles/main.css',
    './scripts/core/Globals.js',
    './scripts/core/App.js',
    './scripts/views/View_Config.js',
    './scripts/views/View_Inventory.js',
    './scripts/views/View_POS.js',
    './scripts/actions/Action_Inventory.js',
    './scripts/actions/Action_POS.js',
    './scripts/actions/Action_Printer.js',
    './scripts/utils/ESCPOS.js',
    './scripts/core/Firebase.js'
];

self.addEventListener('install', event => {
    self.skipWaiting();
    event.waitUntil(
        caches.open(CACHE_NAME).then(cache => {
            return cache.addAll(ASSETS);
        })
    );
});

self.addEventListener('activate', event => {
    event.waitUntil(
        caches.keys().then(cacheNames => {
            return Promise.all(
                cacheNames.map(cache => {
                    if (cache !== CACHE_NAME) {
                        return caches.delete(cache);
                    }
                })
            );
        }).then(() => self.clients.claim())
    );
});

self.addEventListener('fetch', event => {
    event.respondWith(
        caches.match(event.request).then(cachedResponse => {
            const fetchPromise = fetch(event.request).then(networkResponse => {
                // Actualizar la caché silenciosamente en segundo plano
                if (networkResponse && networkResponse.status === 200) {
                    caches.open(CACHE_NAME).then(cache => {
                        cache.put(event.request, networkResponse.clone());
                    });
                }
                return networkResponse;
            }).catch(() => {
                // Falla de red (offline), ignorar para que use lo que hay en caché
            });
            
            // Devuelve la caché rápido si existe, mientras networkPromise actualiza por detrás
            return cachedResponse || fetchPromise;
        })
    );
});
