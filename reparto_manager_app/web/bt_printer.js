let btDevice;
let btServer;
let btService;
let btCharacteristic;
let printQueue = [];
let isPrinting = false;

// Configuración de la impresora térmica
// Múltiples UUIDs comunes por si no es 18f0
const SERVICE_UUIDS = ['000018f0-0000-1000-8000-00805f9b34fb', '0000fee7-0000-1000-8000-00805f9b34fb', 'e7810a71-73ae-499d-8c15-faa9aef0c3f2', '49535343-fe7d-4ae5-8fa9-9fafd205e455', '0000ffe0-0000-1000-8000-00805f9b34fb', '0000fff0-0000-1000-8000-00805f9b34fb']; 

async function connectToBluetoothPrinter() {
  if (btDevice && btDevice.gatt.connected) {
    return true;
  }
  
  try {
    btDevice = await navigator.bluetooth.requestDevice({
      acceptAllDevices: true,
      optionalServices: SERVICE_UUIDS
    });

    btDevice.addEventListener('gattserverdisconnected', () => {
      console.log('Bluetooth printer disconnected.');
    });

    btServer = await btDevice.gatt.connect();
    
    // Buscar el servicio válido
    const services = await btServer.getPrimaryServices();
    btService = services.find(s => SERVICE_UUIDS.includes(s.uuid));
    
    if (!btService) {
      alert('Error: Ningun servicio compatible encontrado. UUIDs buscados: ' + SERVICE_UUIDS.join(', ')); console.error('Compatible service not found');
      return false;
    }
    
    // Obtenemos la característica de escritura
    const characteristics = await btService.getCharacteristics();
    btCharacteristic = characteristics.find(c => c.properties.write || c.properties.writeWithoutResponse);
    
    if (!btCharacteristic) {
      alert('Error: Servicio encontrado pero no se puede escribir.'); console.error('No writable characteristic found');
      return false;
    }
    
    return true;
  } catch (error) {
    alert('Error de conexion Bluetooth: ' + error); console.error('Connection failed!', error);
    return false;
  }
}

async function sendBytesToPrinter(bytes) {
  if (!btDevice || !btDevice.gatt.connected) {
    let connected = await connectToBluetoothPrinter();
    if (!connected) return false;
  }
  
  try {
    const CHUNK_SIZE = 100;
    for (let i = 0; i < bytes.length; i += CHUNK_SIZE) {
      const chunk = bytes.slice(i, i + CHUNK_SIZE);
      await btCharacteristic.writeValue(new Uint8Array(chunk));
    }
    return true;
  } catch (error) {
    console.error('Print failed!', error);
    return false;
  }
}

// Interfaz para Dart
window.webPrintCustom = function(text, size, align) {
  // ESC/POS Align: 0=Left, 1=Center, 2=Right
  let alignCmd = [0x1B, 0x61, align]; 
  
  // ESC/POS Size: 0=Normal, 1=Double Height, 2=Double Width/Height
  let sizeCmd = [0x1D, 0x21, 0x00]; 
  if (size === 1) sizeCmd = [0x1D, 0x21, 0x01]; // Double height
  if (size === 2) sizeCmd = [0x1D, 0x21, 0x11]; // Double width & height
  
  let textBytes = new TextEncoder().encode(text + '\n');
  let data = [...alignCmd, ...sizeCmd, ...textBytes];
  printQueue.push(data);
  processQueue();
};

window.webPrintNewLine = function() {
  printQueue.push([0x0A]);
  processQueue();
};

window.webPaperCut = function() {
  // Comando de corte ESC/POS
  printQueue.push([0x1D, 0x56, 0x41, 0x00]);
  processQueue();
};

async function processQueue() {
  if (isPrinting || printQueue.length === 0) return;
  isPrinting = true;
  
  let allBytes = [];
  while(printQueue.length > 0) {
    allBytes.push(...printQueue.shift());
  }
  
  await sendBytesToPrinter(allBytes);
  isPrinting = false;
}

window.webConnectPrinter = async function() {
  try {
    await connectToBluetoothPrinter();
    console.log('Printer connected successfully from config');
  } catch (e) {
    console.error('Failed to connect printer from config', e);
  }
};





window.webPrintHtml = function(htmlContent) {
  const printWindow = window.open('', '_blank');
  if (!printWindow) {
    alert("El navegador bloque� la ventana emergente. Por favor permite los popups para imprimir.");
    return;
  }
  printWindow.document.write(
    <html>
      <head>
        <title>Ticket</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { 
            font-family: monospace; 
            font-size: 12px; 
            width: 100%;
            max-width: 58mm; 
            margin: 0 auto; 
            padding: 10px; 
            color: black; 
            background: white; 
          }
          .align-1 { text-align: center; }
          .align-0 { text-align: left; }
          .align-2 { text-align: right; }
          .size-2 { font-size: 18px; font-weight: bold; }
          .size-1 { font-size: 14px; font-weight: bold; }
          .size-0 { font-size: 12px; }
          .row { display: flex; justify-content: space-between; width: 100%; }
        </style>
      </head>
      <body>
         + htmlContent + 
      </body>
    </html>
  );
  printWindow.document.close();
  printWindow.focus();
  setTimeout(() => {
    printWindow.print();
    printWindow.close();
  }, 500);
};
