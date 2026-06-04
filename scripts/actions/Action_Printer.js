/**
 * Archivo: scripts/actions/Action_Printer.js
 * Propósito: Generar ticket visual en HTML y usar window.print() nativo.
 */

window.Actions.Printer_ConnectAndPrint = function(cart, total) {
    if (cart.length === 0) {
        alert("El carrito está vacío.");
        return;
    }

    try {
        // 1. Generar comandos ESC/POS puros
        const escposData = window.Actions.ESCPOS.buildTicket(cart, total);
        
        // 2. Convertir a Base64
        let binary = '';
        for (let i = 0; i < escposData.byteLength; i++) {
            binary += String.fromCharCode(escposData[i]);
        }
        const base64Data = window.btoa(binary);

        // 3. Crear el intent de RawBT
        const intentUrl = 'intent:' + base64Data + '#Intent;scheme=rawbt;package=ru.a402d.rawbtprinter;end;';

        // 4. Disparar el intent. RawBT se abrirá, conectará, imprimirá y se cerrará en 1 segundo.
        window.location.href = intentUrl;

        // Limpiar el carrito después de mandar a imprimir
        window.Actions.POS_ClearCart();
        if(typeof window.UI.POS_RenderCart === 'function') window.UI.POS_RenderCart();
        
    } catch (error) {
        console.error("Error al generar impresión RawBT:", error);
        alert("Ocurrió un error al preparar la impresión.");
    }
};
