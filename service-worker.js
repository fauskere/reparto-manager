const CACHE_NAME = 'reparto-manager-v1.0.2';
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
    './scripts/utils/ESCPOS.js'
];

self.addEventListener('install', event => {
    event.waitUntil(
        caches.open(CACHE_NAME).then(cache => {
            return cache.addAll(ASSETS);
        })
    );
});

self.addEventListener('fetch', event => {
    event.respondWith(
        caches.match(event.request).then(response => {
            return response || fetch(event.request);
        })
    );
});
