/**
 * Archivo: scripts/views/View_Inventory.js
 * Propósito: Interfaz para agregar y ver productos del inventario.
 */

window.UI.Inventory_RenderForm = function(containerId) {
    const container = document.getElementById(containerId);
    if (!container) return;

    container.innerHTML = `
        <div class="inventory-form glass-panel" style="padding: 1.5rem; margin-bottom: 1.5rem;">
            <h3>Agregar Nuevo Producto</h3>
            <div style="margin-top: 1rem; display: flex; gap: 1rem; flex-wrap: wrap;">
                <input type="text" id="inv-name" placeholder="Nombre del producto" style="flex: 1; min-width: 200px; padding: 0.75rem; border-radius: var(--radius-md); border: 1px solid var(--border-color); background: var(--bg-secondary); color: var(--text-primary); font-size: 1rem;">
                <input type="number" id="inv-price" placeholder="Precio ($)" style="width: 120px; padding: 0.75rem; border-radius: var(--radius-md); border: 1px solid var(--border-color); background: var(--bg-secondary); color: var(--text-primary); font-size: 1rem;">
                <button onclick="window.UI.Inventory_HandleSubmit()" style="padding: 0.75rem 1.5rem; background: var(--success); color: white; border: none; border-radius: var(--radius-md); cursor: pointer; font-weight: 600; font-size: 1rem; box-shadow: var(--shadow-sm);">Agregar</button>
            </div>
            <div id="inv-message" style="margin-top: 0.5rem; font-size: 0.875rem; font-weight: 500;"></div>
        </div>
        <div id="inv-list"></div>
    `;
    
    window.UI.Inventory_RenderList();
};

window.UI.Inventory_HandleSubmit = function() {
    const nameInput = document.getElementById('inv-name');
    const priceInput = document.getElementById('inv-price');
    const msg = document.getElementById('inv-message');

    const success = window.Actions.Inventory_AddProduct(nameInput.value, priceInput.value);
    
    if (success) {
        msg.textContent = "¡Producto agregado al inventario!";
        msg.style.color = "var(--success)";
        nameInput.value = '';
        priceInput.value = '';
        setTimeout(() => msg.textContent = '', 2500);
        
        window.UI.Inventory_RenderList();
        if (typeof window.UI.POS_RenderCatalog === 'function') window.UI.POS_RenderCatalog();
    } else {
        msg.textContent = "Error: Verifica que el nombre y el precio sean válidos.";
        msg.style.color = "var(--danger)";
    }
};

window.UI.Inventory_RenderList = function() {
    const listContainer = document.getElementById('inv-list');
    if (!listContainer) return;

    const products = window.Actions.Inventory_GetProducts();
    
    if (products.length === 0) {
        listContainer.innerHTML = `
            <div class="glass-panel" style="padding: 2rem; text-align: center; color: var(--text-secondary);">
                <p>El inventario está vacío. Agrega tu primer producto arriba.</p>
            </div>
        `;
        return;
    }

    let html = `<div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 1rem;">`;
    products.forEach(p => {
        html += `
            <div class="glass-panel" style="padding: 1.5rem; position: relative;">
                <h4 style="margin-bottom: 0.5rem; padding-right: 1.5rem; word-break: break-word;">${p.name}</h4>
                <p style="color: var(--accent); font-weight: 700; font-size: 1.2rem;">$${p.price.toFixed(2)}</p>
                <button onclick="window.UI.Inventory_HandleDelete('${p.id}')" style="position: absolute; top: 0.75rem; right: 0.75rem; background: var(--bg-secondary); color: var(--danger); border: 1px solid var(--border-color); border-radius: var(--radius-md); padding: 0.2rem 0.5rem; cursor: pointer; font-size: 0.8rem; transition: background 0.2s;" onmouseover="this.style.background='var(--danger)'; this.style.color='white'" onmouseout="this.style.background='var(--bg-secondary)'; this.style.color='var(--danger)'">Eliminar</button>
            </div>
        `;
    });
    html += `</div>`;
    listContainer.innerHTML = html;
};

window.UI.Inventory_HandleDelete = function(id) {
    if (confirm("¿Estás seguro de eliminar este producto del inventario?")) {
        window.Actions.Inventory_DeleteProduct(id);
        window.UI.Inventory_RenderList();
        if (typeof window.UI.POS_RenderCatalog === 'function') window.UI.POS_RenderCatalog();
    }
};
