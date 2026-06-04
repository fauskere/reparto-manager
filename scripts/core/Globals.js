/**
 * Archivo: scripts/core/Globals.js
 * Propósito: Inicializar los espacios de nombres globales requeridos por las reglas.
 */

// Inicializamos el objeto UI para todas las vistas (funciones que modifican el DOM)
if (typeof window.UI === 'undefined') {
    window.UI = {};
}

// Inicializamos el objeto Actions para toda la lógica de negocio
if (typeof window.Actions === 'undefined') {
    window.Actions = {};
}

// Configuración global de la aplicación
window.AppConfig = {
    version: 'v1.0.8', // Parche de tamaño de chunks BLE
    name: 'Reparto Manager'
};
