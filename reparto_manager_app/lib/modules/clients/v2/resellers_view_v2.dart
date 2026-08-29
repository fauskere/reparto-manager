import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../core/preferences_service.dart';
import '../../../widgets/custom_header_filter_bar.dart';
import '../client.dart';
import 'clients_actions_v2.dart';
import 'client_card_item_v2.dart';
import 'client_dialogs_v2.dart';
import '../special_client_price_global_view.dart';
import '../../shell/app_drawer.dart';

class ResellersViewV2 extends StatefulWidget {
  const ResellersViewV2({super.key});

  @override
  State<ResellersViewV2> createState() => _ResellersViewV2State();
}

class _ResellersViewV2State extends State<ResellersViewV2> {
  String _searchQuery = '';
  String _selectedOrder = 'A-Z';
  late bool _isGridView;

  @override
  void initState() {
    super.initState();
    _isGridView = PreferencesService().getBool('resellers_is_grid') ?? true;
  }

  void _navigateToGlobalPrices() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SpecialClientPriceGlobalView(isWholesale: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 800;

        final filterBar = CustomHeaderFilterBar(
          showSearchBar: true,
          searchQuery: _searchQuery,
          onSearchChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
          searchHint: 'Buscar revendedor...',
          showZoneFilter: true,
          selectedZone: ClientsActionsV2().selectedFilterCity,
          onZoneChanged: (zone) => ClientsActionsV2().setFilterCity(zone == 'TODAS' ? null : zone),
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
            title: const Text("Revendedores"),
            actions: [
              IconButton(
                icon: Icon(_isGridView ? Icons.list : Icons.grid_view, color: AppTheme.primaryYellow),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                  PreferencesService().setBool('resellers_is_grid', _isGridView);
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Padding(
            padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
            child: Column(
              children: [
                filterBar,
                const SizedBox(height: 12),
                Expanded(child: _buildList(isMobile, isPhone: constraints.maxWidth <= 500)),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildList(bool isMobile, {bool isPhone = false}) {
    return ListenableBuilder(
      listenable: ClientsActionsV2(),
      builder: (context, child) {
        var clientsList = ClientsActionsV2().allClients.where((c) => c.type == 'revendedor' && !c.hidden).toList();

        final filterCity = ClientsActionsV2().selectedFilterCity;
        if (filterCity != null && filterCity.isNotEmpty) {
          clientsList = clientsList.where((c) => c.city.trim().toLowerCase() == filterCity.trim().toLowerCase()).toList();
        }

        final today = DateTime.now().toString().substring(0, 10);
        int Function(Client, Client) comparator;
        if (_selectedOrder == 'A-Z') {
          comparator = (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase());
        } else if (_selectedOrder == 'Z-A') {
          comparator = (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase());
        } else {
          comparator = (a, b) => b.balance.compareTo(a.balance);
        }

        clientsList.sort(comparator);

        if (_searchQuery.isNotEmpty) {
          clientsList = clientsList.where((c) => 
            c.name.toLowerCase().contains(_searchQuery) || 
            c.address.toLowerCase().contains(_searchQuery) ||
            c.city.toLowerCase().contains(_searchQuery) ||
            c.nickname.toLowerCase().contains(_searchQuery)
          ).toList();
        }

        double totalDebt = 0.0;
        for (var c in clientsList) {
          totalDebt += ClientsActionsV2().getCalculatedBalance(c.id);
        }
        final fmt = NumberFormat.currency(locale: 'es_ES', symbol: '\$', decimalDigits: 0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: clientsList.isEmpty
                  ? const Center(child: Text("No hay revendedores registrados.", style: TextStyle(color: AppTheme.textSecondary)))
                  : (!_isGridView
                      ? ListView.builder(
                          itemCount: clientsList.length,
                          itemBuilder: (context, index) => ClientCardItemV2(client: clientsList[index], isMobile: isMobile, isGrid: false, isPhone: isPhone),
                        )
                      : GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isPhone ? 1 : (isMobile ? 2 : 3),
                            childAspectRatio: isPhone ? 2.8 : (isMobile ? 1.4 : 1.9),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: clientsList.length,
                          itemBuilder: (context, index) => ClientCardItemV2(client: clientsList[index], isMobile: isMobile, isGrid: true, isPhone: isPhone),
                        )),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryYellow),
              ),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => ClientDialogsV2.showAddDialog(context),
                    icon: const Icon(Icons.person_add, color: Colors.black, size: 18),
                    label: const Text("Nuevo Revendedor", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _navigateToGlobalPrices,
                    icon: const Icon(Icons.price_change, color: AppTheme.primaryYellow, size: 18),
                    label: const Text("Precios Revendedor", style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: AppTheme.primaryYellow, width: 1.5),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (clientsList.isNotEmpty) ...[
                    if (!isMobile) const Text("TOTAL ADEUDADO: ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    Text(
                      totalDebt == 0 ? "\$0" : (totalDebt > 0 ? fmt.format(totalDebt) : "-${fmt.format(totalDebt.abs())}"), 
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: totalDebt > 0 ? AppTheme.danger : (totalDebt < 0 ? Colors.greenAccent : AppTheme.textSecondary)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      }
    );
  }
}
