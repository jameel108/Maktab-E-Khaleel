// Maktab-E-Khaleel — Service Worker for PWA & Offline UI Caching (Section 20.1 & 24.2)
const CACHE_NAME = "maktab-e-khaleel-v1";
const ASSETS = ["./index.html", "./css/style.css", "./css/dashboard.css", "./js/config.js", "./js/auth.js", "./js/owner-register.js", "./js/dashboard.js"];

self.addEventListener("install", (event) => {
  event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(ASSETS)));
});

self.addEventListener("fetch", (event) => {
  event.respondWith(caches.match(event.request).then((res) => res || fetch(event.request)));
});
