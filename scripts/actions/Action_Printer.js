/**
 * Archivo: scripts/actions/Action_Printer.js
 * Propósito: Generar ticket visual en HTML y usar window.print() nativo.
 */

window.Actions.Printer_ConnectAndPrint = function(cart, total) {
    if (cart.length === 0) {
        alert("El carrito está vacío.");
        return;
    }

    // Crear un iframe oculto para inyectar el diseño del ticket y mandarlo a imprimir
    let iframe = document.getElementById('ticket-printer-frame');
    if (!iframe) {
        iframe = document.createElement('iframe');
        iframe.id = 'ticket-printer-frame';
        iframe.style.position = 'absolute';
        iframe.style.width = '0px';
        iframe.style.height = '0px';
        iframe.style.border = 'none';
        document.body.appendChild(iframe);
    }

    // Construcción del HTML del ticket adaptado a 58mm
    let ticketHTML = `
        <!DOCTYPE html>
        <html>
        <head>
            <title>Imprimir Ticket</title>
            <style>
                @page { 
                    margin: 0; 
                    size: 58mm auto; /* Formato de rollo térmico */
                }
                body { 
                    font-family: monospace; 
                    font-size: 12px; 
                    width: 58mm; /* Ajuste estricto al papel */
                    padding: 5mm; 
                    margin: 0; 
                    color: black; 
                    background: white; 
                    box-sizing: border-box;
                }
                .center { text-align: center; }
                .bold { font-weight: bold; }
                .divider { border-bottom: 1px dashed black; margin: 8px 0; }
                table { width: 100%; border-collapse: collapse; font-size: 11px; }
                td { vertical-align: top; padding-bottom: 4px; }
                .price { text-align: right; }
            </style>
        </head>
        <body>
            <div class="center bold" style="font-size: 16px; margin-bottom: 5px;">REPARTO MANAGER</div>
            <div class="center">Comprobante de Venta</div>
            <div class="divider"></div>
            <div>Fecha: ${new Date().toLocaleString()}</div>
            <div class="divider"></div>
            <table>
    `;

    cart.forEach(item => {
        ticketHTML += `
            <tr>
                <td style="padding-right: 4px;">${item.quantity}x ${item.name}</td>
                <td class="price">$${(item.price * item.quantity).toFixed(2)}</td>
            </tr>
        `;
    });

    ticketHTML += `
            </table>
            <div class="divider"></div>
            <table class="bold" style="font-size: 14px;">
                <tr>
                    <td>TOTAL:</td>
                    <td class="price">$${total.toFixed(2)}</td>
                </tr>
            </table>
            <div class="center" style="margin-top: 15px;">¡Gracias por su compra!</div>
            <div style="height: 10mm;"></div> <!-- Margen inferior para corte -->
        </body>
        </html>
    `;

    const doc = iframe.contentWindow.document;
    doc.open();
    doc.write(ticketHTML);
    doc.close();

    // Esperar medio segundo para asegurar que el navegador renderizó el HTML, y lanzar impresión
    setTimeout(() => {
        iframe.contentWindow.focus();
        iframe.contentWindow.print();
        
        // Limpiamos carrito tras enviar orden de impresión
        window.Actions.POS_ClearCart();
        if(typeof window.UI.POS_RenderCart === 'function') window.UI.POS_RenderCart();
    }, 500);
};
