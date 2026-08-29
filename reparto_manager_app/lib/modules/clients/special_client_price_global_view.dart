import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../inventory/inventory_actions.dart';
import 'clients_actions.dart';
import 'client.dart';

class SpecialClientPriceGlobalView extends StatefulWidget {
  final bool isWholesale;
  const SpecialClientPriceGlobalView({super.key, this.isWholesale = false});

  @override
  State<SpecialClientPriceGlobalView> createState() =>
      _SpecialClientPriceGlobalViewState();
}

class _SpecialClientPriceGlobalViewState
    extends State<SpecialClientPriceGlobalView> {
  final Map<String, TextEditingController> _priceControllers = {};
  final Map<String, bool> _selectedProducts = {};
  List<Client> _targetClients = [];
  String _searchQuery = '';
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    final inventory = InventoryActions().products;
    for (var prod in inventory) {
      if (prod.variants.isEmpty) {
        final key = prod.id;
        final rPrice = widget.isWholesale
            ? prod.resellerPrice
            : prod.specialPrice;
        _priceControllers[key] = TextEditingController(
          text: rPrice != null ? rPrice.toStringAsFixed(0) : '',
        );
      } else {
        for (var variant in prod.variants) {
          final key = '${prod.id}_${variant.name}';
          final rPrice = widget.isWholesale
              ? variant.resellerPrice
              : variant.specialPrice;
          _priceControllers[key] = TextEditingController(
            text: rPrice != null ? rPrice.toStringAsFixed(0) : '',
          );
        }
      }
    }
  }

  @override
  void dispose() {
    for (var c in _priceControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _showTargetClientsDialog() {
    final allSpecial = widget.isWholesale
        ? ClientsActions().resellerClients
        : ClientsActions().specialClients;
    List<Client> tempSelected = List.from(_targetClients);
    String searchQ = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final filtered = allSpecial
                .where(
                  (c) =>
                      c.name.toLowerCase().contains(searchQ) ||
                      c.city.toLowerCase().contains(searchQ),
                )
                .toList();
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              title: const Text(
                'Seleccionar Clientes Objetivo',
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: 400,
                height: 400,
                child: Column(
                  children: [
                    Text(
                      'Si no seleccionas ninguno, la lista afectará a TODOS LOS ${widget.isWholesale ? "REVENDEDORES" : "ESPECIALES"} por defecto (Lista Global).',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar sucursal...',
                        filled: true,
                        fillColor: AppTheme.primaryYellow,
                        isDense: true,
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.black,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) =>
                          setStateDialog(() => searchQ = val.toLowerCase()),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final c = filtered[index];
                          final isSel = tempSelected.any((sc) => sc.id == c.id);
                          return CheckboxListTile(
                            activeColor: AppTheme.primaryYellow,
                            checkColor: Colors.black,
                            title: Text(
                              c.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              '${c.city} - ${c.address}',
                              style: const TextStyle(color: Colors.white54),
                            ),
                            value: isSel,
                            onChanged: (val) {
                              setStateDialog(() {
                                if (val == true) {
                                  tempSelected.add(c);
                                } else {
                                  tempSelected.removeWhere(
                                    (sc) => sc.id == c.id,
                                  );
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'CANCELAR',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _targetClients = tempSelected;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('ACEPTAR'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _save() async {
    final inventory = InventoryActions().products;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryYellow),
      ),
    );
    try {
      final batch = FirebaseFirestore.instance.batch();
      if (_targetClients.isEmpty) {
        for (var prod in inventory) {
          if (prod.variants.isEmpty) {
            final key = prod.id;
            final txt = _priceControllers[key]?.text.trim() ?? '';
            if (txt.isNotEmpty &&
                double.tryParse(txt) != null &&
                (_selectedProducts[key] ?? false)) {
              final newP = double.parse(txt);
              if (widget.isWholesale) {
                batch.update(
                  FirebaseFirestore.instance
                      .collection('inventory')
                      .doc(prod.id),
                  {'resellerPrice': newP},
                );
              } else {
                batch.update(
                  FirebaseFirestore.instance
                      .collection('inventory')
                      .doc(prod.id),
                  {'specialPrice': newP},
                );
              }
            }
          } else {
            List<Map<String, dynamic>> updatedVariants = [];
            bool changed = false;
            for (var v in prod.variants) {
              final key = '${prod.id}_${v.name}';
              final txt = _priceControllers[key]?.text.trim() ?? '';
              var map = v.toMap();
              if (txt.isNotEmpty &&
                  double.tryParse(txt) != null &&
                  (_selectedProducts[key] ?? false)) {
                final newP = double.parse(txt);
                if (widget.isWholesale) {
                  map['resellerPrice'] = newP;
                } else {
                  map['specialPrice'] = newP;
                }
                changed = true;
              }
              updatedVariants.add(map);
            }
            if (changed) {
              batch.update(
                FirebaseFirestore.instance.collection('inventory').doc(prod.id),
                {'variants': updatedVariants},
              );
            }
          }
        }
      } else {
        Map<String, double> newPrices = {};
        for (var prod in inventory) {
          if (prod.variants.isEmpty) {
            final text = _priceControllers[prod.id]?.text.trim() ?? '';
            final double? p = text.isNotEmpty ? double.tryParse(text) : null;
            if (_selectedProducts[prod.id] == true) {
              newPrices[prod.id] = p ?? -1;
            }
          } else {
            for (var variant in prod.variants) {
              final key = '${prod.id}_${variant.name}';
              final text = _priceControllers[key]?.text.trim() ?? '';
              final double? p = text.isNotEmpty ? double.tryParse(text) : null;
              if (_selectedProducts[key] == true) {
                newPrices[key] = p ?? -1;
              }
            }
          }
        }
        for (var client in _targetClients) {
          Map<String, double> customP = Map.from(client.customPrices);
          for (var entry in newPrices.entries) {
            if (entry.value == -1) {
              customP.remove(entry.key);
            } else {
              customP[entry.key] = entry.value;
            }
          }
          final ref = FirebaseFirestore.instance
              .collection('clients')
              .doc(client.id);
          batch.update(ref, {'customPrices': customP});
        }
      }

      await batch.commit();

      if (mounted) {
        Navigator.pop(context); // Cierra loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _targetClients.isEmpty
                  ? 'Lista de precios globales guardada.'
                  : 'Precios actualizados para ${_targetClients.length} sucursales.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Cierra vista
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  void _toggle(String key, double basePrice) {
    setState(() {
      _selectedProducts[key] = !(_selectedProducts[key] ?? false);
      if (_selectedProducts[key] == true &&
          _priceControllers[key]!.text.isEmpty) {
        _priceControllers[key]!.text = basePrice.toStringAsFixed(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int selectedCount = _selectedProducts.values.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isWholesale ? 'Precios Mayoristas' : 'Precios Especiales',
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.list : Icons.grid_view,
              color: AppTheme.primaryYellow,
            ),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'Ver como lista' : 'Ver como cuadrilla',
          ),
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save, color: Colors.black),
            label: const Text(
              'GUARDAR',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.primaryYellow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Container(
        color: AppTheme.backgroundDark,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppTheme.surfaceDark,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Afectando a:',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        Text(
                          _targetClients.isEmpty
                              ? (widget.isWholesale
                                    ? 'GLOBAL (Todos los revendedores)'
                                    : 'GLOBAL (Todos los especiales)')
                              : '${_targetClients.length} sucursales seleccionadas',
                          style: const TextStyle(
                            color: AppTheme.primaryYellow,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showTargetClientsDialog,
                    icon: const Icon(
                      Icons.people,
                      color: Colors.black,
                      size: 18,
                    ),
                    label: const Text(
                      'Seleccionar Destino',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (val) =>
                    setState(() => _searchQuery = val.toLowerCase()),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar producto...',
                  hintStyle: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.black),
                  filled: true,
                  fillColor: AppTheme.primaryYellow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: InventoryActions(),
                builder: (context, _) {
                  final inventory = InventoryActions().products;
                  final filtered = inventory
                      .where(
                        (p) =>
                            _searchQuery.isEmpty ||
                            p.name.toLowerCase().contains(_searchQuery) ||
                            p.category.toLowerCase().contains(_searchQuery),
                      )
                      .toList();

                  final List<Map<String, dynamic>> items = [];
                  for (var prod in filtered) {
                    if (prod.variants.isEmpty) {
                      items.add({
                        'name': prod.name,
                        'basePrice': (prod.specialPrice ?? prod.price)
                            .toDouble(),
                        'key': prod.id,
                      });
                    } else {
                      for (var v in prod.variants) {
                        items.add({
                          'name': '${prod.name} (${v.name})',
                          'basePrice': (v.specialPrice ?? v.price ?? prod.price)
                              .toDouble(),
                          'key': '${prod.id}_${v.name}',
                        });
                      }
                    }
                  }

                  if (_isGridView) {
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.15,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: items.length,
                      itemBuilder: (context, index) =>
                          _buildGridCard(items[index]),
                    );
                  } else {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (context, index) =>
                          _buildListRow(items[index]),
                    );
                  }
                },
              ),
            ),
            if (selectedCount > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: AppTheme.surfaceDark,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save, color: Colors.black),
                  label: Text(
                    'GUARDAR ($selectedCount seleccionados)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(Map<String, dynamic> item) {
    final key = item['key'] as String;
    final name = item['name'] as String;
    final basePrice = item['basePrice'] as double;
    if (!_selectedProducts.containsKey(key)) {
      _selectedProducts[key] = false;
      _priceControllers[key] ??= TextEditingController();
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
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                  ),
                  style: const TextStyle(
                    color: AppTheme.primaryYellow,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    prefixStyle: const TextStyle(
                      color: AppTheme.primaryYellow,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                    hintText: basePrice.toStringAsFixed(0),
                    hintStyle: const TextStyle(
                      color: Colors.white24,
                      fontSize: 18,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 4,
                    ),
                    border: InputBorder.none,
                  ),
                )
              else
                Text(
                  '\$${basePrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    color: AppTheme.primaryYellow,
                    fontWeight: FontWeight.w900,
                  ),
                ),
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
      _priceControllers[key] ??= TextEditingController();
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
              Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? AppTheme.primaryYellow : Colors.white24,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (isSelected)
                SizedBox(
                  width: 130,
                  child: TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: false,
                    ),
                    style: const TextStyle(
                      color: AppTheme.primaryYellow,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      prefixStyle: const TextStyle(
                        color: AppTheme.primaryYellow,
                        fontWeight: FontWeight.bold,
                      ),
                      hintText: basePrice.toStringAsFixed(0),
                      hintStyle: const TextStyle(color: Colors.white24),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                )
              else
                Text(
                  '\$${basePrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
