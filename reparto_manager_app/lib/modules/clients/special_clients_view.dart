import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import '../../core/preferences_service.dart';
import '../../models/product.dart';
import '../inventory/inventory_actions.dart';
import 'clients_actions.dart';
import 'client.dart';
import 'client_details_view.dart';
import 'client_group.dart';
import 'client_groups_actions.dart';
import '../shell/app_drawer.dart';
import 'special_client_price_global_view.dart';

class SpecialClientsView extends StatefulWidget {
  const SpecialClientsView({super.key});

  @override
  State<SpecialClientsView> createState() => _SpecialClientsViewState();
}

class _SpecialClientsViewState extends State<SpecialClientsView> {
  String _selectedFormCity = '';
  bool _isEnteringNewCity = false;
  String _searchQuery = '';
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
                        listenable: ClientsActions(),
                        builder: (context, child) {
                          var specialList = ClientsActions().allClients.where((c) => c.type == 'especial' && !c.hidden).toList();
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
                                  content: const Text("¿Estás seguro de que deseas eliminar este grupo? Los clientes ya no estarán agrupados.", style: TextStyle(color: Colors.white70)),
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Grupo eliminado."), backgroundColor: Colors.green),
                                    );
                                  }
                                } catch (e) {
                                  setStateDialog(() => isSaving = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Error al eliminar: $e"), backgroundColor: AppTheme.danger),
                                    );
                                  }
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
                            if (groupName.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Por favor ingresá un nombre de grupo."), backgroundColor: AppTheme.danger),
                              );
                              return;
                            }
                            setStateDialog(() => isSaving = true);
                            try {
                              if (selectedGroupId != null) {
                                await ClientGroupsActions().updateGroup(selectedGroupId!, groupName.trim(), selectedClientIds);
                              } else {
                                await ClientGroupsActions().createGroup(groupName.trim(), selectedClientIds);
                              }
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(selectedGroupId != null ? "Grupo actualizado." : "Grupo creado."), backgroundColor: Colors.green),
                                );
                              }
                            } catch (e) {
                              setStateDialog(() => isSaving = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error al guardar: $e"), backgroundColor: AppTheme.danger),
                                );
                              }
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

  void _showPromoteDialog() {
    String searchQuery = '';
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Container(
                width: 400,
                constraints: BoxConstraints(maxHeight: (MediaQuery.of(context).size.height - MediaQuery.of(context).viewInsets.bottom) * 0.85),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Promover Cliente a Especial", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryYellow)),
                    const SizedBox(height: 16),
                    TextField(
                      cursorColor: AppTheme.primaryYellow,
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: 'Buscar cliente para promover...',
                        hintStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.search, color: Colors.black),
                        filled: true,
                        fillColor: AppTheme.primaryYellow,
                      ),
                      onChanged: (val) {
                        setStateDialog(() {
                          searchQuery = val.toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListenableBuilder(
                        listenable: ClientsActions(),
                        builder: (context, child) {
                          var list = ClientsActions().allClients.where((c) => c.type == 'normal' && !c.hidden).toList();
                          if (searchQuery.isNotEmpty) {
                            list = list.where((c) => 
                              c.name.toLowerCase().contains(searchQuery) ||
                              c.city.toLowerCase().contains(searchQuery)
                            ).toList();
                          }
                          if (list.isEmpty) {
                            return const Center(child: Text("No se encontraron clientes normales."));
                          }
                          return ListView.builder(
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final client = list[index];
                              return ListTile(
                                leading: const Icon(Icons.person, color: AppTheme.primaryYellow),
                                title: Text(client.name),
                                subtitle: Text("${client.city} ââ‚¬Â¢ ${client.address}"),
                                onTap: () async {
                                  Navigator.pop(context);
                                  await ClientsActions().promoteToSpecial(client.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("${client.name} ahora es un Cliente Especial."),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          );
                        }
                      ),
                    ),
                  ],
                ),
              );
            }
          ),
        );
      }
    );
  }

  void _showEditDialog(Client client) {
    final editNameCtrl = TextEditingController(text: client.name);
    final editPhoneCtrl = TextEditingController(text: client.phone);
    final editAddressCtrl = TextEditingController(text: client.address);
    final editCityCtrl = TextEditingController(text: client.city);
    final editNicknameCtrl = TextEditingController(text: client.nickname);
    bool isOpenContinuous = client.isOpenContinuous;

    showDialog(
      context: context,
      builder: (context) {
        bool _isSaving = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              title: const Text("Editar Cliente Especial"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: editNameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: editCityCtrl,
                    decoration: const InputDecoration(labelText: 'Ciudad', prefixIcon: Icon(Icons.location_city)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: editAddressCtrl,
                    decoration: const InputDecoration(labelText: 'Dirección', prefixIcon: Icon(Icons.location_on)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: editNicknameCtrl,
                    decoration: const InputDecoration(labelText: 'Apodo (Oculto, útil para buscar)', prefixIcon: Icon(Icons.badge)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: editPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Icons.phone)),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text("Abre de corrido âËœâ‚¬ïÂ¸Â"),
                    value: isOpenContinuous,
                    activeColor: AppTheme.primaryYellow,
                    onChanged: (val) => setStateDialog(() => isOpenContinuous = val),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text("Cancelar", style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: _isSaving ? null : () async {
                    if (editNameCtrl.text.trim().isEmpty || editCityCtrl.text.trim().isEmpty) {
                      return;
                    }
                    setStateDialog(() => _isSaving = true);
                    try {
                      await ClientsActions().updateClient(
                        client.id,
                        editNameCtrl.text,
                        editPhoneCtrl.text,
                        editCityCtrl.text,
                        editAddressCtrl.text,
                        nickname: editNicknameCtrl.text,
                        isOpenContinuous: isOpenContinuous,
                        type: 'especial',
                        customPrices: client.customPrices,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      setStateDialog(() => _isSaving = false);
                    }
                  },
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text("Guardar"),
                )
              ],
            );
          }
        );
      }
    );
  }

  void _navigateToPriceConfig(Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpecialClientPricesView(client: client),
      ),
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

        final searchBar = SizedBox(
          width: isMobile ? double.infinity : 350,
          height: 40,
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
            cursorColor: Colors.black,
            decoration: InputDecoration(
              hintText: 'Buscar cliente especial...',
              hintStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Colors.black, size: 18),
              isDense: true,
              filled: true,
              fillColor: AppTheme.primaryYellow,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        );

        return Scaffold(
          drawer: const AppDrawer(),
          appBar: AppBar(
            elevation: 0,
            title: Row(
              children: [
                const Text("Clientes Especiales"),
                if (!isMobile) ...[
                  const SizedBox(width: 32),
                  searchBar,
                ]
              ],
            ),
            actions: [
              if (!isMobile) ...[
                _buildDesktopFilters(),
                const SizedBox(width: 8),
              ],
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
            child: _buildList(isMobile, isPhone: constraints.maxWidth <= 500, isTablet: constraints.maxWidth > 500 && constraints.maxWidth <= 1024),
          ),
        );
      }
    );
  }

  Widget _buildDesktopFilters() {
    return ListenableBuilder(
      listenable: ClientsActions(),
      builder: (context, child) {
        final allCities = ClientsActions().specialCities;
        final selectedFilter = ClientsActions().selectedFilterCity;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
          height: 36,
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
            hint: const Text("Todas las ciudades", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
            value: (selectedFilter != null && allCities.contains(selectedFilter)) ? selectedFilter : null,
            items: [
              const DropdownMenuItem<String>(value: null, child: Text("Todas las ciudades", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13))),
              ...allCities.map((c) => DropdownMenuItem<String>(value: c, child: Text(c, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)))),
            ],
            onChanged: (val) => ClientsActions().setFilterCity(val),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _navigateToGlobalPrices,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryYellow,
            foregroundColor: Colors.black,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          icon: const Icon(Icons.price_change, color: Colors.black),
          label: const Text("Lista de Precios Global", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        ),
        ],
        );
      }
    );
  }

  Widget _buildCityDropdown(bool isMobile, List<String> allCities, String? selectedFilter) {
    return SizedBox(
      width: isMobile ? double.infinity : 180,
      height: isMobile ? 36 : 40,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppTheme.primaryYellow,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          prefixIcon: const Icon(Icons.location_city, size: 16, color: Colors.black),
        ),
        dropdownColor: AppTheme.primaryYellow,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
        value: (selectedFilter != null && allCities.contains(selectedFilter)) ? selectedFilter : null,
        hint: const Text("Ciudad", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
        items: [
          const DropdownMenuItem<String>(value: null, child: Text("Todas las ciudades", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13))),
          ...allCities.map((c) => DropdownMenuItem<String>(value: c, child: Text(c, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)))),
        ],
        onChanged: (val) => ClientsActions().setFilterCity(val),
      ),
    );
  }

  Widget _buildList(bool isMobile, {bool isPhone = false, bool isTablet = false}) {
    return ListenableBuilder(
      listenable: ClientsActions(),
      builder: (context, child) {
        var clientsList = List<Client>.from(ClientsActions().specialClients);
        final today = DateTime.now().toString().substring(0, 10);
        clientsList.sort((a, b) {
           bool aVisited = a.lastVisitDate == today && a.lastVisitStatus.isNotEmpty;
           bool bVisited = b.lastVisitDate == today && b.lastVisitStatus.isNotEmpty;
           if (aVisited && !bVisited) return 1;
           if (!aVisited && bVisited) return -1;
           return 0;
        });

        if (_searchQuery.isNotEmpty) {
           clientsList = clientsList.where((c) => 
             c.name.toLowerCase().contains(_searchQuery) || 
             c.address.toLowerCase().contains(_searchQuery) ||
             c.city.toLowerCase().contains(_searchQuery) ||
             c.nickname.toLowerCase().contains(_searchQuery)
           ).toList();
        }
        final clients = clientsList;
        final allCities = ClientsActions().specialCities;
        final selectedFilter = ClientsActions().selectedFilterCity;
        
        double totalDebt = clients.fold(0, (sum, c) => sum + c.balance);
        final fmt = NumberFormat.currency(locale: 'es_ES', symbol: '\$', decimalDigits: 0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPhone) ...[
              const Text("Buscar", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              // searchBar local
              SizedBox(
                width: double.infinity,
                height: 40,
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    hintText: 'Buscar cliente especial...',
                    hintStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.black, size: 18),
                    isDense: true,
                    filled: true,
                    fillColor: AppTheme.primaryYellow,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text("Filtros", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              _buildCityDropdown(isMobile, allCities, selectedFilter),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _navigateToGlobalPrices,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.price_change, color: Colors.black),
                  label: const Text("Lista de Precios Global", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ] else if (isMobile || isTablet) ...[
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                        cursorColor: Colors.black,
                        decoration: InputDecoration(
                          hintText: 'Buscar cliente especial...',
                          hintStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 13),
                          prefixIcon: const Icon(Icons.search, color: Colors.black, size: 18),
                          isDense: true,
                          filled: true,
                          fillColor: AppTheme.primaryYellow,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildCityDropdown(isMobile, allCities, selectedFilter)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _navigateToGlobalPrices,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.price_change, color: Colors.black),
                  label: const Text("Lista de Precios Global", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: clients.isEmpty
                  ? const Center(child: Text("No hay clientes especiales.", style: TextStyle(color: AppTheme.textSecondary)))
                  : (!_isGridView
                      ? ListView.builder(
                          itemCount: clients.length,
                          itemBuilder: (context, index) => _buildClientCard(clients[index], isMobile, false, isPhone: isPhone),
                        )
                      : GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isPhone ? 1 : (isMobile ? 2 : 3),
                            childAspectRatio: isPhone ? 2.8 : (isMobile ? 1.4 : 1.9),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: clients.length,
                          itemBuilder: (context, index) => _buildClientCard(clients[index], isMobile, true, isPhone: isPhone),
                        )),
            ),
            // Barra inferior: botón Agregar a la izquierda, TOTAL a la derecha
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
                    onPressed: _showPromoteDialog,
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
                    icon: const Icon(Icons.group_work, color: Colors.black, size: 18),
                    label: const Text("Agrupar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const Spacer(),
                  // TOTAL a la DERECHA
                  if (clients.isNotEmpty) ...[
                    if (!isMobile) const Text("TOTAL ADEUDADO: ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    Text(fmt.format(totalDebt), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: totalDebt > 0 ? AppTheme.danger : Colors.greenAccent)),
                  ] else
                    const Text("Sin clientes especiales aún", style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildClientCard(Client client, bool isMobile, bool isGrid, {bool isPhone = false}) {
    final fmt = NumberFormat.currency(locale: 'es_ES', symbol: '\$', decimalDigits: 0);
    final today = DateTime.now().toString().substring(0, 10);
    bool visitedToday = client.lastVisitDate == today;
    bool isVisited = visitedToday && client.lastVisitStatus == 'visited';
    bool isSkipped = visitedToday && client.lastVisitStatus == 'skipped';

    Widget actionButtons = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: Icon(Icons.price_change, color: AppTheme.primaryYellow, size: isPhone ? 18 : 22),
          tooltip: 'Configurar Precios',
          onPressed: () => _navigateToPriceConfig(client),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        SizedBox(width: isPhone ? 8 : 14),
        IconButton(
          icon: Icon(Icons.edit, color: visitedToday ? Colors.grey : AppTheme.primaryYellow, size: isPhone ? 18 : 20),
          onPressed: () => _showEditDialog(client),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        SizedBox(width: isPhone ? 8 : 14),
        IconButton(
          icon: Icon(Icons.delete_outline, color: visitedToday ? Colors.grey : AppTheme.danger, size: isPhone ? 18 : 20),
          onPressed: () => _handleDeleteClient(context, client),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );

    if (isPhone) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: visitedToday ? (isVisited ? AppTheme.surfaceDark.withOpacity(0.5) : Colors.black.withOpacity(0.3)) : AppTheme.surfaceDark,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ClientDetailsView(client: client)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: visitedToday ? Colors.transparent : AppTheme.backgroundDark,
                                child: isVisited ? const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20) 
                                     : isSkipped ? const Icon(Icons.cancel, color: Colors.grey, size: 20)
                                     : const Icon(Icons.storefront, color: AppTheme.primaryYellow, size: 18),
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: GestureDetector(
                                  onTap: () {
                                    ClientsActions().toggleOpenContinuous(client.id, client.isOpenContinuous);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.surfaceDark,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      client.isOpenContinuous ? Icons.store : Icons.access_time,
                                      size: 8,
                                      color: client.isOpenContinuous ? AppTheme.textSecondary : AppTheme.primaryYellow,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!visitedToday) ...[
                                IconButton(
                                  icon: const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 20),
                                  onPressed: () => ClientsActions().markVisit(client.id, 'visited'),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.cancel_outlined, color: Colors.grey, size: 20),
                                  onPressed: () => ClientsActions().markVisit(client.id, 'skipped'),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                ),
                              ],
                              if (visitedToday) ...[
                                IconButton(
                                  icon: const Icon(Icons.undo, color: AppTheme.primaryYellow, size: 20),
                                  onPressed: () => ClientsActions().markVisit(client.id, ''),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              client.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 13,
                                decoration: visitedToday ? TextDecoration.lineThrough : null,
                                color: visitedToday ? Colors.grey : AppTheme.textPrimary
                              ), 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            client.city, 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                          ),
                          if (!client.isOpenContinuous) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.access_time, color: AppTheme.primaryYellow, size: 12),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                "Cierra Mediodía",
                                style: TextStyle(
                                  color: visitedToday ? Colors.grey : AppTheme.primaryYellow,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (client.balance != 0)
                      Text(
                        fmt.format(client.balance),
                        style: TextStyle(
                          fontWeight: FontWeight.w900, 
                          fontSize: 13,
                          color: client.balance > 0 ? AppTheme.danger : Colors.greenAccent
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      const SizedBox(height: 15),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.price_change, color: AppTheme.primaryYellow, size: 18),
                          onPressed: () => _navigateToPriceConfig(client),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: Icon(Icons.edit, color: visitedToday ? Colors.grey : AppTheme.primaryYellow, size: 18),
                          onPressed: () => _showEditDialog(client),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: visitedToday ? Colors.grey : AppTheme.danger, size: 18),
                          onPressed: () => _handleDeleteClient(context, client),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isGrid) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: visitedToday ? (isVisited ? AppTheme.surfaceDark.withOpacity(0.5) : Colors.black.withOpacity(0.3)) : AppTheme.surfaceDark,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ClientDetailsView(client: client)),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(isPhone ? 8.0 : 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: isPhone ? 14 : 16,
                          backgroundColor: visitedToday ? Colors.transparent : AppTheme.backgroundDark,
                          child: isVisited ? Icon(Icons.check_circle, color: Colors.greenAccent, size: isPhone ? 20 : 24) 
                               : isSkipped ? Icon(Icons.cancel, color: Colors.grey, size: isPhone ? 20 : 24)
                               : Icon(Icons.storefront, color: AppTheme.primaryYellow, size: isPhone ? 18 : 22),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: GestureDetector(
                            onTap: () {
                              ClientsActions().toggleOpenContinuous(client.id, client.isOpenContinuous);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppTheme.surfaceDark,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                client.isOpenContinuous ? Icons.store : Icons.access_time,
                                size: isPhone ? 8 : 10,
                                color: client.isOpenContinuous ? AppTheme.textSecondary : AppTheme.primaryYellow,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        client.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: isPhone ? 13 : 15,
                          decoration: visitedToday ? TextDecoration.lineThrough : null,
                          color: visitedToday ? Colors.grey : AppTheme.textPrimary
                        ), 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isPhone ? 4 : 8),
                Text(
                  client.city, 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: isPhone ? 11 : 13),
                ),
                if (!client.isOpenContinuous) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: AppTheme.primaryYellow, size: isPhone ? 12 : 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "Cierra Mediodía",
                          style: TextStyle(
                            color: visitedToday ? Colors.grey : AppTheme.primaryYellow,
                            fontSize: isPhone ? 10 : 12,
                            fontWeight: FontWeight.bold
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (client.balance != 0)
                      Expanded(
                        child: Text(
                          fmt.format(client.balance),
                          style: TextStyle(
                            fontWeight: FontWeight.w900, 
                            fontSize: isPhone ? 13 : 15,
                            color: client.balance > 0 ? AppTheme.danger : Colors.greenAccent
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      const Spacer(),
                    const SizedBox(width: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!visitedToday) ...[
                          IconButton(
                            icon: Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: isPhone ? 16 : 20),
                            onPressed: () => ClientsActions().markVisit(client.id, 'visited'),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: Icon(Icons.cancel_outlined, color: Colors.grey, size: isPhone ? 16 : 20),
                            onPressed: () => ClientsActions().markVisit(client.id, 'skipped'),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (visitedToday) ...[
                          IconButton(
                            icon: Icon(Icons.undo, color: AppTheme.primaryYellow, size: isPhone ? 16 : 20),
                            onPressed: () => ClientsActions().markVisit(client.id, ''),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                        ],
                        actionButtons,
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Modo Lista
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      color: visitedToday ? (isVisited ? AppTheme.surfaceDark.withOpacity(0.5) : Colors.black.withOpacity(0.3)) : AppTheme.surfaceDark,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ClientDetailsView(client: client)),
          );
        },
        child: Container(
          height: isPhone ? 58 : 72,
          padding: EdgeInsets.symmetric(horizontal: isPhone ? 8 : 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: isPhone ? 14 : 20,
                    backgroundColor: visitedToday ? Colors.transparent : AppTheme.backgroundDark,
                    child: isVisited ? Icon(Icons.check_circle, color: Colors.greenAccent, size: isPhone ? 18 : 24) 
                         : isSkipped ? Icon(Icons.cancel, color: Colors.grey, size: isPhone ? 18 : 24)
                         : Icon(Icons.storefront, color: AppTheme.primaryYellow, size: isPhone ? 18 : 24),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () {
                        ClientsActions().toggleOpenContinuous(client.id, client.isOpenContinuous);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppTheme.surfaceDark,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          client.isOpenContinuous ? Icons.store : Icons.access_time,
                          size: isPhone ? 8 : 12,
                          color: client.isOpenContinuous ? AppTheme.textSecondary : AppTheme.primaryYellow,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name, 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: isPhone ? 13 : 16,
                        decoration: visitedToday ? TextDecoration.lineThrough : null,
                        color: visitedToday ? Colors.grey : AppTheme.textPrimary
                      ), 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(client.city, style: TextStyle(color: AppTheme.textSecondary, fontSize: isPhone ? 11 : 13)),
                        if (!client.isOpenContinuous) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.access_time, color: AppTheme.primaryYellow, size: isPhone ? 12 : 16),
                          const SizedBox(width: 4),
                          Text(
                            "Cierra Mediodía", 
                            style: TextStyle(
                              color: visitedToday ? Colors.grey : AppTheme.primaryYellow, 
                              fontSize: isPhone ? 10 : 12, 
                              fontWeight: FontWeight.bold
                            )
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!visitedToday) ...[
                    IconButton(
                      icon: Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: isPhone ? 18 : 28),
                      onPressed: () => ClientsActions().markVisit(client.id, 'visited'),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.cancel_outlined, color: Colors.grey, size: isPhone ? 18 : 28),
                      onPressed: () => ClientsActions().markVisit(client.id, 'skipped'),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (visitedToday) ...[
                    IconButton(
                      icon: Icon(Icons.undo, color: AppTheme.primaryYellow, size: isPhone ? 18 : 28),
                      onPressed: () => ClientsActions().markVisit(client.id, ''),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (client.balance != 0)
                    Padding(
                      padding: EdgeInsets.only(right: isPhone ? 8.0 : 16.0),
                      child: Text(
                        fmt.format(client.balance),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: isPhone ? 13 : 20,
                          color: visitedToday ? Colors.grey : (client.balance > 0 ? AppTheme.danger : Colors.greenAccent),
                        ),
                      ),
                    ),
                  actionButtons,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDeleteClient(BuildContext context, Client client) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Row(
          children: [
            Icon(Icons.remove_circle_outline, color: AppTheme.danger),
            const SizedBox(width: 8),
            Text("Quitar de Especiales", style: TextStyle(color: AppTheme.danger)),
          ],
        ),
        content: Text(
          "¿Estás seguro que deseas quitar a ${client.name} de la lista de Clientes Especiales?\n\nVolverá a figurar como cliente común y se perderán sus precios específicos.",
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await ClientsActions().demoteFromSpecial(client.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${client.name} fue quitado de Especiales y devuelto a Clientes comunes."),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text("QUITAR", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class SpecialClientPricesView extends StatefulWidget {
  final Client client;
  const SpecialClientPricesView({super.key, required this.client});

  @override
  State<SpecialClientPricesView> createState() => _SpecialClientPricesViewState();
}

class _SpecialClientPricesViewState extends State<SpecialClientPricesView> {
  final Map<String, bool> _selectedProducts = {};
  final Map<String, TextEditingController> _priceControllers = {};
  String _searchQuery = '';
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    final inventory = InventoryActions().products;
    for (var prod in inventory) {
      if (prod.variants.isEmpty) {
        final key = prod.id;
        final hasCustom = widget.client.customPrices.containsKey(key);
        _selectedProducts[key] = hasCustom;
        _priceControllers[key] = TextEditingController(
          text: hasCustom ? widget.client.customPrices[key]!.toStringAsFixed(0) : '',
        );
      } else {
        for (var variant in prod.variants) {
          final key = '${prod.id}_${variant.name}';
          final hasCustom = widget.client.customPrices.containsKey(key);
          _selectedProducts[key] = hasCustom;
          _priceControllers[key] = TextEditingController(
            text: hasCustom ? widget.client.customPrices[key]!.toStringAsFixed(0) : '',
          );
        }
      }
    }
  }

  @override
  void dispose() {
    for (var c in _priceControllers.values) c.dispose();
    super.dispose();
  }

  void _toggle(String key, double basePrice) {
    setState(() {
      final now = !(_selectedProducts[key] ?? false);
      _selectedProducts[key] = now;
      if (now && (_priceControllers[key]?.text.isEmpty ?? true)) {
        _priceControllers[key]?.text = basePrice.toStringAsFixed(0);
      }
    });
  }

  void _save() {
    final Map<String, double> newCustomPrices = {};
    _selectedProducts.forEach((key, selected) {
      if (selected) {
        final text = _priceControllers[key]?.text.trim() ?? '';
        double price = double.tryParse(text) ?? 0.0;
        if (price <= 0) price = _getBasePrice(key);
        newCustomPrices[key] = price;
      }
    });
    ClientsActions().updateClient(
      widget.client.id, widget.client.name, widget.client.phone,
      widget.client.city, widget.client.address,
      nickname: widget.client.nickname,
      isOpenContinuous: widget.client.isOpenContinuous,
      type: 'especial', customPrices: newCustomPrices,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Catálogo y precios actualizados."), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  double _getBasePrice(String key) {
    final parts = key.split('_');
    final prod = InventoryActions().products.firstWhere((p) => p.id == parts[0], orElse: () => Product(id: '', name: '', price: 0));
    if (parts.length > 1 && prod.variants.isNotEmpty) {
      final v = prod.variants.firstWhere((v) => v.name == parts[1], orElse: () => ProductVariant(name: '', price: 0));
      return v.price ?? prod.price;
    }
    return prod.price;
  }

  List<Map<String, dynamic>> _buildItems(List<dynamic> inventory) {
    final items = <Map<String, dynamic>>[];
    for (var prod in inventory) {
      if (prod.variants.isEmpty) {
        items.add({'name': prod.name, 'basePrice': prod.price.toDouble(), 'key': prod.id, 'category': prod.category});
      } else {
        for (var v in prod.variants) {
          items.add({'name': '${prod.name} (${v.name})', 'basePrice': (v.price ?? prod.price).toDouble(), 'key': '${prod.id}_${v.name}', 'category': prod.category});
        }
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final inventory = InventoryActions().products;
    final selectedCount = _selectedProducts.values.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Catálogo: ${widget.client.name}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("$selectedCount seleccionado${selectedCount == 1 ? '' : 's'}",
              style: const TextStyle(fontSize: 12, color: AppTheme.primaryYellow)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view, color: AppTheme.primaryYellow),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'Ver como lista' : 'Ver como cuadrilla',
          ),
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save, color: Colors.black),
            label: const Text("GUARDAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(backgroundColor: AppTheme.primaryYellow, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              cursorColor: Colors.black,
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                hintStyle: const TextStyle(color: Colors.black54),
                prefixIcon: const Icon(Icons.search, color: Colors.black),
                filled: true, fillColor: AppTheme.primaryYellow,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListenableBuilder(
              listenable: InventoryActions(),
              builder: (context, _) {
                final allItems = _buildItems(inventory);
                final filtered = allItems.where((item) =>
                  _searchQuery.isEmpty ||
                  (item['name'] as String).toLowerCase().contains(_searchQuery) ||
                  (item['category'] as String).toLowerCase().contains(_searchQuery)
                ).toList();

                if (_isGridView) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.15,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildGridCard(filtered[index]),
                  );
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildListRow(filtered[index]),
                  );
                }
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.surfaceDark,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save, color: Colors.black),
              label: Text("GUARDAR ($selectedCount seleccionados)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryYellow,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(Map<String, dynamic> item) {
    final key = item['key'] as String;
    final name = item['name'] as String;
    final basePrice = item['basePrice'] as double;
    if (!_selectedProducts.containsKey(key)) {
      _selectedProducts[key] = false;
      _priceControllers[key] = TextEditingController();
    }
    final isSelected = _selectedProducts[key] ?? false;
    final controller = _priceControllers[key]!;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? AppTheme.primaryYellow.withOpacity(0.4)
              : AppTheme.primaryYellow.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _toggle(key, basePrice),
        splashColor: AppTheme.primaryYellow.withOpacity(0.2),
        highlightColor: AppTheme.primaryYellow.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.2),
                      maxLines: 3, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? AppTheme.primaryYellow : Colors.white24,
                    size: 18,
                  ),
                ],
              ),
              const Spacer(),
              if (isSelected)
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                  style: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.w900, fontSize: 20),
                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    prefixStyle: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.w900, fontSize: 20),
                    hintText: basePrice.toStringAsFixed(0),
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                    border: InputBorder.none,
                  ),
                )
              else
                Text('\$${basePrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 20, color: AppTheme.primaryYellow, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListRow(Map<String, dynamic> item) {
    final key = item['key'] as String;
    final name = item['name'] as String;
    final basePrice = item['basePrice'] as double;
    if (!_selectedProducts.containsKey(key)) {
      _selectedProducts[key] = false;
      _priceControllers[key] = TextEditingController();
    }
    final isSelected = _selectedProducts[key] ?? false;
    final controller = _priceControllers[key]!;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected
              ? AppTheme.primaryYellow.withOpacity(0.4)
              : AppTheme.primaryYellow.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _toggle(key, basePrice),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? AppTheme.primaryYellow : Colors.white24, size: 22),
              const SizedBox(width: 12),
              Expanded(child: Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
              const SizedBox(width: 12),
              if (isSelected)
                SizedBox(
                  width: 130,
                  child: TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                    style: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 16),
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      prefixStyle: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold),
                      hintText: basePrice.toStringAsFixed(0),
                      hintStyle: const TextStyle(color: Colors.white24),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      filled: true, fillColor: Colors.black26,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                )
              else
                Text('\$${basePrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
