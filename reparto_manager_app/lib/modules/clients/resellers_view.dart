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
import 'special_client_price_global_view.dart';
import '../shell/app_drawer.dart';
import '../truck_load/truck_load_settings.dart';

class ResellersView extends StatefulWidget {
  const ResellersView({super.key});

  @override
  State<ResellersView> createState() => _ResellersViewState();
}

class _ResellersViewState extends State<ResellersView> {
  String _selectedFormCity = '';
  bool _isEnteringNewCity = false;
  String _searchQuery = '';
  late bool _isGridView;

  @override
  void initState() {
    super.initState();
    _isGridView = PreferencesService().getBool('resellers_is_grid') ?? true;
    // Limpiar filtro de ciudades al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ClientsActions().setFilterCity(null);
    });
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final nicknameController = TextEditingController();
    final newCityController = TextEditingController();
    bool isOpenContinuous = false;
    
    final cities = ClientsActions().resellerCities;
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
            final cities = ClientsActions().resellerCities;
            if (!_isEnteringNewCity && _selectedFormCity.isNotEmpty && !cities.contains(_selectedFormCity)) {
              _selectedFormCity = '';
            }
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              title: const Text("Nuevo Revendedor"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre / Negocio',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
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
                        decoration: const InputDecoration(
                          labelText: 'Ciudad',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        value: _selectedFormCity.isEmpty && cities.isNotEmpty
                            ? cities.first
                            : (_selectedFormCity.isEmpty ? null : _selectedFormCity),
                        items: [
                          ...cities.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))),
                          const DropdownMenuItem<String>(
                            value: 'NEW_CITY',
                            child: Text('+ Agregar nueva ciudad', style: TextStyle(color: AppTheme.primaryYellow)),
                          ),
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
                      decoration: const InputDecoration(
                        labelText: 'DirecciÃ³n',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nicknameController,
                      decoration: const InputDecoration(
                        labelText: 'Apodo (Oculto, Ãºtil para buscar)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'TelÃ©fono',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text("Cancelar", style: TextStyle(color: AppTheme.textSecondary)),
                ),
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
                      await ClientsActions().addClient(
                        name,
                        phone,
                        city,
                        address,
                        nickname: nicknameController.text.trim(),
                        isOpenContinuous: isOpenContinuous,
                        type: 'revendedor',
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
              title: const Text("Editar Revendedor"),
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
                    decoration: const InputDecoration(labelText: 'DirecciÃ³n', prefixIcon: Icon(Icons.location_on)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: editNicknameCtrl,
                    decoration: const InputDecoration(labelText: 'Apodo (Oculto, Ãºtil para buscar)', prefixIcon: Icon(Icons.badge)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: editPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'TelÃ©fono', prefixIcon: Icon(Icons.phone)),
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
                        type: 'revendedor',
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
        final searchBar = SizedBox(
          width: isMobile ? double.infinity : 350,
          height: 40,
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
            cursorColor: Colors.black,
            decoration: InputDecoration(
              hintText: 'Buscar revendedor...',
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
                const Text("Revendedores"),
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
                  PreferencesService().setBool('resellers_is_grid', _isGridView);
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
        final allCities = ClientsActions().resellerCities;
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
        var clientsList = List<Client>.from(ClientsActions().resellerClients);
        clientsList.sort((a, b) => a.name.compareTo(b.name));

        if (_searchQuery.isNotEmpty) {
           clientsList = clientsList.where((c) => 
             c.name.toLowerCase().contains(_searchQuery) || 
             c.address.toLowerCase().contains(_searchQuery) ||
             c.city.toLowerCase().contains(_searchQuery) ||
             c.nickname.toLowerCase().contains(_searchQuery)
           ).toList();
        }
        final clients = clientsList;
        final allCities = ClientsActions().resellerCities;
        final selectedFilter = ClientsActions().selectedFilterCity;
        
        final searchBar = SizedBox(
          width: isMobile ? double.infinity : 350,
          height: 36,
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
            cursorColor: Colors.black,
            decoration: InputDecoration(
              hintText: 'Buscar revendedor...',
              hintStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Colors.black, size: 18),
              isDense: true,
              filled: true,
              fillColor: AppTheme.primaryYellow,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        );

        double totalDebt = clients.fold(0, (sum, c) => sum + c.balance);
        final fmt = NumberFormat.currency(locale: 'es_ES', symbol: '\$', decimalDigits: 0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPhone) ...[
              const Text("Buscar", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              searchBar,
              const SizedBox(height: 12),
              const Text("Filtros", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              _buildCityDropdown(isMobile, allCities, selectedFilter),
              const SizedBox(height: 16),
            ] else if (isMobile || isTablet) ...[
              Row(
                children: [
                  Expanded(child: searchBar),
                  const SizedBox(width: 16),
                  Expanded(child: _buildCityDropdown(isMobile, allCities, selectedFilter)),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: clients.isEmpty
                  ? const Center(child: Text("No hay revendedores registrados.", style: TextStyle(color: AppTheme.textSecondary)))
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryYellow),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showAddDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryYellow,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        icon: const Icon(Icons.person_add, color: Colors.black),
                        label: const Text("Agregar Revendedor", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isMobile) const Text("TOTAL ADEUDADO: ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                          Text(fmt.format(totalDebt), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: totalDebt > 0 ? AppTheme.danger : Colors.greenAccent)),
                        ],
                      ),
                    ],
                  ),
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
                    label: const Text("Lista de Precios Mayorista", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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

    Widget actionButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.price_change, color: AppTheme.primaryYellow, size: isPhone ? 18 : 22),
          tooltip: 'Configurar Precios',
          onPressed: () => _navigateToPriceConfig(client),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        SizedBox(width: isPhone ? 8 : 12),
        IconButton(
          icon: Icon(Icons.edit, color: AppTheme.primaryYellow, size: isPhone ? 18 : 20),
          onPressed: () => _showEditDialog(client),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        SizedBox(width: isPhone ? 8 : 12),
        IconButton(
          icon: Icon(Icons.delete_outline, color: AppTheme.danger, size: isPhone ? 18 : 20),
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
        color: AppTheme.surfaceDark,
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
                          const CircleAvatar(
                            radius: 14,
                            backgroundColor: AppTheme.backgroundDark,
                            child: Icon(Icons.storefront, color: AppTheme.primaryYellow, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              client.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 13,
                                color: AppTheme.textPrimary
                              ), 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        client.city, 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
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
                          icon: const Icon(Icons.edit, color: AppTheme.primaryYellow, size: 18),
                          onPressed: () => _showEditDialog(client),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 18),
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
        color: AppTheme.surfaceDark,
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
                    CircleAvatar(
                      radius: isPhone ? 14 : 16,
                      backgroundColor: AppTheme.backgroundDark,
                      child: Icon(Icons.storefront, color: AppTheme.primaryYellow, size: isPhone ? 18 : 22),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        client.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: isPhone ? 13 : 15,
                          color: AppTheme.textPrimary,
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
                    actionButtons,
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
      color: AppTheme.surfaceDark,
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
              CircleAvatar(
                radius: isPhone ? 14 : 20,
                backgroundColor: AppTheme.backgroundDark,
                child: Icon(Icons.storefront, color: AppTheme.primaryYellow, size: isPhone ? 18 : 24),
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
                        color: AppTheme.textPrimary,
                      ), 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis
                    ),
                    const SizedBox(height: 2),
                    Text(client.city, style: TextStyle(color: AppTheme.textSecondary, fontSize: isPhone ? 11 : 13)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (client.balance != 0)
                    Padding(
                      padding: EdgeInsets.only(right: isPhone ? 8.0 : 16.0),
                      child: Text(
                        fmt.format(client.balance),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: isPhone ? 13 : 20,
                          color: client.balance > 0 ? AppTheme.danger : Colors.greenAccent,
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

  void _navigateToPriceConfig(Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResellerClientPricesView(client: client),
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
            "Este cliente tiene saldo pendiente (${fmt.format(client.balance)}). No se puede eliminar, pero podÃ©s ocultarlo para que no figure en los repartos.",
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
              "Este cliente tiene historial de ventas o pagos registrado. No se puede eliminar por seguridad, pero podÃ©s ocultarlo.",
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
              "Â¿EstÃ¡s seguro que deseas eliminar de forma permanente a ${client.name}?",
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

class ResellerPriceGlobalView extends StatefulWidget {
  const ResellerPriceGlobalView({super.key});

  @override
  State<ResellerPriceGlobalView> createState() => _ResellerPriceGlobalViewState();
}

class _ResellerPriceGlobalViewState extends State<ResellerPriceGlobalView> {
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
        final rPrice = prod.resellerPrice;
        _priceControllers[key] = TextEditingController(
          text: rPrice != null ? rPrice.toStringAsFixed(0) : '',
        );
      } else {
        for (var variant in prod.variants) {
          final key = '${prod.id}_${variant.name}';
          final rPrice = variant.resellerPrice;
          _priceControllers[key] = TextEditingController(
            text: rPrice != null ? rPrice.toStringAsFixed(0) : '',
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

  Future<void> _save() async {
    final inventory = InventoryActions().products;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow)),
    );
    try {
      for (var prod in inventory) {
        if (prod.variants.isEmpty) {
          final key = prod.id;
          final text = _priceControllers[key]?.text.trim() ?? '';
          final double? parsedPrice = text.isNotEmpty ? (double.tryParse(text) ?? 0.0) : null;
          if (parsedPrice != prod.resellerPrice) {
            await InventoryActions().updateResellerPrice(prod.id, parsedPrice, []);
          }
        } else {
          List<ProductVariant> updatedVariants = [];
          bool hasChanges = false;
          for (var variant in prod.variants) {
            final key = '${prod.id}_${variant.name}';
            final text = _priceControllers[key]?.text.trim() ?? '';
            final double? parsedPrice = text.isNotEmpty ? (double.tryParse(text) ?? 0.0) : null;
            if (parsedPrice != variant.resellerPrice) hasChanges = true;
            updatedVariants.add(ProductVariant(
              name: variant.name, price: variant.price, resellerPrice: parsedPrice,
            ));
          }
          if (hasChanges) {
            await InventoryActions().updateResellerPrice(prod.id, prod.resellerPrice, updatedVariants);
          }
        }
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lista de precios mayoristas guardada."), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar: $e"), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Precios Mayoristas Globales"),
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
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.primaryYellow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListenableBuilder(
        listenable: InventoryActions(),
        builder: (context, child) {
          final inventory = InventoryActions().products;
          if (inventory.isEmpty) {
            return const Center(child: Text("El inventario estÃ¡ vacÃ­o."));
          }

          // Generar lista plana de items (producto simple o variante)
          final List<Map<String, dynamic>> items = [];
          for (var prod in inventory) {
            if (prod.variants.isEmpty) {
              items.add({'name': prod.name, 'basePrice': prod.price, 'key': prod.id, 'category': prod.category});
            } else {
              for (var v in prod.variants) {
                items.add({
                  'name': '${prod.name} (${v.name})',
                  'basePrice': v.price ?? prod.price,
                  'key': '${prod.id}_${v.name}',
                  'category': prod.category,
                });
              }
            }
          }

          final filtered = items.where((item) =>
            _searchQuery.isEmpty ||
            (item['name'] as String).toLowerCase().contains(_searchQuery) ||
            (item['category'] as String).toLowerCase().contains(_searchQuery)
          ).toList();

          return Column(
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
                child: _isGridView
                    ? GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.15,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final key = item['key'] as String;
                          final name = item['name'] as String;
                          final basePrice = item['basePrice'] as double;
                          if (!_priceControllers.containsKey(key)) {
                            _priceControllers[key] = TextEditingController();
                          }
                          final controller = _priceControllers[key]!;
                          final hasPrice = controller.text.trim().isNotEmpty;

                          return Card(
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: hasPrice
                                    ? AppTheme.primaryYellow.withOpacity(0.4)
                                    : AppTheme.primaryYellow.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(name,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, height: 1.2),
                                      maxLines: 3, overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text("Normal: \$${basePrice.toStringAsFixed(0)}",
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                  const Spacer(),
                                  TextField(
                                    controller: controller,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                                    style: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 18),
                                    onChanged: (_) => setState(() {}),
                                    decoration: InputDecoration(
                                      prefixText: '\$ ',
                                      prefixStyle: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 18),
                                      hintText: 'Igual al normal',
                                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final key = item['key'] as String;
                          final name = item['name'] as String;
                          final basePrice = item['basePrice'] as double;
                          final controller = _priceControllers[key]!;
                          final hasPrice = controller.text.trim().isNotEmpty;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: hasPrice
                                    ? AppTheme.primaryYellow.withOpacity(0.4)
                                    : AppTheme.primaryYellow.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                        Text("Normal: \$${basePrice.toStringAsFixed(0)}", style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 150,
                                    child: TextField(
                                      controller: controller,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                                      style: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 16),
                                      onChanged: (_) => setState(() {}),
                                      decoration: InputDecoration(
                                        prefixText: '\$ ',
                                        prefixStyle: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold),
                                        hintText: 'Igual al normal',
                                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        filled: true, fillColor: Colors.black26,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
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
                  label: const Text("GUARDAR LISTA DE PRECIOS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬ CatÃ¡logo de precios personalizado para un revendedor especÃ­fico Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
class ResellerClientPricesView extends StatefulWidget {
  final Client client;
  const ResellerClientPricesView({super.key, required this.client});

  @override
  State<ResellerClientPricesView> createState() => _ResellerClientPricesViewState();
}

class _ResellerClientPricesViewState extends State<ResellerClientPricesView> {
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
      type: 'revendedor', customPrices: newCustomPrices,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("CatÃ¡logo y precios actualizados."), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  double _getBasePrice(String key) {
    final parts = key.split('_');
    final prod = InventoryActions().products.firstWhere(
      (p) => p.id == parts[0], orElse: () => Product(id: '', name: '', price: 0));
    if (parts.length > 1 && prod.variants.isNotEmpty) {
      final v = prod.variants.firstWhere(
        (v) => v.name == parts[1], orElse: () => ProductVariant(name: '', price: 0));
      return v.resellerPrice ?? v.price ?? prod.price;
    }
    return prod.resellerPrice ?? prod.price;
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
            Text("CatÃ¡logo: ${widget.client.name}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("$selectedCount producto${selectedCount == 1 ? '' : 's'} seleccionado${selectedCount == 1 ? '' : 's'}",
              style: const TextStyle(fontSize: 12, color: AppTheme.primaryYellow)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view, color: AppTheme.primaryYellow),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save, color: Colors.black),
            label: const Text("GUARDAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.primaryYellow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
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
                final filtered = inventory.where((p) =>
                  _searchQuery.isEmpty ||
                  p.name.toLowerCase().contains(_searchQuery) ||
                  p.category.toLowerCase().contains(_searchQuery)
                ).toList();

                // Construir lista plana de items
                final List<Map<String, dynamic>> items = [];
                for (var prod in filtered) {
                  if (prod.variants.isEmpty) {
                    items.add({'name': prod.name, 'basePrice': (prod.resellerPrice ?? prod.price).toDouble(), 'key': prod.id});
                  } else {
                    for (var v in prod.variants) {
                      items.add({'name': '${prod.name} (${v.name})', 'basePrice': (v.resellerPrice ?? v.price ?? prod.price).toDouble(), 'key': '${prod.id}_${v.name}'});
                    }
                  }
                }

                if (_isGridView) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.15,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) => _buildGridCard(items[index]),
                  );
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) => _buildListRow(items[index]),
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
              label: Text("GUARDAR ($selectedCount seleccionados)",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
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

