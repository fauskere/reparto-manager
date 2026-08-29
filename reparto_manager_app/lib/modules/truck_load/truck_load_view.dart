import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../inventory/inventory_actions.dart';
import '../shell/app_drawer.dart';
import 'truck_load_actions.dart';
import 'truck_load_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TruckLoadView extends StatefulWidget {
  const TruckLoadView({super.key});

  @override
  State<TruckLoadView> createState() => _TruckLoadViewState();
}

class _TruckLoadViewState extends State<TruckLoadView> {
  int _tabIndex = 0; // 0: Gestion de Carga, 1: Historial por Zona
  bool _isEditMode = false;

  // Filters for History
  DateTimeRange? _selectedDateRange;
  String _selectedZoneId = 'all';
  List<Map<String, dynamic>> _zones = [];

  // Dropdown options for History
  String _historyTimeFilter = 'Día';
  DateTime _referenceDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    TruckLoadActions().addListener(_onTruckLoadUpdate);
    TruckLoadSettings().addListener(_onSettingsUpdate);
    _loadZones();
    _setTimeFilter('Semana');
  }

  @override
  void dispose() {
    TruckLoadActions().removeListener(_onTruckLoadUpdate);
    TruckLoadSettings().removeListener(_onSettingsUpdate);
    super.dispose();
  }

  void _onTruckLoadUpdate() {
    if (mounted) setState(() {});
  }

  void _onSettingsUpdate() {
    if (mounted) setState(() {});
  }

  void _updateDateRange() {
    DateTime start;
    DateTime end;

    if (_historyTimeFilter == 'Día') {
      start = DateTime(_referenceDate.year, _referenceDate.month, _referenceDate.day);
      end = DateTime(start.year, start.month, start.day, 23, 59, 59);
    } else if (_historyTimeFilter == 'Semana') {
      int weekday = _referenceDate.weekday;
      start = DateTime(_referenceDate.year, _referenceDate.month, _referenceDate.day).subtract(Duration(days: weekday - 1));
      end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    } else if (_historyTimeFilter == 'Mes') {
      start = DateTime(_referenceDate.year, _referenceDate.month, 1);
      DateTime nextMonth = DateTime(_referenceDate.year, _referenceDate.month + 1, 1);
      end = nextMonth.subtract(const Duration(seconds: 1));
    } else if (_historyTimeFilter == 'Año') {
      start = DateTime(_referenceDate.year, 1, 1);
      end = DateTime(_referenceDate.year, 12, 31, 23, 59, 59);
    } else { // Todo
      start = DateTime(2020);
      end = DateTime.now().add(const Duration(days: 3650));
    }
    _selectedDateRange = DateTimeRange(start: start, end: end);
  }

  void _setTimeFilter(String filter) {
    _historyTimeFilter = filter;
    _updateDateRange();
    setState((){});
  }
  
  void _setReferenceDate(DateTime date) {
    _referenceDate = date;
    _updateDateRange();
    setState((){});
  }

  void _previousPeriod() {
    if (_historyTimeFilter == 'Día') _setReferenceDate(_referenceDate.subtract(const Duration(days: 1)));
    else if (_historyTimeFilter == 'Semana') _setReferenceDate(_referenceDate.subtract(const Duration(days: 7)));
    else if (_historyTimeFilter == 'Mes') _setReferenceDate(DateTime(_referenceDate.year, _referenceDate.month - 1, 1));
    else if (_historyTimeFilter == 'Año') _setReferenceDate(DateTime(_referenceDate.year - 1, 1, 1));
  }

  void _nextPeriod() {
    if (_historyTimeFilter == 'Día') _setReferenceDate(_referenceDate.add(const Duration(days: 1)));
    else if (_historyTimeFilter == 'Semana') _setReferenceDate(_referenceDate.add(const Duration(days: 7)));
    else if (_historyTimeFilter == 'Mes') _setReferenceDate(DateTime(_referenceDate.year, _referenceDate.month + 1, 1));
    else if (_historyTimeFilter == 'Año') _setReferenceDate(DateTime(_referenceDate.year + 1, 1, 1));
  }

  Future<void> _loadZones() async {
    final docs = await FirebaseFirestore.instance.collection('zones').get();
    if (mounted) {
      setState(() {
        _zones = docs.docs.map((d) => {'id': d.id, 'name': d['name'], 'cities': d['cities']}).toList();
      });
    }
  }

  void _confirmClearStock() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Limpiar Carga', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
        content: const Text('¿Estás seguro de que quieres poner toda la carga de la camioneta actual a CERO? Esto no afectará las ventas, pero borrará el stock físico registrado.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              await TruckLoadActions().clearAllStock();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Limpiar Todo', style: TextStyle(color: Colors.white)),
          )
        ],
      )
    );
  }

  List<Product> _getSortedProducts() {
    final settings = TruckLoadSettings();
    List<Product> products = List.from(InventoryActions().products);

    if (settings.sortMethod == 'Personalizado' && settings.customOrder.isNotEmpty) {
      products.sort((a, b) {
        int idxA = settings.customOrder.indexOf(a.id);
        int idxB = settings.customOrder.indexOf(b.id);
        if (idxA == -1 && idxB == -1) return a.name.compareTo(b.name);
        if (idxA == -1) return 1;
        if (idxB == -1) return -1;
        return idxA.compareTo(idxB);
      });
    } else if (settings.sortMethod == 'Nombre') {
      products.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (settings.sortMethod == 'Categoría') {
      products.sort((a, b) => a.category.toLowerCase().compareTo(b.category.toLowerCase()));
    } else if (settings.sortMethod == 'Precio') {
      products.sort((a, b) => a.price.compareTo(b.price));
    }
    return products;
  }

  void _moveProduct(int oldIndex, int newIndex) {
    final settings = TruckLoadSettings();
    List<Product> sorted = _getSortedProducts();
    if (newIndex > oldIndex) newIndex -= 1;
    final item = sorted.removeAt(oldIndex);
    sorted.insert(newIndex, item);
    
    settings.saveCustomOrder(sorted.map((e) => e.id).toList());
  }

  Widget _buildProductCard(Product product, bool isGrid, {int? index}) {
    final truckActions = TruckLoadActions();
    
    return Card(
      color: AppTheme.surfaceDark,
      margin: EdgeInsets.only(bottom: isGrid ? 0 : 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (TruckLoadSettings().sortMethod == 'Personalizado' && !isGrid && _isEditMode)
                  index != null
                      ? ReorderableDragStartListener(
                          index: index,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.grab,
                            child: Container(
                              padding: const EdgeInsets.only(right: 12.0, top: 4, bottom: 4),
                              child: const Icon(Icons.drag_indicator, color: Colors.grey, size: 28),
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.only(right: 12.0, top: 4, bottom: 4),
                          child: const Icon(Icons.drag_indicator, color: Colors.grey, size: 28),
                        ),
                Expanded(child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 8),
            _isEditMode && !isGrid
              ? const SizedBox.shrink()
              : Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: (product.variants.isEmpty ? [{'name': '', 'displayName': 'Única', 'lowStockThreshold': null}] : product.variants.map((v) => {'name': v.name, 'displayName': v.name, 'lowStockThreshold': v.lowStockThreshold})).map((vData) {
                    String vName = vData['name'] as String;
                    String dName = vData['displayName'] as String;
                    int? threshold = vData['lowStockThreshold'] as int?;
                    int? currentStock = truckActions.getStockForVariant(product.id, vName);
                    bool isInfinite = currentStock == null;
                    bool isLowStock = !isInfinite && threshold != null && currentStock <= threshold;
                    
                    return IntrinsicWidth(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (dName != "Única") Text("$dName: ", style: const TextStyle(fontSize: 14)),
                          if (isLowStock)
                            const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.warning_amber, color: AppTheme.danger, size: 14)),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: isInfinite || currentStock == 0 ? null : () => truckActions.updateStock(product.id, vName, -1, 'manual_remove'),
                                child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.remove, color: (isInfinite || currentStock == 0) ? Colors.grey : AppTheme.primaryYellow, size: 24)),
                              ),
                              SizedBox(
                                width: 50,
                                height: 35,
                                child: TextField(
                                  controller: TextEditingController(text: isInfinite ? '∞' : currentStock.toString()),
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isLowStock ? AppTheme.danger : Colors.white),
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.zero,
                                    border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                                    isDense: true,
                                  ),
                                    onSubmitted: (val) {
                                      if (val.trim().isEmpty || val.toLowerCase() == 'inf' || val == '∞' || val.toLowerCase() == 'infinito') {
                                        truckActions.setStockInfinite(product.id, vName);
                                      } else {
                                        int? parsed = int.tryParse(val);
                                        if (parsed != null) {
                                          truckActions.setStock(product.id, vName, parsed);
                                        }
                                      }
                                    },
                                ),
                              ),
                              InkWell(
                                onTap: () => truckActions.updateStock(product.id, vName, 1, 'manual_add'),
                                child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.add, color: AppTheme.primaryYellow, size: 24)),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  }).toList(),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockManagement() {
    final settings = TruckLoadSettings();
    final products = _getSortedProducts();

    if (products.isEmpty) {
      return const Center(child: Text("No hay productos en inventario."));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Vehículo: ${TruckLoadActions().activeTruckId}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryYellow)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                onPressed: _confirmClearStock,
                icon: const Icon(Icons.delete_sweep, color: Colors.white, size: 18),
                label: const Text("Limpiar Carga", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: settings.sortMethod,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, labelText: 'Ordenar por'),
                  items: const [
                    DropdownMenuItem(value: 'Nombre', child: Text('Nombre')),
                    DropdownMenuItem(value: 'Categoría', child: Text('Categoría')),
                    DropdownMenuItem(value: 'Precio', child: Text('Precio')),
                    DropdownMenuItem(value: 'Personalizado', child: Text('Personalizado')),
                  ],
                  onChanged: (val) {
                    if (val != null) settings.setSortMethod(val);
                  },
                ),
              ),
              const SizedBox(width: 8),
              if (settings.sortMethod == 'Personalizado' && !settings.isGridView)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _isEditMode ? AppTheme.primaryYellow : AppTheme.surfaceDark),
                  onPressed: () => setState(() => _isEditMode = !_isEditMode),
                  child: Text(_isEditMode ? 'Guardar' : 'Editar Orden', style: TextStyle(color: _isEditMode ? Colors.black : Colors.white)),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.list, color: !settings.isGridView ? AppTheme.primaryYellow : Colors.grey),
                onPressed: () => settings.setGridView(false),
              ),
              IconButton(
                icon: Icon(Icons.grid_view, color: settings.isGridView ? AppTheme.primaryYellow : Colors.grey),
                onPressed: () => settings.setGridView(true),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: settings.isGridView
              ? GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.8, crossAxisSpacing: 12, mainAxisSpacing: 12),
                  itemCount: products.length,
                  itemBuilder: (context, index) => _buildProductCard(products[index], true),
                )
              : (settings.sortMethod == 'Personalizado'
                  ? ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.all(16),
                      itemCount: products.length,
                      onReorder: _moveProduct,
                      itemBuilder: (context, index) {
                        return Container(
                          key: ValueKey(products[index].id),
                          child: _buildProductCard(products[index], false, index: index),
                        );
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: products.length,
                      itemBuilder: (context, index) => _buildProductCard(products[index], false),
                    )),
        ),
      ],
    );
  }

  Widget _buildHistory() {
    String navText = "Historial";
    if (_historyTimeFilter == 'Día') {
      navText = DateFormat('d MMM yyyy', 'es_ES').format(_referenceDate);
    } else if (_historyTimeFilter == 'Semana') {
      int weekday = _referenceDate.weekday;
      DateTime startOfWeek = DateTime(_referenceDate.year, _referenceDate.month, _referenceDate.day).subtract(Duration(days: weekday - 1));
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
      navText = "${DateFormat('d MMM', 'es_ES').format(startOfWeek)} - ${DateFormat('d MMM yyyy', 'es_ES').format(endOfWeek)}";
    } else if (_historyTimeFilter == 'Mes') {
      navText = DateFormat('MMMM yyyy', 'es_ES').format(_referenceDate).toUpperCase();
    } else if (_historyTimeFilter == 'Año') {
      navText = DateFormat('yyyy', 'es_ES').format(_referenceDate);
    } else {
      navText = "Todo el Historial";
    }

    final today = DateTime.now();
    final isToday = _referenceDate.year == today.year && _referenceDate.month == today.month && _referenceDate.day == today.day;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(color: AppTheme.primaryYellow, borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: AppTheme.primaryYellow,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.black, size: 18),
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                      value: _historyTimeFilter,
                      isExpanded: true,
                      items: ['Día', 'Semana', 'Mes', 'Año', 'Todo'].map((p) => DropdownMenuItem<String>(
                        value: p,
                        child: Text(p, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) _setTimeFilter(val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 6,
                child: DropdownButtonFormField<String>(
                  value: _selectedZoneId,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, labelText: 'Zona de Reparto'),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('Todas las Zonas')),
                    ..._zones.map((z) => DropdownMenuItem(value: z['id'], child: Text(z['name']))),
                  ],
                  onChanged: (val) => setState(() => _selectedZoneId = val!),
                ),
              ),
            ],
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: AppTheme.primaryYellow, borderRadius: BorderRadius.circular(30)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _previousPeriod,
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.calendar_month, color: Colors.black, size: 24),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _referenceDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          initialDatePickerMode: _historyTimeFilter == 'Mes' ? DatePickerMode.year : DatePickerMode.day,
                          locale: const Locale('es', 'ES'),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppTheme.primaryYellow,
                                  onPrimary: Colors.black,
                                  surface: AppTheme.surfaceDark,
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) _setReferenceDate(date);
                      },
                    ),
                    const SizedBox(width: 16),
                    Text(navText, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.black, size: 28),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _nextPeriod,
                    ),
                  ],
                ),
              ),
              if (!isToday) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _setReferenceDate(DateTime.now()),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: AppTheme.primaryYellow.withOpacity(0.2), borderRadius: BorderRadius.circular(30)),
                    child: const Text("HOY", style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ]
            ],
          ),
        ),

        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchHistoryReport(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
              
              final report = snapshot.data ?? [];
              if (report.isEmpty) return const Center(child: Text("No hay datos para este período y zona."));

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: report.length,
                itemBuilder: (context, index) {
                  final row = report[index];
                  bool isLowStockAlert = row['ranOut'] == true;
                  bool salesExceedLoad = row['loadedCount'] > 0 && row['soldCount'] > row['loadedCount'];
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        if (isLowStockAlert || salesExceedLoad)
                          const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(Icons.warning_amber, color: AppTheme.danger, size: 28),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${row['productName']} - ${row['variantName']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: (isLowStockAlert || salesExceedLoad) ? AppTheme.danger : Colors.white)),
                              if (isLowStockAlert)
                                const Text("¡Stock agotado durante venta!", style: TextStyle(color: AppTheme.danger, fontSize: 12)),
                              if (salesExceedLoad && !isLowStockAlert)
                                const Text("Ventas superan la carga", style: TextStyle(color: AppTheme.danger, fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("Vendido: ${row['soldCount']}", style: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("Cargado: ${row['loadedCount'] <= 0 ? 'Sin límite' : row['loadedCount']}", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _fetchHistoryReport() async {
    if (_selectedDateRange == null) return [];
    
    List<String> targetCities = [];
    if (_selectedZoneId != 'all') {
      final zone = _zones.firstWhere((z) => z['id'] == _selectedZoneId, orElse: () => {'cities': []});
      targetCities = List<String>.from(zone['cities']);
    }

    final logsSnap = await FirebaseFirestore.instance.collection('cargo_logs')
      .where('date', isGreaterThanOrEqualTo: _selectedDateRange!.start)
      .where('date', isLessThanOrEqualTo: _selectedDateRange!.end.add(const Duration(days: 1)))
      .get();

    final salesSnap = await FirebaseFirestore.instance.collection('sales')
      .where('date', isGreaterThanOrEqualTo: _selectedDateRange!.start)
      .where('date', isLessThanOrEqualTo: _selectedDateRange!.end.add(const Duration(days: 1)))
      .get();

    Map<String, Map<String, dynamic>> consolidated = {};

    final activeTruck = TruckLoadActions().activeTruckId;
    for (var doc in logsSnap.docs) {
      final data = doc.data();
      if (data['truckId'] != activeTruck) continue;
      
      String key = "${data['productId']}_${data['variantName']}";
      if (!consolidated.containsKey(key)) {
        consolidated[key] = {
          'productId': data['productId'],
          'productName': '???',
          'variantName': data['variantName'],
          'soldCount': 0,
          'loadedCount': 0,
          'ranOut': false,
        };
      }
      if (data['type'] == 'manual_add') {
        consolidated[key]!['loadedCount'] += data['addedQuantity'] as int;
      } else if (data['type'] == 'manual_remove') {
        consolidated[key]!['loadedCount'] += data['addedQuantity'] as int;
      }
    }

    for (var doc in salesSnap.docs) {
      final data = doc.data();
      String city = data['city'] ?? '';
      
      // EXCLUDE RESELLER SALES (Vendedores) FROM TRUCK INVENTORY HISTORY
      if (city.toLowerCase() == 'vendedores') continue;

      if (_selectedZoneId != 'all') {
        bool matchesCity = targetCities.any((c) => c.toLowerCase().trim() == city.toLowerCase().trim());
        if (!matchesCity) continue;
      }

      List items = data['items'] ?? [];
      for (var item in items) {
        String pId = item['productId'] ?? '';
        String vName = item['variantName'] ?? '';
        int qty = item['quantity'] ?? 0;
        String pName = item['productName'] ?? item['name'] ?? 'Producto Desconocido';

        if (vName.isEmpty) continue;
        String key = "${pId}_$vName";
        
        if (!consolidated.containsKey(key)) {
          consolidated[key] = {
            'productId': pId,
            'productName': pName,
            'variantName': vName,
            'soldCount': 0,
            'loadedCount': 0,
            'ranOut': false,
          };
        } else {
          consolidated[key]!['productName'] = pName;
        }

        consolidated[key]!['soldCount'] += qty;
        
        // Simular deteccion de quiebre de stock usando la logica de ventas:
        // En una version ideal de BDD guardariamos si en ese momento quebro stock,
        // pero podemos asumir que si lo actual de la camioneta es 0 o menos, ranOut.
        int? currentStock = TruckLoadActions().getStockForVariant(pId, vName);
        if (currentStock != null && currentStock <= 0) {
          consolidated[key]!['ranOut'] = true;
        }
      }
    }

    final products = InventoryActions().products;
    for (var val in consolidated.values) {
      if (val['productName'] == '???') {
        try {
          val['productName'] = products.firstWhere((p) => p.id == val['productId']).name;
        } catch (_) {
          val['productName'] = 'Eliminado';
        }
      }
    }

    final list = consolidated.values.toList();
    final sortedProducts = _getSortedProducts();
    final sortedIds = sortedProducts.map((p) => p.id).toList();

    list.sort((a, b) {
      int idxA = sortedIds.indexOf(a['productId']);
      int idxB = sortedIds.indexOf(b['productId']);
      if (idxA == -1 && idxB == -1) return a['productName'].compareTo(b['productName']);
      if (idxA == -1) return 1;
      if (idxB == -1) return -1;
      return idxA.compareTo(idxB);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Carga de Camioneta'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tabIndex == 0 ? AppTheme.primaryYellow : AppTheme.surfaceDark,
                      foregroundColor: _tabIndex == 0 ? Colors.black : Colors.white,
                    ),
                    onPressed: () => setState(() => _tabIndex = 0),
                    child: const Text('Gestión de Carga'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tabIndex == 1 ? AppTheme.primaryYellow : AppTheme.surfaceDark,
                      foregroundColor: _tabIndex == 1 ? Colors.black : Colors.white,
                    ),
                    onPressed: () => setState(() => _tabIndex = 1),
                    child: const Text('Historial y Ventas'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _tabIndex == 0 ? _buildStockManagement() : _buildHistory(),
    );
  }
}
