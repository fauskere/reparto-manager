import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../widgets/custom_header_filter_bar.dart';
import '../inventory/inventory_actions.dart';
import '../truck_load/truck_load_settings.dart';
import 'v2/clients_actions_v2.dart';
import 'client.dart';

class PriceCatalogView extends StatefulWidget {
  const PriceCatalogView({super.key});

  @override
  State<PriceCatalogView> createState() => _PriceCatalogViewState();
}

class _PriceCatalogViewState extends State<PriceCatalogView> {
  String _searchQuery = '';
  bool _isResellerMode = true; // true: Revendedores / Mayoristas, false: Clientes / Público
  String? _selectedClientId;
  final Set<String> _selectedCategories = {};

  void _showClientSearchDialog(List<Client> candidates) {
    String searchDialogQ = '';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              final filtered = candidates.where((c) {
                if (searchDialogQ.isEmpty) return true;
                final q = searchDialogQ.toLowerCase();
                return c.name.toLowerCase().contains(q) || c.city.toLowerCase().contains(q);
              }).toList();

              return Container(
                width: 450,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isResellerMode ? "Asignar Revendedor" : "Asignar Cliente",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryYellow),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      autofocus: true,
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                      cursorColor: Colors.black,
                      decoration: InputDecoration(
                        hintText: 'Escribí el nombre o ciudad...',
                        hintStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Colors.black, size: 18),
                        isDense: true,
                        filled: true,
                        fillColor: AppTheme.primaryYellow,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) => setStateDialog(() => searchDialogQ = val),
                    ),
                    const SizedBox(height: 12),
                    // Opción Ninguno (Globales)
                    InkWell(
                      onTap: () {
                        setState(() => _selectedClientId = null);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedClientId == null ? AppTheme.primaryYellow.withOpacity(0.2) : Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _selectedClientId == null ? AppTheme.primaryYellow : Colors.white10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.public, color: AppTheme.primaryYellow, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isResellerMode ? "🌐 Precios Mayoristas Globales (Sin asignar)" : "🌐 Precios Públicos Globales (Sin asignar)",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            if (_selectedClientId == null)
                              const Icon(Icons.check_circle, color: AppTheme.primaryYellow, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 4),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text("No se encontraron coincidencias.", style: TextStyle(color: Colors.white54)))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final client = filtered[index];
                                final isSelected = _selectedClientId == client.id;
                                return ListTile(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  selected: isSelected,
                                  selectedTileColor: AppTheme.primaryYellow.withOpacity(0.15),
                                  leading: const Icon(Icons.person, color: AppTheme.primaryYellow),
                                  title: Text(client.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: Text("${client.city} • ${client.customPrices.length} precios configurados", style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                  trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryYellow) : null,
                                  onTap: () {
                                    setState(() => _selectedClientId = client.id);
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
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

  @override
  Widget build(BuildContext context) {
    final allClients = ClientsActionsV2().allClients;
    
    final candidates = allClients.where((c) {
      if (c.hidden) return false;
      bool typeMatch = _isResellerMode ? (c.type == 'revendedor') : (c.type != 'revendedor');
      return typeMatch && c.customPrices.isNotEmpty;
    }).toList();

    candidates.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    Client? selectedClient;
    if (_selectedClientId != null) {
      selectedClient = candidates.firstWhere(
        (c) => c.id == _selectedClientId,
        orElse: () => candidates.isNotEmpty ? candidates.first : candidates.first,
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text("Catálogo de Precios"),
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
      ),
      body: Column(
        children: [
          // PANEL SUPERIOR DE CONTROLES: SWITCH + BOTÓN BUSCADOR ASIGNAR CLIENTE + BUSCADOR PRODUCTOS
          Container(
            color: AppTheme.surfaceDark,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    // SWITCH TIPO DE PRECIO
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.primaryYellow.withOpacity(0.4)),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _isResellerMode = false;
                                    _selectedClientId = null;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: !_isResellerMode ? AppTheme.primaryYellow : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "CLIENTES (Público)",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: !_isResellerMode ? Colors.black : Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _isResellerMode = true;
                                    _selectedClientId = null;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _isResellerMode ? AppTheme.primaryYellow : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "REVENDEDORES",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: _isResellerMode ? Colors.black : Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // BOTÓN DE BÚSQUEDA / ASIGNACIÓN RÁPIDA DE CLIENTE CON AUTOFOCUS
                    Expanded(
                      flex: 5,
                      child: InkWell(
                        onTap: () => _showClientSearchDialog(candidates),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: selectedClient != null ? AppTheme.primaryYellow.withOpacity(0.15) : Colors.black45,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selectedClient != null ? AppTheme.primaryYellow : Colors.white24,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selectedClient != null ? Icons.person : Icons.search,
                                color: AppTheme.primaryYellow,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  selectedClient != null
                                      ? "${selectedClient.name} (${selectedClient.city})"
                                      : (_isResellerMode ? "Asignar Revendedor..." : "Asignar Cliente..."),
                                  style: TextStyle(
                                    color: selectedClient != null ? AppTheme.primaryYellow : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: AppTheme.primaryYellow, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CustomHeaderFilterBar(
                  showSearchBar: true,
                  searchQuery: _searchQuery,
                  onSearchChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  searchHint: 'Buscar producto en el catálogo...',
                  showZoneFilter: false,
                  anchorDate: DateTime.now(),
                  customTrailingWidgets: [
                    ElevatedButton.icon(
                      onPressed: () {
                        final allProds = InventoryActions().products;
                        final Set<String> categories = allProds.map((p) => p.category.trim().isEmpty ? 'Sin Categoría / Otros' : p.category.trim()).toSet();
                        categories.add('Sin Categoría / Otros');
                        final sortedCatList = categories.toList()..sort();

                        showDialog(
                          context: context,
                          builder: (ctx) {
                            return StatefulBuilder(
                              builder: (ctx, setStateFilter) {
                                return AlertDialog(
                                  backgroundColor: AppTheme.surfaceDark,
                                  title: const Text("Filtrar por Categorías", style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold)),
                                  content: SizedBox(
                                    width: 320,
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            dense: true,
                                            title: const Text("Todas las Categorías", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                            trailing: IconButton(
                                              icon: Icon(
                                                _selectedCategories.isEmpty ? Icons.check_box : Icons.check_box_outline_blank,
                                                color: AppTheme.primaryYellow,
                                              ),
                                              onPressed: () {
                                                setState(() => _selectedCategories.clear());
                                                setStateFilter(() {});
                                              },
                                            ),
                                          ),
                                          const Divider(color: Colors.white24),
                                          ...sortedCatList.map((cat) {
                                            final isChecked = _selectedCategories.contains(cat);
                                            return CheckboxListTile(
                                              dense: true,
                                              activeColor: AppTheme.primaryYellow,
                                              checkColor: Colors.black,
                                              title: Text(cat, style: const TextStyle(color: Colors.white)),
                                              value: isChecked,
                                              onChanged: (val) {
                                                setState(() {
                                                  if (val == true) {
                                                    _selectedCategories.add(cat);
                                                  } else {
                                                    _selectedCategories.remove(cat);
                                                  }
                                                });
                                                setStateFilter(() {});
                                              },
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text("CERRAR", style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                      icon: Icon(
                        _selectedCategories.isEmpty ? Icons.filter_list : Icons.filter_alt,
                        color: Colors.black,
                        size: 16,
                      ),
                      label: Text(
                        _selectedCategories.isEmpty ? "Categorías" : "Categorías (${_selectedCategories.length})",
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryYellow,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // LISTA EN 2 COLUMNAS DE ALTO FIJO COMPACTO (IDEAL CAPTURAS DE PANTALLA)
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([InventoryActions(), TruckLoadSettings(), ClientsActionsV2()]),
              builder: (context, child) {
                final inventoryUnsorted = InventoryActions().products;
                final inventory = List<Product>.from(inventoryUnsorted);
                
                final settings = TruckLoadSettings();
                if (settings.sortMethod == 'Personalizado' && settings.customOrder.isNotEmpty) {
                  inventory.sort((a, b) {
                    int idxA = settings.customOrder.indexOf(a.id);
                    int idxB = settings.customOrder.indexOf(b.id);
                    if (idxA == -1 && idxB == -1) return a.name.compareTo(b.name);
                    if (idxA == -1) return 1;
                    if (idxB == -1) return -1;
                    return idxA.compareTo(idxB);
                  });
                }

                final List<Map<String, dynamic>> items = [];
                for (var prod in inventory) {
                  final catName = prod.category.trim().isEmpty ? 'Sin Categoría / Otros' : prod.category.trim();
                  bool matchesCategory = _selectedCategories.isEmpty || _selectedCategories.contains(catName);
                  if (!matchesCategory) continue;

                  if (prod.variants.isEmpty) {
                    final key = prod.id;
                    final double normalP = prod.price.toDouble();
                    final double globalRoleP = (_isResellerMode 
                        ? (prod.resellerPrice ?? prod.specialPrice ?? prod.price)
                        : (selectedClient?.type == 'especial' ? (prod.specialPrice ?? prod.price) : prod.price)).toDouble();

                    final double? customP = selectedClient?.customPrices[key];
                    final double effectiveP = customP ?? globalRoleP;

                    if (_searchQuery.isEmpty || prod.name.toLowerCase().contains(_searchQuery)) {
                      items.add({
                        'name': prod.name,
                        'category': prod.category,
                        'normalPrice': normalP,
                        'effectivePrice': effectiveP,
                        'isCustomized': customP != null,
                      });
                    }
                  } else {
                    for (var v in prod.variants) {
                      final key = '${prod.id}_${v.name}';
                      final vName = '${prod.name} (${v.name})';
                      final double normalP = (v.price ?? prod.price).toDouble();
                      final double globalRoleP = (_isResellerMode
                          ? (v.resellerPrice ?? v.specialPrice ?? v.price ?? prod.price)
                          : (selectedClient?.type == 'especial' ? (v.specialPrice ?? v.price ?? prod.price) : (v.price ?? prod.price))).toDouble();

                      final double? customP = selectedClient?.customPrices[key];
                      final double effectiveP = customP ?? globalRoleP;

                      if (_searchQuery.isEmpty || vName.toLowerCase().contains(_searchQuery)) {
                        items.add({
                          'name': vName,
                          'category': prod.category,
                          'normalPrice': normalP,
                          'effectivePrice': effectiveP,
                          'isCustomized': customP != null,
                        });
                      }
                    }
                  }
                }

                if (items.isEmpty) {
                  return const Center(
                    child: Text("No se encontraron productos.", style: TextStyle(color: AppTheme.textSecondary)),
                  );
                }

                // Pares de 2 en 2 para garantizar 2 columnas paralelas compactas de alto fijo natural
                final List<List<Map<String, dynamic>>> pairedItems = [];
                for (int i = 0; i < items.length; i += 2) {
                  if (i + 1 < items.length) {
                    pairedItems.add([items[i], items[i + 1]]);
                  } else {
                    pairedItems.add([items[i]]);
                  }
                }

                final fmt = NumberFormat.currency(locale: 'es_ES', symbol: '\$', decimalDigits: 0);

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  itemCount: pairedItems.length,
                  itemBuilder: (context, index) {
                    final pair = pairedItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        children: [
                          Expanded(child: _buildCatalogTile(pair[0], selectedClient, fmt)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: pair.length > 1
                                ? _buildCatalogTile(pair[1], selectedClient, fmt)
                                : const SizedBox(),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogTile(Map<String, dynamic> item, Client? selectedClient, NumberFormat fmt) {
    final bool isCustomized = item['isCustomized'] as bool;
    final double effectivePrice = item['effectivePrice'] as double;
    final double normalPrice = item['normalPrice'] as double;

    return Container(
      decoration: BoxDecoration(
        color: isCustomized ? AppTheme.surfaceDark : AppTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCustomized ? AppTheme.primaryYellow : Colors.white10,
          width: isCustomized ? 1.2 : 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(
            isCustomized ? Icons.star : Icons.sell_outlined,
            color: isCustomized ? AppTheme.primaryYellow : Colors.greenAccent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item['category'],
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                fmt.format(effectivePrice),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: isCustomized ? AppTheme.primaryYellow : Colors.greenAccent,
                ),
              ),
              if (!_isResellerMode && effectivePrice != normalPrice && isCustomized)
                Text(
                  "Púb: ${fmt.format(normalPrice)}",
                  style: const TextStyle(fontSize: 10, color: Colors.white54),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
