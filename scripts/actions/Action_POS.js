/**
 * Archivo: scripts/actions/Action_POS.js
 * Propósito: Lógica de negocio del POS (Carrito, cuentas).
 */

window.Actions.POS_State = {
    cart: []
};

window.Actions.POS_AddToCart = function(productId) {
    const products = window.Actions.Inventory_GetProducts();
    const product = products.find(p => p.id === productId);
    if (!product) return;

    const existing = window.Actions.POS_State.cart.find(item => item.id === productId);
    if (existing) {
        existing.quantity += 1;
    } else {
        window.Actions.POS_State.cart.push({
            ...product,
            quantity: 1
        });
    }
};

window.Actions.POS_RemoveFromCart = function(productId) {
    window.Actions.POS_State.cart = window.Actions.POS_State.cart.filter(item => item.id !== productId);
};

window.Actions.POS_ClearCart = function() {
    window.Actions.POS_State.cart = [];
};

window.Actions.POS_GetTotal = function() {
    return window.Actions.POS_State.cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);
};
