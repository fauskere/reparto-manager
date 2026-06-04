/**
 * Archivo: scripts/actions/Action_Printer.js
 * Propósito: Generar ticket visual en HTML y usar window.print() nativo.
 */

window.Actions.Printer_ConnectAndPrint = async function(cart, total) {
    if (cart.length === 0) {
        alert("El carrito está vacío.");
        return;
    }

    try {
        if (!navigator.bluetooth) {
            alert("Tu navegador no soporta Web Bluetooth. Asegúrate de usar Chrome.");
            return;
        }

        // 1. Generar comandos ESC/POS puros
        const escposData = window.Actions.ESCPOS.buildTicket(cart, total);

        // 2. Escanear y conectar a la impresora BLE
        const device = await navigator.bluetooth.requestDevice({
            acceptAllDevices: true,
            optionalServices: [
                '49535343-fe7d-4ae5-8fa9-9fafd205e455', // Generic Serial BLE
                'e7810a71-73ae-499d-8c15-faa9aef0c3f2', // Epson BLE
                '000018f0-0000-1000-8000-00805f9b34fb', // Generic Printer
                'afbc9bc9-a78b-49fc-9e32-261274c10000'  // Custom Epson fallback
            ]
        });

        const server = await device.gatt.connect();
        const services = await server.getPrimaryServices();
        let printChar = null;

        // Buscar el canal de escritura (donde se mandan los datos)
        for (const service of services) {
            const characteristics = await service.getCharacteristics();
            for (const char of characteristics) {
                if (char.properties.write || char.properties.writeWithoutResponse) {
                    printChar = char;
                    break;
                }
            }
            if (printChar) break;
        }

        if (!printChar) {
            throw new Error("No se encontró canal de escritura en la impresora.");
        }

        // 3. Enviar datos en pedazos (Chunks) seguros para BLE
        const chunkSize = 256; 
        for (let i = 0; i < escposData.length; i += chunkSize) {
            const chunk = escposData.slice(i, i + chunkSize);
            if (printChar.properties.writeWithoutResponse) {
                await printChar.writeValueWithoutResponse(chunk);
            } else {
                await printChar.writeValue(chunk);
            }
        }

        device.gatt.disconnect();

        // Limpiar el carrito después de mandar a imprimir
        window.Actions.POS_ClearCart();
        if(typeof window.UI.POS_RenderCart === 'function') window.UI.POS_RenderCart();
        
    } catch (error) {
        console.error("Error BLE directo:", error);
        alert("Ocurrió un error en la impresión directa: " + error.message);
    }
};
