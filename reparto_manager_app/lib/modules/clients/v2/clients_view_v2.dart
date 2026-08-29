import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../core/preferences_service.dart';
import '../../../widgets/custom_header_filter_bar.dart';
import 'clients_actions_v2.dart';
import '../client.dart';
import 'client_card_item_v2.dart';
import 'client_dialogs_v2.dart';
import '../../shell/app_drawer.dart';

class ClientsViewV2 extends StatefulWidget {
  const ClientsViewV2({super.key});

  @override
  State<ClientsViewV2> createState() => _ClientsViewV2State();
}

class _ClientsViewV2State extends State<ClientsViewV2> {
  String _selectedOrder = 'A-Z';
  String _searchQuery = '';
  late bool _isGridView;

  @override
  void initState() {
    super.initState();
    _isGridView = PreferencesService().getBool('clients_is_grid') ?? false;
    ClientsActionsV2().addListener(_onActionsChanged);
  }

  @override
  void dispose() {
    ClientsActionsV2().removeListener(_onActionsChanged);
    super.dispose();
  }

  void _onActionsChanged() {
    if (mounted) setState(() {});
  }

  List<Client> _getFilteredAndSortedClients() {
    final actions = ClientsActionsV2();
    var list = List<Client>.from(actions.allClients);

    if (actions.selectedFilterCity != null) {
      list = list.where((c) => c.city.trim() == actions.selectedFilterCity).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) =>
        c.name.toLowerCase().contains(q) ||
        c.address.toLowerCase().contains(q) ||
        c.city.toLowerCase().contains(q) ||
        c.nickname.toLowerCase().contains(q)
      ).toList();
    }

    final today = DateTime.now().toString().substring(0, 10);

    final pending = list.where((c) {
      bool isVisited = c.lastVisitDate == today && c.lastVisitStatus.isNotEmpty;
      return !isVisited;
    }).toList();

    final visited = list.where((c) {
      bool isVisited = c.lastVisitDate == today && c.lastVisitStatus.isNotEmpty;
      return isVisited;
    }).toList();

    int Function(Client, Client) comparator;
    if (_selectedOrder == 'A-Z') {
      comparator = (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase());
    } else if (_selectedOrder == 'Z-A') {
      comparator = (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase());
    } else {
      comparator = (a, b) => b.balance.compareTo(a.balance);
    }

    pending.sort(comparator);
    visited.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return [...pending, ...visited];
  }

  @override
  Widget build(BuildContext context) {
    final actions = ClientsActionsV2();
    final clients = _getFilteredAndSortedClients();
    final isMobile = MediaQuery.of(context).size.width < 700;
    final fmt = NumberFormat.currency(locale: 'es_ES', symbol: '\$', decimalDigits: 0);

    final filterBar = CustomHeaderFilterBar(
      showSearchBar: true,
      searchQuery: _searchQuery,
      onSearchChanged: (val) => setState(() => _searchQuery = val),
      searchHint: 'Buscar cliente...',
      showZoneFilter: true,
      selectedZone: actions.selectedFilterCity,
      onZoneChanged: (zone) => actions.setFilterCity(zone == 'TODAS' ? null : zone),
      showSortDropdown: true,
      sortOption: _selectedOrder,
      onSortChanged: (sort) {
        if (sort != null) setState(() => _selectedOrder = sort);
      },
      anchorDate: DateTime.now(),
    );

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        elevation: 0,
        title: const Text("Clientes"),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view, color: AppTheme.primaryYellow),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
              PreferencesService().setBool('clients_is_grid', _isGridView);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            filterBar,
            const SizedBox(height: 12),
            Expanded(
              child: clients.isEmpty
                  ? const Center(child: Text("No se encontraron clientes.", style: TextStyle(color: AppTheme.textSecondary)))
                  : !_isGridView
                      ? ListView.builder(
                          itemCount: clients.length,
                          itemBuilder: (context, index) => ClientCardItemV2(
                            client: clients[index],
                            isMobile: isMobile,
                            isGrid: false,
                          ),
                        )
                      : GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isMobile ? 1 : 2,
                            childAspectRatio: isMobile ? 2.5 : 3.0,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: clients.length,
                          itemBuilder: (context, index) => ClientCardItemV2(
                            client: clients[index],
                            isMobile: isMobile,
                            isGrid: true,
                          ),
                        ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryYellow),
              ),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => ClientDialogsV2.showAddDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.person_add, size: 20),
                    label: const Text("Agregar Cliente", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const Spacer(),
                  const Text("TOTAL ADEUDADO: ", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                  Text(
                    fmt.format(clients.fold(0.0, (sum, c) => sum + c.balance)),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.danger),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
