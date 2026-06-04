/**
 * Archivo: scripts/actions/Action_Inventory.js
 * Propósito: Lógica de negocio para manejar los productos (Inventario).
 */

window.Actions.Inventory_AddProduct = function(name, price, image = null) {
    if (!name || !price || isNaN(price)) return false;
    
    let products = window.Actions.Inventory_GetProducts();
    const newProduct = {
        id: Date.now().toString(),
        name: name,
        price: parseFloat(price),
        image: image || ''
    };
    
    products.push(newProduct);
    localStorage.setItem('reparto_inventory', JSON.stringify(products));
    return true;
};

window.Actions.Inventory_GetProducts = function() {
    const data = localStorage.getItem('reparto_inventory');
    return data ? JSON.parse(data) : [];
};

window.Actions.Inventory_DeleteProduct = function(id) {
    let products = window.Actions.Inventory_GetProducts();
    products = products.filter(p => p.id !== id);
    localStorage.setItem('reparto_inventory', JSON.stringify(products));
};
