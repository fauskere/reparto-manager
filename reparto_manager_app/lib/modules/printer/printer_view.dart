import 'package:flutter/foundation.dart';
// import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/preferences_service.dart';

class PrinterView extends StatefulWidget {
  const PrinterView({super.key});
  @override
  State<PrinterView> createState() => _PrinterViewState();
}


// @JS('webConnectPrinter')
// external void // _webConnectPrinter();

class _PrinterViewState extends State<PrinterView> {

  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location
    ].request();

    bool? isConnected = await bluetooth.isConnected;
    List<BluetoothDevice> devices = [];
    try {
      devices = await bluetooth.getBondedDevices();
    } catch (e) {
      print("Error obteniendo dispositivos: $e");
    }

    setState(() {
      _devices = devices;
      _connected = isConnected ?? false;
    });
  }

  void _connect() {
    if (_selectedDevice != null) {
      bluetooth.connect(_selectedDevice!).then((_) {
        PreferencesService().setString('printer_mac', _selectedDevice!.address ?? '');
        setState(() => _connected = true);
      }).catchError((error) {
        setState(() => _connected = false);
      });
    }
  }

  void _disconnect() {
    bluetooth.disconnect();
    setState(() => _connected = false);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Configuraci�n de Impresora (Web)')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bluetooth, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text('Impresi�n Bluetooth Web', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Hac� clic en el bot�n de abajo para buscar y conectar tu impresora Bluetooth.', textAlign: TextAlign.center),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.bluetooth_connected),
                label: const Text('Conectar Impresora', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                onPressed: () {
                  // _webConnectPrinter();
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Configuración de Impresora")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Selecciona tu impresora Bluetooth vinculada:", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            DropdownButton<BluetoothDevice>(
              isExpanded: true,
              value: _selectedDevice,
              hint: const Text("Toca aquí para seleccionar"),
              items: _devices.map((e) => DropdownMenuItem<BluetoothDevice>(
                value: e,
                child: Text(e.name ?? "Desconocido"),
              )).toList(),
              onChanged: (device) {
                setState(() => _selectedDevice = device);
              },
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _connected ? null : _connect,
                    child: const Text("Conectar"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _connected ? _disconnect : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16)
                    ),
                    child: const Text("Desconectar"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            if (_connected)
              const Center(
                child: Chip(
                  backgroundColor: Colors.green,
                  label: Text("Impresora Conectada", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
          ],
        ),
      ),
    );
  }
}


