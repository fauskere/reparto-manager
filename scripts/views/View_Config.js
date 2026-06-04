/**
 * Archivo: scripts/views/View_Config.js
 * Propósito: Manejar las vistas relacionadas con la configuración.
 */

window.UI.Config_RenderVersion = function() {
    const container = document.getElementById('config-container');
    if (container) {
        container.innerHTML = `
            <span class="version-badge">${window.AppConfig.version}</span>
        `;
    }
};
