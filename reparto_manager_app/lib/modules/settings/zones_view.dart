import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import '../shell/app_drawer.dart';
import '../clients/v2/clients_actions_v2.dart';

class Zone {
  final String id;
  final String name;
  final List<String> cities;

  Zone({required this.id, required this.name, required this.cities});

  factory Zone.fromDocument(DocumentSnapshot doc) {
    return Zone(
      id: doc.id,
      name: doc['name'] ?? '',
      cities: List<String>.from(doc['cities'] ?? []),
    );
  }
}

class ZonesView extends StatefulWidget {
  const ZonesView({super.key});

  @override
  State<ZonesView> createState() => _ZonesViewState();
}

class _ZonesViewState extends State<ZonesView> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void _showZoneDialog([Zone? zone]) {
    final nameCtrl = TextEditingController(text: zone?.name ?? '');
    
    // Extraer todas las ciudades únicas de los clientes
    final allClients = ClientsActionsV2().allClients;
    final Set<String> uniqueCities = {};
    for (var c in allClients) {
      if (c.city.trim().isNotEmpty) {
        uniqueCities.add(c.city.trim());
      }
    }
    
    List<String> sortedCities = uniqueCities.toList()..sort();
    List<String> selectedCities = List<String>.from(zone?.cities ?? []);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              title: Text(zone == null ? 'Nueva Zona' : 'Editar Zona', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre de la Zona (Ej: Lunes)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Selecciona las ciudades:', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: sortedCities.isEmpty 
                        ? const Text("No hay ciudades registradas en los clientes.", style: TextStyle(color: AppTheme.textSecondary))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: sortedCities.length,
                            itemBuilder: (context, index) {
                              final city = sortedCities[index];
                              final isSelected = selectedCities.contains(city);
                              return CheckboxListTile(
                                activeColor: AppTheme.primaryYellow,
                                checkColor: Colors.black,
                                title: Text(city),
                                value: isSelected,
                                onChanged: (val) {
                                  setStateDialog(() {
                                    if (val == true) {
                                      selectedCities.add(city);
                                    } else {
                                      selectedCities.remove(city);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;

                    if (zone == null) {
                      await _db.collection('zones').add({
                        'name': name,
                        'cities': selectedCities,
                      });
                    } else {
                      await _db.collection('zones').doc(zone.id).update({
                        'name': name,
                        'cities': selectedCities,
                      });
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Guardar', style: TextStyle(color: Colors.black)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  void _deleteZone(Zone zone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Eliminar Zona'),
        content: Text('¿Seguro que quieres eliminar la zona ${zone.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              _db.collection('zones').doc(zone.id).delete();
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zonas de Reparto'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showZoneDialog(),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('zones').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final zones = snapshot.data!.docs.map((d) => Zone.fromDocument(d)).toList();

          if (zones.isEmpty) {
            return const Center(child: Text("No hay zonas creadas.", style: TextStyle(color: AppTheme.textSecondary)));
          }

          return ListView.builder(
            itemCount: zones.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final zone = zones[index];
              return Card(
                color: AppTheme.surfaceDark,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(zone.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryYellow)),
                  subtitle: Text(zone.cities.join(', '), style: const TextStyle(color: AppTheme.textSecondary)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: () => _showZoneDialog(zone)),
                      IconButton(icon: const Icon(Icons.delete, color: AppTheme.danger), onPressed: () => _deleteZone(zone)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
