/**
 * Archivo: scripts/actions/Action_Printer.js
 * Propósito: Conexión Web Bluetooth para enviar el ticket a la impresora.
 */

window.Actions.Printer_State = {
    device: null,
    characteristic: null
};

window.Actions.Printer_ConnectAndPrint = async function(cart, total) {
    if (!navigator.bluetooth) {
        alert("Tu navegador no soporta Bluetooth Web. Usa Chrome en tu tablet Android.");
        return;
    }

    if (cart.length === 0) {
        alert("El carrito está vacío.");
        return;
    }

    try {
        if (!window.Actions.Printer_State.device || !window.Actions.Printer_State.device.gatt.connected) {
            console.log("Solicitando dispositivo Bluetooth...");
            const device = await navigator.bluetooth.requestDevice({
                acceptAllDevices: true,
                optionalServices: ['000018f0-0000-1000-8000-00805f9b34fb', 'e7810a71-73ae-499d-8c15-faa9aef0c3f2', '00001801-0000-1000-8000-00805f9b34fb']
            });

            const server = await device.gatt.connect();
            const services = await server.getPrimaryServices();
            let writeChar = null;
            
            for (let service of services) {
                const characteristics = await service.getCharacteristics();
                for (let char of characteristics) {
                    if (char.properties.write || char.properties.writeWithoutResponse) {
                        writeChar = char;
                        break;
                    }
                }
                if (writeChar) break;
            }

            if (!writeChar) {
                throw new Error("No se encontró capacidad de escritura en esta impresora.");
            }

            window.Actions.Printer_State.device = device;
            window.Actions.Printer_State.characteristic = writeChar;
        }

        const bytes = window.Actions.ESCPOS.buildTicket(cart, total);
        
        const CHUNK_SIZE = 512;
        for (let i = 0; i < bytes.length; i += CHUNK_SIZE) {
            const chunk = bytes.slice(i, i + CHUNK_SIZE);
            if (window.Actions.Printer_State.characteristic.properties.writeWithoutResponse) {
                await window.Actions.Printer_State.characteristic.writeValueWithoutResponse(chunk);
            } else {
                await window.Actions.Printer_State.characteristic.writeValue(chunk);
            }
        }
        
        alert("¡Ticket enviado a la impresora!");
        window.Actions.POS_ClearCart();
        window.UI.POS_RenderCart();

    } catch (error) {
        console.error("Error de impresión:", error);
        alert("Error de conexión: " + error.message);
    }
};
