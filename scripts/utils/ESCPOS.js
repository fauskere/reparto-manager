/**
 * Archivo: scripts/utils/ESCPOS.js
 * Propósito: Generador de comandos ESC/POS para impresoras térmicas.
 */

window.Actions.ESCPOS = {
    CMD: {
        INIT: [0x1B, 0x40],
        ALIGN_LEFT: [0x1B, 0x61, 0x00],
        ALIGN_CENTER: [0x1B, 0x61, 0x01],
        ALIGN_RIGHT: [0x1B, 0x61, 0x02],
        BOLD_ON: [0x1B, 0x45, 0x01],
        BOLD_OFF: [0x1B, 0x45, 0x00],
        TEXT_NORMAL: [0x1D, 0x21, 0x00],
        TEXT_DOUBLE_HEIGHT: [0x1D, 0x21, 0x01],
        TEXT_DOUBLE_WIDTH: [0x1D, 0x21, 0x10],
        TEXT_DOUBLE_BOTH: [0x1D, 0x21, 0x11],
        CUT_PAPER: [0x1D, 0x56, 0x41, 0x00],
        NEW_LINE: [0x0A]
    },
    
    PAPER_WIDTH: 32, // Estándar 58mm
    
    encoder: new TextEncoder(),

    buildTicket: function(cart, total) {
        let buffer = [];
        
        const add = (cmd) => buffer.push(...cmd);
        const addText = (text) => buffer.push(...this.encoder.encode(text));
        
        // Inicializar
        add(this.CMD.INIT);
        
        // Cabecera
        add(this.CMD.ALIGN_CENTER);
        add(this.CMD.TEXT_DOUBLE_BOTH);
        add(this.CMD.BOLD_ON);
        addText("REPARTO MANAGER\n");
        add(this.CMD.BOLD_OFF);
        add(this.CMD.TEXT_NORMAL);
        addText("Comprobante de Venta\n");
        addText("--------------------------------\n");
        
        // Fecha
        add(this.CMD.ALIGN_LEFT);
        addText("Fecha: " + new Date().toLocaleString() + "\n");
        addText("--------------------------------\n");
        
        // Productos
        cart.forEach(item => {
            let line = `${item.quantity}x ${item.name}`;
            let price = `$${(item.price * item.quantity).toFixed(2)}`;
            
            if (line.length + price.length > this.PAPER_WIDTH) {
                line = line.substring(0, this.PAPER_WIDTH - price.length - 1);
            }
            let spaces = this.PAPER_WIDTH - line.length - price.length;
            addText(line + " ".repeat(Math.max(0, spaces)) + price + "\n");
        });
        
        addText("--------------------------------\n");
        
        // Total
        add(this.CMD.ALIGN_RIGHT);
        add(this.CMD.TEXT_DOUBLE_HEIGHT);
        add(this.CMD.BOLD_ON);
        addText(`TOTAL: $${total.toFixed(2)}\n`);
        add(this.CMD.BOLD_OFF);
        add(this.CMD.TEXT_NORMAL);
        
        // Pie
        add(this.CMD.ALIGN_CENTER);
        addText("\nGracias por su compra!\n");
        
        // Espaciado y corte
        addText("\n\n\n\n");
        add(this.CMD.CUT_PAPER);
        
        return new Uint8Array(buffer);
    }
};
