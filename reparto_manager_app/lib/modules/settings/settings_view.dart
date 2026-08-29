import 'package:flutter/material.dart';
import '../../core/app_config.dart';
import '../../core/theme.dart';
import '../clients/clients_view.dart';
import '../clients/special_clients_view.dart';
import '../clients/resellers_view.dart';
import '../printer/printer_view.dart';
import '../shell/app_drawer.dart';
import '../truck_load/truck_load_actions.dart';
import 'global_ledger_view.dart';
import 'zones_view.dart';
import 'reorder_drawer_settings_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  void _showOldModulesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_edu, color: AppTheme.primaryYellow, size: 24),
                    SizedBox(width: 8),
                    Text("Módulos OLD (Legado)", style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Accedé a las versiones anteriores de las pantallas de clientes para consultar historiales antiguos.",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.people_outline, color: Colors.white),
                  title: const Text("Clientes (OLD)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text("Módulo antiguo de clientes comunes", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.primaryYellow),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientsView()));
                  },
                ),
                const Divider(color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.storefront_outlined, color: Colors.white),
                  title: const Text("Clientes Especiales (OLD)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text("Módulo antiguo de clientes especiales", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.primaryYellow),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SpecialClientsView()));
                  },
                ),
                const Divider(color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.badge_outlined, color: Colors.white),
                  title: const Text("Revendedores (OLD)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text("Módulo antiguo de revendedores", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.primaryYellow),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ResellersView()));
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("CERRAR", style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        elevation: 0,
        title: const Text("Configuración"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            Card(
              child: ListTile(
                leading: const Icon(Icons.print, color: AppTheme.primaryYellow, size: 32),
                title: const Text("Impresora Bluetooth", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Conectar o cambiar la impresora de recibos"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PrinterView()));
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.history_edu, color: AppTheme.primaryYellow, size: 32),
                title: const Text("Auditoría Global de Saldos", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Ver el historial completo de cambios en saldos de clientes"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const GlobalLedgerView()));
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.reorder, color: AppTheme.primaryYellow, size: 32),
                title: const Text("Organizar Menú Lateral", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Reordenar arrastrando las opciones del menú de navegación"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ReorderDrawerSettingsView()));
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.map, color: AppTheme.primaryYellow, size: 32),
                title: const Text("Zonas de Reparto", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Gestionar zonas y ciudades asignadas"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ZonesView()));
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.local_shipping, color: AppTheme.primaryYellow, size: 32),
                title: const Text("Vehículo Activo", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(TruckLoadActions().activeTruckId),
                trailing: const Icon(Icons.edit),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      final ctrl = TextEditingController(text: TruckLoadActions().activeTruckId);
                      return AlertDialog(
                        backgroundColor: AppTheme.surfaceDark,
                        title: const Text("Vehículo Activo", style: TextStyle(fontWeight: FontWeight.bold)),
                        content: TextField(
                          controller: ctrl,
                          decoration: const InputDecoration(labelText: "ID del Vehículo", border: OutlineInputBorder()),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
                          ElevatedButton(
                            onPressed: () {
                              TruckLoadActions().setActiveTruck(ctrl.text.trim());
                              setState(() {});
                              Navigator.pop(context);
                            },
                            child: const Text("Guardar", style: TextStyle(color: Colors.black)),
                          ),
                        ],
                      );
                    }
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // OPCIÓN MÓDULOS OLD (UBICADA ARRIBA DE ACERCA DE LA APLICACIÓN)
            Card(
              child: ListTile(
                leading: const Icon(Icons.history_toggle_off, color: AppTheme.primaryYellow, size: 32),
                title: const Text("Módulos OLD", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Acceder a las versiones anteriores de clientes y revendedores"),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showOldModulesDialog,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline, color: AppTheme.primaryYellow, size: 32),
                title: const Text("Acerca de la Aplicación", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Versión instalada en el dispositivo"),
                trailing: Text(AppConfig.version, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
