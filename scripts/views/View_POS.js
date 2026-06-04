/**
 * Archivo: scripts/views/View_POS.js
 * Propósito: Interfaz del Punto de Venta (Catálogo y carrito).
 */

window.UI.POS_RenderCatalog = function() {
    const container = document.getElementById('pos-catalog');
    if (!container) return;

    const products = window.Actions.Inventory_GetProducts();
    
    if (products.length === 0) {
        container.innerHTML = `
            <div class="glass-panel" style="padding: 2rem; text-align: center; color: var(--text-secondary);">
                <p>No hay productos disponibles.</p>
                <p style="font-size: 0.9rem; margin-top: 0.5rem;">Ve a la sección "Inventario" para cargar tus productos.</p>
            </div>
        `;
        return;
    }

    let html = `<div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(140px, 1fr)); gap: 1rem;">`;
    products.forEach(p => {
        html += `
            <div class="glass-panel" style="padding: 1rem; cursor: pointer; transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1); display: flex; flex-direction: column; justify-content: space-between;" onmouseover="this.style.transform='translateY(-4px)'; this.style.borderColor='var(--accent)'" onmouseout="this.style.transform='translateY(0)'; this.style.borderColor='var(--border-color)'" onclick="window.UI.POS_HandleAddToCart('${p.id}')">
                <h4 style="margin-bottom: 0.5rem; font-size: 0.95rem; line-height: 1.2;">${p.name}</h4>
                <div style="margin-top: auto;">
                    <p style="color: var(--accent); font-weight: 700; font-size: 1.1rem; margin-bottom: 0.75rem;">$${p.price.toFixed(2)}</p>
                    <div style="background: rgba(59, 130, 246, 0.1); text-align: center; border-radius: var(--radius-md); padding: 0.4rem; font-size: 0.85rem; font-weight: 600; color: var(--accent); display: flex; justify-content: center; align-items: center; gap: 0.25rem;">
                        <span>Agregar</span>
                        <span style="font-size: 1.1rem;">+</span>
                    </div>
                </div>
            </div>
        `;
    });
    html += `</div>`;
    container.innerHTML = html;
};

window.UI.POS_RenderCart = function() {
    const container = document.getElementById('pos-cart');
    if (!container) return;

    const cart = window.Actions.POS_State.cart;
    const total = window.Actions.POS_GetTotal();

    if (cart.length === 0) {
        container.innerHTML = `
            <div style="text-align: center; color: var(--text-secondary); padding: 3rem 1rem; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100%;">
                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="opacity: 0.3; margin-bottom: 1rem;"><circle cx="9" cy="21" r="1"></circle><circle cx="20" cy="21" r="1"></circle><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path></svg>
                <p>El pedido está vacío</p>
                <p style="font-size: 0.85rem; margin-top: 0.5rem; opacity: 0.7;">Toca un producto del catálogo para agregarlo</p>
            </div>
        `;
        return;
    }

    let html = `<div style="display: flex; flex-direction: column; gap: 0.75rem; max-height: calc(100vh - 300px); overflow-y: auto; margin-bottom: 1rem; padding-right: 0.5rem; flex: 1;">`;
    cart.forEach(item => {
        html += `
            <div style="display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border-color); padding-bottom: 0.75rem;">
                <div style="flex: 1; padding-right: 0.5rem;">
                    <p style="font-weight: 600; font-size: 0.95rem; margin-bottom: 0.2rem;">${item.name}</p>
                    <p style="color: var(--text-secondary); font-size: 0.85rem;">${item.quantity} x $${item.price.toFixed(2)}</p>
                </div>
                <div style="display: flex; align-items: center; gap: 0.75rem;">
                    <p style="font-weight: 700; color: var(--text-primary); font-size: 1.05rem;">$${(item.price * item.quantity).toFixed(2)}</p>
                    <button onclick="window.UI.POS_HandleRemove('${item.id}')" style="background: var(--bg-secondary); color: var(--danger); border: 1px solid var(--border-color); border-radius: 50%; width: 28px; height: 28px; cursor: pointer; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 1.1rem; transition: background 0.2s;" onmouseover="this.style.background='var(--danger)'; this.style.color='white'" onmouseout="this.style.background='var(--bg-secondary)'; this.style.color='var(--danger)'">×</button>
                </div>
            </div>
        `;
    });
    html += `</div>`;

    html += `
        <div style="border-top: 2px dashed var(--border-color); padding-top: 1.5rem; margin-top: auto;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem;">
                <span style="font-size: 1.25rem; font-weight: 600; color: var(--text-secondary);">Total</span>
                <span style="font-size: 1.75rem; font-weight: 800; color: var(--success);">$${total.toFixed(2)}</span>
            </div>
            <button style="width: 100%; padding: 1.25rem; background: var(--success); color: white; border: none; border-radius: var(--radius-lg); font-size: 1.1rem; font-weight: 700; cursor: pointer; box-shadow: 0 4px 14px 0 rgba(16, 185, 129, 0.39); transition: transform 0.1s;" onmousedown="this.style.transform='scale(0.98)'" onmouseup="this.style.transform='scale(1)'">
                Cobrar e Imprimir Ticket
            </button>
            <button onclick="window.UI.POS_HandleClear()" style="width: 100%; padding: 0.75rem; margin-top: 0.75rem; background: transparent; color: var(--danger); border: 1px solid rgba(239, 68, 68, 0.3); border-radius: var(--radius-lg); font-weight: 600; cursor: pointer; transition: background 0.2s;" onmouseover="this.style.background='rgba(239, 68, 68, 0.1)'" onmouseout="this.style.background='transparent'">
                Cancelar Pedido
            </button>
        </div>
    `;

    container.innerHTML = html;
};

window.UI.POS_HandleAddToCart = function(productId) {
    window.Actions.POS_AddToCart(productId);
    window.UI.POS_RenderCart();
};

window.UI.POS_HandleRemove = function(productId) {
    window.Actions.POS_RemoveFromCart(productId);
    window.UI.POS_RenderCart();
};

window.UI.POS_HandleClear = function() {
    if (confirm("¿Estás seguro de que quieres limpiar todo el pedido actual?")) {
        window.Actions.POS_ClearCart();
        window.UI.POS_RenderCart();
    }
};
