import 'package:flutter/material.dart';
import '../pos/pos_view.dart';
import '../inventory/inventory_view.dart';
import '../clients/v2/clients_view_v2.dart';
import '../clients/v2/special_clients_view_v2.dart';
import '../clients/v2/resellers_view_v2.dart';
import '../clients/clients_view.dart';
import '../clients/special_clients_view.dart';
import '../clients/resellers_view.dart';
import '../promotions/promotions_view.dart';
import '../reports/reports_view.dart';
import '../reports/summary_view.dart';
import '../clients/client_groups_view.dart';
import '../settings/settings_view.dart';
import '../truck_load/truck_load_view.dart';
import '../statistics/statistics_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static final GlobalKey<_AppShellState> globalKey = GlobalKey<_AppShellState>();

  static _AppShellState? of(BuildContext context) {
    return context.findAncestorStateOfType<_AppShellState>();
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int currentIndex = 0;

  final List<Widget> _views = [
    const POSView(),
    const InventoryView(),
    const ClientsViewV2(),
    const SpecialClientsViewV2(),
    const ResellersViewV2(),
    const PromotionsView(),
    const ReportsView(),
    const SummaryView(),
    const ClientGroupsView(),
    const TruckLoadView(),
    const StatisticsView(),
    const SettingsView(),
    const ClientsView(),        // 12: Clientes (OLD)
    const SpecialClientsView(), // 13: Clientes Especiales (OLD)
    const ResellersView(),      // 14: Revendedores (OLD)
  ];

  void switchTab(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _views[currentIndex];
  }
}
