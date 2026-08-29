import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import '../../core/preferences_service.dart';
import 'clients_actions.dart';
import 'client.dart';
import 'client_details_view.dart';
import '../shell/app_drawer.dart';

class ClientsView extends StatefulWidget {
  const ClientsView({super.key});

  @override
  State<ClientsView> createState() => _ClientsViewState();
}

class _ClientsViewState extends State<ClientsView> {
  String _selectedOrder = 'A-Z';
  String _selectedFormCity = '';
  bool _isEnteringNewCity = false;
  String _searchQuery = '';
  late bool _isGridView;

  @override
  void initState() {
    super.initState();
    _isGridView = PreferencesService().getBool('clients_is_grid') ?? true;
  }

  Widget _buildOrderDropdown(bool isMobile) {
    return SizedBox(
      width: isMobile ? double.infinity : 130,
      height: isMobile ? 36 : 40,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppTheme.primaryYellow,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        dropdownColor: AppTheme.primaryYellow,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
        value: _selectedOrder,
        items: const [
          DropdownMenuItem(value: 'A-Z', child: Text("A-Z", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13))),
          DropdownMenuItem(value: 'Z-A', child: Text("Z-A", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13))),
          DropdownMenuItem(value: 'Saldo', child: Text("Por Saldo", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13))),
        ],
        onChanged: (val) {
          if (val != null) {
            setState(() {
              _selectedOrder = val;
            });
          }
        },
      ),
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

  void _showAddDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final nicknameController = TextEditingController();
    final newCityController = TextEditingController();
    bool _isOpenContinuous = false;
    
    final cities = ClientsActions().cities;
    _selectedFormCity = ClientsActions().selectedFilterCity ?? '';
    if (_selectedFormCity.isEmpty && cities.isNotEmpty) {
      _selectedFormCity = cities.first;
    }
    _isEnteringNewCity = false;

    showDialog(
      context: context,
      builder: (context) {
        bool _isSaving = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final cities = ClientsActions().cities;
            if (!_isEnteringNewCity && _selectedFormCity.isNotEmpty && !cities.contains(_selectedFormCity)) {
              _selectedFormCity = '';
            }
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              title: const Text("Nuevo Cliente"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre / Negocio', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                    ),
                    const SizedBox(height: 16),
                    if (_isEnteringNewCity || cities.isEmpty) ...[
                      TextField(
                        controller: newCityController,
                        decoration: InputDecoration(
                          labelText: 'Escribe la Ciudad',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.location_city),
                          suffixIcon: cities.isNotEmpty ? IconButton(
                            icon: const Icon(Icons.cancel),
                            onPressed: () => setStateDialog(() => _isEnteringNewCity = false),
                          ) : null,
                        ),
                      ),
                    ] else ...[
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Ciudad', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_city)),
                        value: _selectedFormCity.isEmpty && cities.isNotEmpty ? cities.first : (_selectedFormCity.isEmpty ? null : _selectedFormCity),
                        items: [
                          ...cities.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))),
                          const DropdownMenuItem<String>(value: 'NEW_CITY', child: Text('+ Agregar nueva ciudad', style: TextStyle(color: AppTheme.primaryYellow))),
                        ],
                        onChanged: (val) {
                          if (val == 'NEW_CITY') {
                            setStateDialog(() => _isEnteringNewCity = true);
                          } else {
                            setStateDialog(() {
                              _selectedFormCity = val ?? '';
                              _isEnteringNewCity = false;
                            });
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nicknameController,
                      decoration: const InputDecoration(labelText: 'Apodo (Oculto, útil para buscar)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text("Abre de corrido ☀️"),
                      subtitle: const Text("Ideal para saber que no cierran al mediodía"),
                      value: _isOpenContinuous,
                      activeColor: AppTheme.primaryYellow,
                      onChanged: (val) => setStateDialog(() => _isOpenContinuous = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: _isSaving ? null : () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: AppTheme.textSecondary))),
                ElevatedButton(
                  onPressed: _isSaving ? null : () async {
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();
                    final address = addressController.text.trim();
                    final city = _isEnteringNewCity ? newCityController.text.trim() : _selectedFormCity;

                    if (name.isEmpty || city.isEmpty) {
                      return;
                    }

                    setStateDialog(() => _isSaving = true);
                    try {
                      await ClientsActions().addClient(name, phone, city, address, nickname: nicknameController.text.trim(), isOpenContinuous: _isOpenContinuous);
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

  void _showEditDialog(Client client) {
    final editNameCtrl = TextEditingController(text: client.name);
    final editPhoneCtrl = TextEditingController(text: client.phone);
    final editAddressCtrl = TextEditingController(text: client.address);
    final editCityCtrl = TextEditingController(text: client.city);
    final editNicknameCtrl = TextEditingController(text: client.nickname);
    bool _isOpenContinuous = client.isOpenContinuous;

    showDialog(
      context: context,
      builder: (context) {
        bool _isSaving = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              title: const Text("Editar Cliente"),
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
                title: const Text("Abre de corrido ☀️"),
                value: _isOpenContinuous,
                activeColor: AppTheme.primaryYellow,
                onChanged: (val) => setStateDialog(() => _isOpenContinuous = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: _isSaving ? null : () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: AppTheme.textSecondary))),
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
                    isOpenContinuous: _isOpenContinuous,
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 800;

        final searchBar = SizedBox(
          width: isMobile ? double.infinity : 320,
          height: 40,
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
            cursorColor: Colors.black,
            decoration: InputDecoration(
              hintText: 'Buscar cliente...',
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
                const Text("Clientes"),
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
                _buildOrderDropdown(isMobile),
              ],
              IconButton(
                icon: Icon(_isGridView ? Icons.list : Icons.grid_view, color: AppTheme.primaryYellow),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                  PreferencesService().setBool('clients_is_grid', _isGridView);
                },
              ),
              const SizedBox(width: 8),
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
        final allCities = ClientsActions().cities;
        final selectedFilter = ClientsActions().selectedFilterCity;
        return SizedBox(
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
        );
      }
    );
  }

  Widget _buildList(bool isMobile, {bool isPhone = false, bool isTablet = false}) {
    return ListenableBuilder(
      listenable: ClientsActions(),
      builder: (context, child) {
        final today = DateTime.now().toString().substring(0, 10);
        var directoryList = ClientsActions().directoryClients;

        if (_searchQuery.isNotEmpty) {
           directoryList = directoryList.where((c) => 
             c.name.toLowerCase().contains(_searchQuery) || 
             c.address.toLowerCase().contains(_searchQuery) ||
             c.city.toLowerCase().contains(_searchQuery) ||
             c.nickname.toLowerCase().contains(_searchQuery)
           ).toList();
        }

        // Separar pendientes de visitados
        final pending = directoryList.where((c) {
          bool isVisited = c.lastVisitDate == today && c.lastVisitStatus.isNotEmpty;
          return !isVisited;
        }).toList();

        final visited = directoryList.where((c) {
          bool isVisited = c.lastVisitDate == today && c.lastVisitStatus.isNotEmpty;
          return isVisited;
        }).toList();

        // Comparador según orden seleccionado
        int Function(Client, Client) comparator;
        if (_selectedOrder == 'A-Z') {
          comparator = (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase());
        } else if (_selectedOrder == 'Z-A') {
          comparator = (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase());
        } else { // 'Saldo'
          comparator = (a, b) => b.balance.compareTo(a.balance);
        }

        pending.sort(comparator);
        visited.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())); // Los visitados al fondo ordenados alfabéticamente

        final clients = [...pending, ...visited];
        final allCities = ClientsActions().cities;
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
                    hintText: 'Buscar cliente...',
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
              const SizedBox(height: 8),
              _buildOrderDropdown(isMobile),
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
                          hintText: 'Buscar cliente...',
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
                  const SizedBox(width: 12),
                  Expanded(child: _buildCityDropdown(isMobile, allCities, selectedFilter)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildOrderDropdown(isMobile)),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: clients.isEmpty
                  ? const Center(child: Text("No hay clientes en esta vista.", style: TextStyle(color: AppTheme.textSecondary)))
                  : (!_isGridView
                      ? ListView.builder(
                          itemCount: clients.length,
                          itemBuilder: (context, index) => _buildClientCard(clients[index], isMobile, false, isPhone: isPhone),
                        )
                      : GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isPhone ? 1 : (isMobile ? 2 : 3),
                            childAspectRatio: isPhone ? 2.8 : (isMobile ? 1.5 : 2.2),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: clients.length,
                          itemBuilder: (context, index) => _buildClientCard(clients[index], isMobile, true, isPhone: isPhone),
                        )),
            ),
            if (clients.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryYellow),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _showAddDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryYellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.person_add, size: 20),
                      label: const Text("Agregar Cliente", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!isPhone) const Text("TOTAL ADEUDADO: ", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                          Text(fmt.format(totalDebt), style: TextStyle(fontSize: isPhone ? 18 : 22, fontWeight: FontWeight.w900, color: totalDebt > 0 ? AppTheme.danger : Colors.greenAccent)),
                        ],
                      ),
                    ),
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
                                     : const Icon(Icons.person, color: AppTheme.primaryYellow, size: 20),
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
                          icon: Icon(Icons.edit, color: visitedToday ? Colors.grey : AppTheme.primaryYellow, size: 18),
                          onPressed: () => _showEditDialog(client),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        ),
                        const SizedBox(width: 8),
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
                               : Icon(Icons.person, color: AppTheme.primaryYellow, size: isPhone ? 20 : 24),
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
                      Text(
                        fmt.format(client.balance),
                        style: TextStyle(
                          fontWeight: FontWeight.w900, 
                          fontSize: isPhone ? 13 : 15,
                          color: client.balance > 0 ? AppTheme.danger : Colors.greenAccent
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                        IconButton(
                          icon: Icon(Icons.edit, color: visitedToday ? Colors.grey : AppTheme.primaryYellow, size: isPhone ? 16 : 20),
                          onPressed: () => _showEditDialog(client),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: visitedToday ? Colors.grey : AppTheme.danger, size: isPhone ? 16 : 20),
                          onPressed: () => _handleDeleteClient(context, client),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
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

    // Modo Lista
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
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
                         : Icon(Icons.person, color: AppTheme.primaryYellow, size: isPhone ? 18 : 24),
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
                          InkWell(
                            onTap: () {
                              ClientsActions().toggleOpenContinuous(client.id, client.isOpenContinuous);
                            },
                            child: Icon(
                              Icons.access_time, 
                              color: AppTheme.primaryYellow,
                              size: isPhone ? 12 : 16
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Cierra Mediodía", 
                            style: TextStyle(
                              color: visitedToday ? Colors.grey : AppTheme.primaryYellow, 
                              fontSize: isPhone ? 10 : 12, 
                              fontWeight: FontWeight.bold
                            )
                          ),
                        ] else ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              ClientsActions().toggleOpenContinuous(client.id, client.isOpenContinuous);
                            },
                            child: Icon(
                              Icons.store, 
                              color: AppTheme.textSecondary,
                              size: isPhone ? 12 : 16
                            ),
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
                  IconButton(
                    icon: Icon(Icons.edit, color: visitedToday ? Colors.grey : AppTheme.primaryYellow, size: isPhone ? 16 : 20),
                    onPressed: () => _showEditDialog(client),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: visitedToday ? Colors.grey : AppTheme.danger, size: isPhone ? 16 : 20),
                    onPressed: () => _handleDeleteClient(context, client),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDeleteClient(BuildContext context, Client client) async {
    final fmt = NumberFormat.currency(locale: 'es_ES', symbol: '\$', decimalDigits: 0);
    // 1. Verificar saldo
    if (client.balance != 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.danger),
              const SizedBox(width: 8),
              const Text("Saldo Pendiente", style: TextStyle(color: AppTheme.danger)),
            ],
          ),
          content: Text(
            "Este cliente tiene saldo pendiente (${fmt.format(client.balance)}). No se puede eliminar, pero podés ocultarlo para que no figure en los repartos.",
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar", style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow, foregroundColor: Colors.black),
              onPressed: () async {
                Navigator.pop(ctx);
                await ClientsActions().hideClient(client.id);
              },
              child: const Text("OCULTAR", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    // 2. Si el saldo es cero, consultar colecciones sales y payments en Firestore
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        content: Row(
          children: [
            CircularProgressIndicator(color: AppTheme.primaryYellow),
            SizedBox(width: 20),
            Text("Verificando historial...", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    try {
      final firestore = FirebaseFirestore.instance;
      final salesQuery = await firestore
          .collection('sales')
          .where('clientId', isEqualTo: client.id)
          .limit(1)
          .get();
      final paymentsQuery = await firestore
          .collection('payments')
          .where('clientId', isEqualTo: client.id)
          .limit(1)
          .get();

      if (context.mounted) {
        Navigator.pop(context);
      }

      final hasHistory = salesQuery.docs.isNotEmpty || paymentsQuery.docs.isNotEmpty;

      if (hasHistory) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: const Row(
              children: [
                Icon(Icons.history, color: AppTheme.primaryYellow),
                SizedBox(width: 8),
                Text("Cliente con Historial", style: TextStyle(color: AppTheme.primaryYellow)),
              ],
            ),
            content: const Text(
              "Este cliente tiene historial de ventas o pagos registrado. No se puede eliminar por seguridad, pero podés ocultarlo.",
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancelar", style: TextStyle(color: AppTheme.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow, foregroundColor: Colors.black),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ClientsActions().hideClient(client.id);
                },
                child: const Text("OCULTAR", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: const Row(
              children: [
                Icon(Icons.delete_forever, color: AppTheme.danger),
                SizedBox(width: 8),
                Text("Eliminar Cliente", style: TextStyle(color: AppTheme.danger)),
              ],
            ),
            content: Text(
              "¿Estás seguro que deseas eliminar de forma permanente a ${client.name}?",
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancelar", style: TextStyle(color: AppTheme.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx);
                  ClientsActions().deleteClient(client.id);
                },
                child: const Text("ELIMINAR", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al verificar historial: $e")),
        );
      }
    }
  }
}

