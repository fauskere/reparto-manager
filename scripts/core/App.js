/**
 * Archivo: scripts/core/App.js
 * Propósito: Controlador principal para arrancar la aplicación.
 */

window.Actions.App_State = {
    currentTab: 'pos'
};

window.Actions.App_Init = function() {
    console.log(`Iniciando ${window.AppConfig.name} ${window.AppConfig.version}`);
    window.Actions.App_RegisterServiceWorker();
    
    // Iniciar escucha del inventario en la nube
    window.Actions.Inventory_Listen(() => {
        // Refrescar vistas automáticamente si cambian los datos remotos
        if (window.Actions.App_State.currentTab === 'inventory') {
            if (typeof window.UI.Inventory_RenderList === 'function') window.UI.Inventory_RenderList();
        } else if (window.Actions.App_State.currentTab === 'pos') {
            if (typeof window.UI.POS_RenderCatalog === 'function') window.UI.POS_RenderCatalog();
        }
    });

    window.UI.App_RenderShell();
};

window.Actions.App_RegisterServiceWorker = function() {
    if ('serviceWorker' in navigator) {
        navigator.serviceWorker.register('./service-worker.js').catch(e => console.warn(e));
    }
};

window.Actions.App_ForceUpdate = function() {
    // 1. Limpiar completamente el Cache Storage de la PWA
    if ('caches' in window) {
        caches.keys().then(function(names) {
            for (let name of names) {
                caches.delete(name);
            }
        });
    }

    // 2. Desregistrar el Service Worker y recargar
    if ('serviceWorker' in navigator) {
        navigator.serviceWorker.getRegistrations().then(function(registrations) {
            for(let registration of registrations) {
                registration.unregister();
            }
            alert("Memoria limpiada profundamente. La app se reiniciará.");
            window.location.href = window.location.pathname + '?t=' + new Date().getTime();
        });
    } else {
        window.location.href = window.location.pathname + '?t=' + new Date().getTime();
    }
};

window.UI.App_RenderShell = function() {
    const appContainer = document.getElementById('app');
    
    appContainer.innerHTML = `
        <header class="app-header glass-panel" style="margin-bottom: 1rem; border-radius: 0 0 var(--radius-lg) var(--radius-lg); border-top: none; display: flex; flex-direction: column; align-items: stretch; padding: 1rem 2rem 0 2rem;">
            <div style="display: flex; align-items: center; justify-content: space-between; width: 100%;">
                <h2 style="font-weight: 800; color: var(--accent-hover); letter-spacing: -0.5px;">${window.AppConfig.name}</h2>
                <div id="config-container"></div>
            </div>
            
            <nav style="display: flex; gap: 2rem; margin-top: 1.5rem; border-bottom: 1px solid var(--border-color);">
                <button onclick="window.UI.App_SwitchTab('pos')" id="tab-pos" style="background: none; border: none; color: var(--text-primary); font-size: 1.05rem; font-weight: 600; cursor: pointer; padding: 0.75rem 0; opacity: 0.5; transition: opacity 0.2s; position: relative;">Punto de Venta</button>
                <button onclick="window.UI.App_SwitchTab('inventory')" id="tab-inventory" style="background: none; border: none; color: var(--text-primary); font-size: 1.05rem; font-weight: 600; cursor: pointer; padding: 0.75rem 0; opacity: 0.5; transition: opacity 0.2s; position: relative;">Inventario</button>
            </nav>
        </header>
        
        <main id="main-content" style="flex: 1; overflow-y: auto; overflow-x: hidden;">
        </main>
    `;
    
    window.UI.Config_RenderVersion();
    window.UI.App_SwitchTab(window.Actions.App_State.currentTab);
};

window.UI.App_SwitchTab = function(tabName) {
    window.Actions.App_State.currentTab = tabName;
    const mainContent = document.getElementById('main-content');
    
    // Reset tabs
    document.getElementById('tab-pos').style.opacity = '0.5';
    document.getElementById('tab-pos').style.boxShadow = 'none';
    document.getElementById('tab-inventory').style.opacity = '0.5';
    document.getElementById('tab-inventory').style.boxShadow = 'none';
    
    // Active tab
    const activeTab = document.getElementById('tab-' + tabName);
    activeTab.style.opacity = '1';
    activeTab.style.boxShadow = 'inset 0 -2px 0 0 var(--accent)';

    if (tabName === 'pos') {
        mainContent.innerHTML = `
            <div class="layout-container" style="height: 100%;">
                <section class="catalog-section" style="overflow-y: auto; padding-right: 0.5rem;">
                    <h3 style="margin-bottom: 1.5rem; color: var(--text-secondary); font-size: 1.1rem; text-transform: uppercase; letter-spacing: 1px;">Catálogo</h3>
                    <div id="pos-catalog"></div>
                </section>
                <aside class="cart-section glass-panel" style="padding: 1.5rem; display: flex; flex-direction: column; height: 100%;">
                    <h3 style="margin-bottom: 1.5rem; border-bottom: 1px solid var(--border-color); padding-bottom: 0.75rem; font-weight: 700;">Pedido Actual</h3>
                    <div id="pos-cart" style="flex: 1; display: flex; flex-direction: column;"></div>
                </aside>
            </div>
        `;
        window.UI.POS_RenderCatalog();
        window.UI.POS_RenderCart();
    } else if (tabName === 'inventory') {
        mainContent.innerHTML = `
            <div class="layout-container" style="display: block; padding: 2rem;">
                <div id="inventory-container"></div>
            </div>
        `;
        window.UI.Inventory_RenderForm('inventory-container');
    }
};
