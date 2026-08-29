import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../core/preferences_service.dart';
import '../../../widgets/custom_header_filter_bar.dart';
import '../client.dart';
import 'clients_actions_v2.dart';
import 'client_card_item_v2.dart';
import 'client_dialogs_v2.dart';
import '../client_groups_actions.dart';
import '../special_client_price_global_view.dart';
import '../../shell/app_drawer.dart';

class SpecialClientsViewV2 extends StatefulWidget {
  const SpecialClientsViewV2({super.key});

  @override
  State<SpecialClientsViewV2> createState() => _SpecialClientsViewV2State();
}

class _SpecialClientsViewV2State extends State<SpecialClientsViewV2> {
  String _searchQuery = '';
  String _selectedOrder = 'A-Z';
  late bool _isGridView;

  @override
  void initState() {
    super.initState();
    _isGridView = PreferencesService().getBool('special_clients_is_grid') ?? true;
  }

  void _showGroupDialog() {
    String groupName = '';
    String? selectedGroupId;
    List<String> selectedClientIds = [];
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              bool isSaving = false;
              return Container(
                width: 450,
                constraints: BoxConstraints(
                  maxHeight: (MediaQuery.of(context).size.height - MediaQuery.of(context).viewInsets.bottom) * 0.85,
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Agrupar Clientes Especiales",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryYellow),
                    ),
                    const SizedBox(height: 16),
                    ListenableBuilder(
                      listenable: ClientGroupsActions(),
                      builder: (context, child) {
                        final groups = ClientGroupsActions().groups;
                        return DropdownButtonFormField<String?>(
                          dropdownColor: AppTheme.surfaceDark,
                          decoration: InputDecoration(
                            labelText: "Seleccionar Grupo (u Omitir para Nuevo)",
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: AppTheme.surfaceDark,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          value: selectedGroupId,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text("-- Crear Nuevo Grupo --", style: TextStyle(color: Colors.white)),
                            ),
                            ...groups.map((g) => DropdownMenuItem<String?>(
                              value: g.id,
                              child: Text(g.name, style: const TextStyle(color: Colors.white)),
                            )),
                          ],
                          onChanged: (val) {
                            setStateDialog(() {
                              selectedGroupId = val;
                              if (val != null) {
                                final grp = groups.firstWhere((g) => g.id == val);
                                groupName = grp.name;
                                selectedClientIds = List<String>.from(grp.clientIds);
                              } else {
                                groupName = '';
                                selectedClientIds = [];
                              }
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      controller: TextEditingController(text: groupName)..selection = TextSelection.fromPosition(TextPosition(offset: groupName.length)),
                      decoration: InputDecoration(
                        labelText: "Nombre del Grupo",
                        labelStyle: const TextStyle(color: Colors.white70),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.primaryYellow), borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white30), borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (val) {
                        groupName = val;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      cursorColor: AppTheme.primaryYellow,
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: 'Buscar sucursal...',
                        hintStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.search, color: Colors.black),
                        filled: true,
                        fillColor: AppTheme.primaryYellow,
                        isDense: true,
                      ),
                      onChanged: (val) {
                        setStateDialog(() {
                          searchQuery = val.toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListenableBuilder(
                        listenable: ClientsActionsV2(),
                        builder: (context, child) {
                          var specialList = ClientsActionsV2().allClients.where((c) => c.type == 'especial' && !c.hidden).toList();
                          if (searchQuery.isNotEmpty) {
                            specialList = specialList.where((c) => 
                              c.name.toLowerCase().contains(searchQuery) ||
                              c.city.toLowerCase().contains(searchQuery)
                            ).toList();
                          }
                          if (specialList.isEmpty) {
                            return const Center(child: Text("No hay clientes especiales.", style: TextStyle(color: Colors.white70)));
                          }
                          return ListView.builder(
                            itemCount: specialList.length,
                            itemBuilder: (context, index) {
                              final client = specialList[index];
                              final isChecked = selectedClientIds.contains(client.id);
                              return CheckboxListTile(
                                activeColor: AppTheme.primaryYellow,
                                checkColor: Colors.black,
                                title: Text(client.name, style: const TextStyle(color: Colors.white)),
                                subtitle: Text("${client.city} • ${client.address}", style: const TextStyle(color: Colors.white70)),
                                value: isChecked,
                                onChanged: (bool? checked) {
                                  setStateDialog(() {
                                    if (checked == true) {
                                      selectedClientIds.add(client.id);
                                    } else {
                                      selectedClientIds.remove(client.id);
                                    }
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSaving ? null : () => Navigator.pop(context),
                          child: const Text("CANCELAR", style: TextStyle(color: Colors.white70)),
                        ),
                        const SizedBox(width: 8),
                        if (selectedGroupId != null)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                            onPressed: isSaving ? null : () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  backgroundColor: AppTheme.surfaceDark,
                                  title: const Text("Eliminar Grupo", style: TextStyle(color: Colors.white)),
                                  content: const Text("¿Estás seguro de que deseas eliminar este grupo?", style: TextStyle(color: Colors.white70)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("CANCELAR")),
                                    TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("ELIMINAR", style: TextStyle(color: AppTheme.danger))),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                setStateDialog(() => isSaving = true);
                                try {
                                  await ClientGroupsActions().deleteGroup(selectedGroupId!);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                } catch (e) {
                                  setStateDialog(() => isSaving = false);
                                }
                              }
                            },
                            child: isSaving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("ELIMINAR", style: TextStyle(color: Colors.white)),
                          ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow),
                          onPressed: isSaving ? null : () async {
                            if (groupName.trim().isEmpty) return;
                            setStateDialog(() => isSaving = true);
                            try {
                              if (selectedGroupId != null) {
                                await ClientGroupsActions().updateGroup(selectedGroupId!, groupName.trim(), selectedClientIds);
                              } else {
                                await ClientGroupsActions().createGroup(groupName.trim(), selectedClientIds);
                              }
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              setStateDialog(() => isSaving = false);
                            }
                          },
                          child: isSaving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : Text(selectedGroupId != null ? "GUARDAR" : "CREAR", style: const TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _navigateToGlobalPrices() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SpecialClientPriceGlobalView(),
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
          searchHint: 'Buscar cliente especial...',
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
            title: const Text("Clientes Especiales"),
            actions: [
              IconButton(
                icon: Icon(_isGridView ? Icons.list : Icons.grid_view, color: AppTheme.primaryYellow),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                  PreferencesService().setBool('special_clients_is_grid', _isGridView);
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

  Widget _buildDesktopFilters() {
    return ListenableBuilder(
      listenable: ClientsActionsV2(),
      builder: (context, child) {
        final allCities = ClientsActionsV2().cities;
        final selectedFilter = ClientsActionsV2().selectedFilterCity;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 38,
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AppTheme.primaryYellow,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.location_city, size: 18, color: Colors.black),
                ),
                dropdownColor: AppTheme.primaryYellow,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                value: (selectedFilter != null && allCities.contains(selectedFilter)) ? selectedFilter : null,
                hint: const Text("Todas las ciudades", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text("Todas las ciudades", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13))),
                  ...allCities.map((c) => DropdownMenuItem<String>(value: c, child: Text(c, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)))),
                ],
                onChanged: (val) => ClientsActionsV2().setFilterCity(val),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _navigateToGlobalPrices,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryYellow,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.price_change, color: Colors.black),
              label: const Text("Lista de Precios Global", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            ),
          ],
        );
      }
    );
  }

  Widget _buildList(bool isMobile, {bool isPhone = false}) {
    return ListenableBuilder(
      listenable: ClientsActionsV2(),
      builder: (context, child) {
        var clientsList = ClientsActionsV2().allClients.where((c) => c.type == 'especial' && !c.hidden).toList();

        final filterCity = ClientsActionsV2().selectedFilterCity;
        if (filterCity != null && filterCity.isNotEmpty) {
          clientsList = clientsList.where((c) => c.city.trim().toLowerCase() == filterCity.trim().toLowerCase()).toList();
        }

        final today = DateTime.now().toString().substring(0, 10);
        clientsList.sort((a, b) {
          bool aVisited = a.lastVisitDate == today && a.lastVisitStatus.isNotEmpty;
          bool bVisited = b.lastVisitDate == today && b.lastVisitStatus.isNotEmpty;
          if (aVisited && !bVisited) return 1;
          if (!aVisited && bVisited) return -1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

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
                  ? const Center(child: Text("No hay clientes especiales.", style: TextStyle(color: AppTheme.textSecondary)))
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
                    label: const Text("Agregar Especial", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _showGroupDialog,
                    icon: const Icon(Icons.group_work, color: AppTheme.primaryYellow, size: 18),
                    label: const Text("Agrupar Clientes", style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 13)),
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
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _navigateToGlobalPrices,
                    icon: const Icon(Icons.price_change, color: AppTheme.primaryYellow, size: 18),
                    label: const Text("Precios Especiales Globales", style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 13)),
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
