import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import '../../core/preferences_service.dart';
import 'app_shell.dart';
import '../clients/price_catalog_view.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final Map<int, Map<String, dynamic>> _allMenuItems = {
    0: {'title': 'Caja / POS', 'icon': Icons.point_of_sale},
    1: {'title': 'Inventario', 'icon': Icons.inventory_2},
    2: {'title': 'Clientes', 'icon': Icons.people},
    3: {'title': 'Clientes Especiales', 'icon': Icons.storefront},
    4: {'title': 'Revendedores', 'icon': Icons.badge},
    5: {'title': 'Promociones', 'icon': Icons.sell},
    6: {'title': 'Reportes', 'icon': Icons.bar_chart},
    7: {'title': 'Resumen de Caja', 'icon': Icons.summarize},
    8: {'title': 'Grupos / Facturación', 'icon': Icons.group_work},
    9: {'title': 'Carga (Camioneta)', 'icon': Icons.local_shipping},
    10: {'title': 'Estadísticas / Pre-Carga', 'icon': Icons.insights},
    11: {'title': 'Configuración', 'icon': Icons.settings},
  };

  List<int> _itemOrder = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

  @override
  void initState() {
    super.initState();
    _loadSavedOrder();
  }

  void _loadSavedOrder() {
    // 1. Cargar local primero
    final localStr = PreferencesService().getString('drawer_menu_order');
    if (localStr != null && localStr.isNotEmpty) {
      final parsed = localStr.split(',').map((e) => int.tryParse(e) ?? -1).where((e) => _allMenuItems.containsKey(e)).toList();
      if (parsed.isNotEmpty) {
        // Completar faltantes si los hay
        for (var k in _allMenuItems.keys) {
          if (!parsed.contains(k)) parsed.add(k);
        }
        setState(() {
          _itemOrder = parsed;
        });
      }
    }

    // 2. Escuchar cambios de Firestore para estar sincronizados entre dispositivos
    FirebaseFirestore.instance.collection('app_settings').doc('drawer_menu_order').snapshots().listen((snap) {
      if (snap.exists && snap.data() != null && snap.data()!['order'] != null) {
        final List<dynamic> firestoreOrder = snap.data()!['order'];
        final parsed = firestoreOrder.map((e) => (e as num).toInt()).where((e) => _allMenuItems.containsKey(e)).toList();
        for (var k in _allMenuItems.keys) {
          if (!parsed.contains(k)) parsed.add(k);
        }
        if (mounted) {
          setState(() {
            _itemOrder = parsed;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final shellState = AppShell.of(context);
    final currentIndex = shellState?.currentIndex ?? 0;

    Widget buildItem(int index, IconData icon, String title) {
      final isSelected = currentIndex == index;
      return ListTile(
        leading: Icon(
          icon, 
          color: isSelected ? AppTheme.primaryYellow : AppTheme.textSecondary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryYellow : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        selected: isSelected,
        selectedTileColor: AppTheme.primaryYellow.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
          shellState?.switchTab(index);
        },
      );
    }

    return Drawer(
      backgroundColor: AppTheme.backgroundDark,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              width: double.infinity,
              color: AppTheme.surfaceDark,
              child: Column(
                children: [
                  Image.asset(
                    'assets/Logo_small.png',
                    height: 80,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.storefront, color: AppTheme.primaryYellow, size: 80),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "María Belén",
                    style: TextStyle(
                      color: AppTheme.primaryYellow,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Sistema de Gestión",
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: ListView(
                  children: [
                    for (int idx in _itemOrder) ...[
                      buildItem(idx, _allMenuItems[idx]!['icon'] as IconData, _allMenuItems[idx]!['title'] as String),
                      const SizedBox(height: 4),
                    ],
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24, indent: 16, endIndent: 16),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.price_change_outlined, color: AppTheme.textSecondary),
                      title: const Text('Catálogo de Precios', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onTap: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PriceCatalogView()));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
