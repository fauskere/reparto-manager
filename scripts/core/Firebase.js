/**
 * Archivo: scripts/core/Firebase.js
 * Propósito: Inicializar Firebase y habilitar soporte Offline en caché.
 */

window.AppConfig.firebaseConfig = {
    apiKey: "AIzaSyCmYAizbCFOiytzHPM8zCYvkBc0tCKdKDo",
    authDomain: "reparto-manager-fb5c2.firebaseapp.com",
    projectId: "reparto-manager-fb5c2",
    storageBucket: "reparto-manager-fb5c2.firebasestorage.app",
    messagingSenderId: "227888814323",
    appId: "1:227888814323:web:e6689482aea43a3e403f86",
    measurementId: "G-XW6WRRRT9Z"
};

// Inicializar Firebase (usando compatibilidad v8 global)
firebase.initializeApp(window.AppConfig.firebaseConfig);
const db = firebase.firestore();

// Habilitar la persistencia Offline (Magia para que funcione sin internet)
db.enablePersistence()
  .catch((err) => {
      if (err.code == 'failed-precondition') {
          console.warn("Persistencia: Múltiples pestañas abiertas. Solo funciona en una a la vez.");
      } else if (err.code == 'unimplemented') {
          console.warn("Persistencia: Tu navegador no soporta caché offline avanzado.");
      }
  });

window.Actions.DB = db;
