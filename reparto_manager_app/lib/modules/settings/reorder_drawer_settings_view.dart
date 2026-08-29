import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import '../../core/preferences_service.dart';

class DrawerMenuItem {
  final int index;
  final IconData icon;
  final String title;

  DrawerMenuItem({required this.index, required this.icon, required this.title});
}

class ReorderDrawerSettingsView extends StatefulWidget {
  const ReorderDrawerSettingsView({super.key});

  @override
  State<ReorderDrawerSettingsView> createState() => _ReorderDrawerSettingsViewState();
}

class _ReorderDrawerSettingsViewState extends State<ReorderDrawerSettingsView> {
  bool _isLoading = true;
  List<DrawerMenuItem> _items = [];

  final List<DrawerMenuItem> _defaultItems = [
    DrawerMenuItem(index: 0, icon: Icons.point_of_sale, title: 'Caja / POS'),
    DrawerMenuItem(index: 1, icon: Icons.inventory_2, title: 'Inventario'),
    DrawerMenuItem(index: 2, icon: Icons.people, title: 'Clientes'),
    DrawerMenuItem(index: 3, icon: Icons.storefront, title: 'Clientes Especiales'),
    DrawerMenuItem(index: 4, icon: Icons.badge, title: 'Revendedores'),
    DrawerMenuItem(index: 5, icon: Icons.sell, title: 'Promociones'),
    DrawerMenuItem(index: 6, icon: Icons.bar_chart, title: 'Reportes'),
    DrawerMenuItem(index: 7, icon: Icons.summarize, title: 'Resumen de Caja'),
    DrawerMenuItem(index: 8, icon: Icons.group_work, title: 'Grupos / Facturación'),
    DrawerMenuItem(index: 9, icon: Icons.local_shipping, title: 'Carga (Camioneta)'),
    DrawerMenuItem(index: 10, icon: Icons.insights, title: 'Estadísticas / Pre-Carga'),
    DrawerMenuItem(index: 11, icon: Icons.settings, title: 'Configuración'),
  ];

  @override
  void initState() {
    super.initState();
    _loadMenuOrder();
  }

  Future<void> _loadMenuOrder() async {
    try {
      // Intentar cargar de Firestore primero (para persistencia entre dispositivos)
      final doc = await FirebaseFirestore.instance.collection('app_settings').doc('drawer_menu_order').get();
      List<int>? savedOrder;

      if (doc.exists && doc.data() != null && doc.data()!['order'] != null) {
        savedOrder = List<int>.from(doc.data()!['order']);
      } else {
        // Si no está en Firestore, intentar del almacenamiento local
        final localStr = PreferencesService().getString('drawer_menu_order');
        if (localStr != null && localStr.isNotEmpty) {
          savedOrder = localStr.split(',').map((e) => int.tryParse(e) ?? -1).where((e) => e != -1).toList();
        }
      }

      if (savedOrder != null && savedOrder.isNotEmpty) {
        List<DrawerMenuItem> ordered = [];
        for (var idx in savedOrder) {
          final found = _defaultItems.firstWhere((item) => item.index == idx, orElse: () => _defaultItems[0]);
          if (!ordered.contains(found)) {
            ordered.add(found);
          }
        }
        // Agregar cualquier item nuevo que falte
        for (var item in _defaultItems) {
          if (!ordered.contains(item)) {
            ordered.add(item);
          }
        }
        _items = ordered;
      } else {
        _items = List.from(_defaultItems);
      }
    } catch (e) {
      _items = List.from(_defaultItems);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveMenuOrder() async {
    final orderIndices = _items.map((e) => e.index).toList();
    
    // 1. Guardar en SharedPreferences local
    await PreferencesService().setString('drawer_menu_order', orderIndices.join(','));

    // 2. Guardar en Firestore para sincronización global (PC, Tablet, Celular)
    try {
      await FirebaseFirestore.instance.collection('app_settings').doc('drawer_menu_order').set({
        'order': orderIndices,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error guardando orden en Firestore: $e");
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Orden del menú lateral guardado y sincronizado correctamente"),
          backgroundColor: Colors.greenAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Organizar Menú Lateral"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: AppTheme.primaryYellow),
            onPressed: _saveMenuOrder,
            tooltip: "Guardar Orden",
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow))
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: AppTheme.surfaceDark,
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.primaryYellow),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Mantené presionado el icono de las líneas a la derecha y arrastrá para cambiar el orden de las opciones del menú.",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    itemCount: _items.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) {
                          newIndex -= 1;
                        }
                        final item = _items.removeAt(oldIndex);
                        _items.insert(newIndex, item);
                      });
                      _saveMenuOrder();
                    },
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        key: ValueKey(item.index),
                        color: AppTheme.surfaceDark,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(item.icon, color: AppTheme.primaryYellow),
                          title: Text(
                            item.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          trailing: const Icon(Icons.drag_handle, color: Colors.grey, size: 28),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
