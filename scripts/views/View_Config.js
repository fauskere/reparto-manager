/**
 * Archivo: scripts/views/View_Config.js
 * Propósito: Manejar las vistas relacionadas con la configuración y utilidades.
 */

window.UI.Config_RenderVersion = function() {
    const container = document.getElementById('config-container');
    if (container) {
        container.innerHTML = `
            <div style="display: flex; align-items: center; gap: 0.5rem;">
                <span class="version-badge">${window.AppConfig.version}</span>
                <button onclick="window.Actions.App_ForceUpdate()" style="background: var(--bg-secondary); color: var(--text-primary); border: 1px solid var(--border-color); border-radius: var(--radius-md); padding: 0.3rem 0.6rem; font-size: 0.8rem; cursor: pointer; transition: background 0.2s;" onmouseover="this.style.background='var(--border-color)'" onmouseout="this.style.background='var(--bg-secondary)'">
                    🔄 Forzar Actualización
                </button>
            </div>
        `;
    }
};
