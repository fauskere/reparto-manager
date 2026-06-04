/**
 * Archivo: scripts/actions/Action_Inventory.js
 * Propósito: Lógica de negocio para manejar productos sincronizados con Firebase.
 */

window.Actions.Inventory_State = {
    products: []
};

// Escuchar en tiempo real a Firebase
window.Actions.Inventory_Listen = function(onUpdateCallback) {
    const db = window.Actions.DB;
    // Escuchamos la colección "products" ordenada por nombre
    db.collection("products").orderBy("name").onSnapshot((snapshot) => {
        window.Actions.Inventory_State.products = [];
        snapshot.forEach((doc) => {
            window.Actions.Inventory_State.products.push({
                id: doc.id,
                ...doc.data()
            });
        });
        if (onUpdateCallback) onUpdateCallback();
    }, (error) => {
        console.error("Error escuchando el inventario:", error);
    });
};

window.Actions.Inventory_AddProduct = async function(name, price, image = null) {
    if (!name || !price || isNaN(price)) return false;
    
    const db = window.Actions.DB;
    try {
        await db.collection("products").add({
            name: name,
            price: parseFloat(price),
            image: image || '',
            createdAt: firebase.firestore.FieldValue.serverTimestamp()
        });
        return true;
    } catch (e) {
        console.error("Error agregando producto: ", e);
        return false;
    }
};

window.Actions.Inventory_GetProducts = function() {
    return window.Actions.Inventory_State.products;
};

window.Actions.Inventory_DeleteProduct = async function(id) {
    const db = window.Actions.DB;
    try {
        await db.collection("products").doc(id).delete();
    } catch (e) {
        console.error("Error eliminando producto: ", e);
    }
};
