import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme.dart';
import '../../../core/preferences_service.dart';
import '../../../models/product.dart';
import '../../inventory/inventory_actions.dart';
import '../client.dart';
import 'clients_actions_v2.dart';

class ClientPriceListViewV2 extends StatefulWidget {
  final Client client;

  const ClientPriceListViewV2({super.key, required this.client});

  @override
  State<ClientPriceListViewV2> createState() => _ClientPriceListViewV2State();
}

class _ClientPriceListViewV2State extends State<ClientPriceListViewV2> {
  late Client _currentClient;
  String _searchQuery = '';
  bool _isEditing = false;
  bool _isGridView = true;
  final Map<String, TextEditingController> _priceControllers = {};
  final Map<String, bool> _selectedProducts = {};

  // Regla de Ajuste Masivo Rápido
  String _massRuleBase = 'normal'; // 'normal' (Precio Público Común) o 'globalRole' (Precio Global de Rol)
  String _massRuleType = 'fixed'; // 'fixed' ($ monto fijo) o 'percent' (% porcentaje)
  final TextEditingController _massRuleValueController = TextEditingController(text: '-200');

  @override
  void initState() {
    super.initState();
    _currentClient = widget.client;
    _isGridView = PreferencesService().getBool('client_price_list_is_grid') ?? true;
    _initEditState();
  }

  void _initEditState() {
    final inventory = InventoryActions().products;
    final bool isWholesale = _currentClient.type == 'revendedor';
    final bool isSpecialRole = _currentClient.type == 'especial';
    final bool hasCustomPrices = _currentClient.customPrices.isNotEmpty;

    for (var prod in inventory) {
      if (prod.variants.isEmpty) {
        final key = prod.id;
        final currentP = _currentClient.customPrices[key];
        final bool hasResellerP = prod.resellerPrice != null && prod.resellerPrice! > 0;
        final bool hasSpecialP = prod.specialPrice != null && prod.specialPrice! > 0;

        final double defaultRoleP = (isWholesale
                ? (prod.resellerPrice ?? prod.specialPrice ?? prod.price)
                : (isSpecialRole
                    ? (prod.specialPrice ?? prod.price)
                    : prod.price))
            .toDouble();

        if (hasCustomPrices) {
          _selectedProducts[key] = currentP != null;
        } else {
          _selectedProducts[key] = isWholesale ? hasResellerP : (isSpecialRole ? hasSpecialP : true);
        }

        _priceControllers[key] = TextEditingController(
          text: (currentP ?? defaultRoleP).toStringAsFixed(0),
        );
      } else {
        for (var variant in prod.variants) {
          final key = '${prod.id}_${variant.name}';
          final currentP = _currentClient.customPrices[key];
          final bool hasResellerP = variant.resellerPrice != null && variant.resellerPrice! > 0;
          final bool hasSpecialP = variant.specialPrice != null && variant.specialPrice! > 0;

          final double defaultRoleP = (isWholesale
                  ? (variant.resellerPrice ?? variant.specialPrice ?? variant.price ?? prod.price)
                  : (isSpecialRole
                      ? (variant.specialPrice ?? variant.price ?? prod.price)
                      : (variant.price ?? prod.price)))
              .toDouble();

          if (hasCustomPrices) {
            _selectedProducts[key] = currentP != null;
          } else {
            _selectedProducts[key] = isWholesale ? hasResellerP : (isSpecialRole ? hasSpecialP : true);
          }

          _priceControllers[key] = TextEditingController(
            text: (currentP ?? defaultRoleP).toStringAsFixed(0),
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
    _massRuleValueController.dispose();
    super.dispose();
  }

  void _reloadClientData() {
    final updated = ClientsActionsV2().allClients.firstWhere(
      (c) => c.id == _currentClient.id,
      orElse: () => _currentClient,
    );
    setState(() {
      _currentClient = updated;
      _initEditState();
    });
  }

  void _applyMassRule(List<Map<String, dynamic>> allItems) {
    final text = _massRuleValueController.text.trim().replaceAll(',', '.');
    final double? val = double.tryParse(text);
    if (val == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresá un valor válido (ej: -200 o -10)"), backgroundColor: AppTheme.danger),
      );
      return;
    }

    int appliedCount = 0;

    setState(() {
      for (var item in allItems) {
        final key = item['key'] as String;
        final bool isSelected = _selectedProducts[key] ?? false;

        if (isSelected) {
          final double baseP = _massRuleBase == 'normal'
              ? (item['normalPrice'] as double)
              : (item['globalRolePrice'] as double);

          double newP = baseP;
          if (_massRuleType == 'fixed') {
            newP = baseP + val;
          } else {
            newP = baseP * (1.0 + (val / 100.0));
          }

          if (newP < 0) newP = 0;

          _priceControllers[key]?.text = newP.toStringAsFixed(0);
          appliedCount++;
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("¡Regla aplicada a $appliedCount productos seleccionados! Revisa y da clic en GUARDAR."),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _saveChanges() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow)),
    );

    try {
      final Map<String, double> newCustomPrices = {};
      for (var entry in _selectedProducts.entries) {
        final key = entry.key;
        final isSelected = entry.value;
        if (isSelected) {
          final text = _priceControllers[key]?.text.trim() ?? '';
          final double? price = double.tryParse(text.replaceAll(',', '.'));
          if (price != null && price > 0) {
            newCustomPrices[key] = price;
          }
        }
      }

      await FirebaseFirestore.instance
          .collection('clients')
          .doc(_currentClient.id)
          .update({'customPrices': newCustomPrices});

      if (mounted) {
        Navigator.pop(context); // Cierra loader
        setState(() {
          _isEditing = false;
        });
        _reloadClientData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lista de precios actualizada."), backgroundColor: Colors.green),
        );
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

  void _showDuplicateListDialog() {
    final allClients = ClientsActionsV2().allClients;
    final sameTypeCandidates = allClients.where((c) => 
      c.id != _currentClient.id && 
      c.type == _currentClient.type && 
      !c.hidden
    ).toList();

    List<String> selectedTargetIds = [];
    String searchQ = '';
    String? cityFilter;
    bool isSaving = false;

    final citiesList = ClientsActionsV2().cities;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              var filteredCandidates = List<Client>.from(sameTypeCandidates);

              if (cityFilter != null && cityFilter!.isNotEmpty) {
                filteredCandidates = filteredCandidates.where((c) => c.city.trim().toLowerCase() == cityFilter!.trim().toLowerCase()).toList();
              }

              if (searchQ.isNotEmpty) {
                filteredCandidates = filteredCandidates.where((c) => 
                  c.name.toLowerCase().contains(searchQ) || 
                  c.city.toLowerCase().contains(searchQ)
                ).toList();
              }

              final String clientTypeName = _currentClient.type == 'revendedor' ? "Revendedores" : "Clientes Especiales";

              return Container(
                width: 580,
                constraints: BoxConstraints(
                  maxHeight: (MediaQuery.of(context).size.height - MediaQuery.of(context).viewInsets.bottom) * 0.85,
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Duplicar Lista a otros $clientTypeName",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryYellow),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Copiarás los precios de '${_currentClient.name}' hacia los $clientTypeName seleccionados.",
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: TextField(
                              cursorColor: Colors.black,
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Buscar $clientTypeName...',
                                hintStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 13),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                prefixIcon: const Icon(Icons.search, color: Colors.black, size: 18),
                                filled: true,
                                fillColor: AppTheme.primaryYellow,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                isDense: true,
                              ),
                              onChanged: (val) => setStateDialog(() => searchQ = val.toLowerCase()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 140,
                          height: 38,
                          child: DropdownButtonFormField<String>(
                            dropdownColor: AppTheme.primaryYellow,
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: AppTheme.primaryYellow,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            ),
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                            value: cityFilter,
                            hint: const Text("Todas", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                            items: [
                              const DropdownMenuItem<String>(value: null, child: Text("Todas", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12))),
                              ...citiesList.map((c) => DropdownMenuItem<String>(value: c, child: Text(c, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)))),
                            ],
                            onChanged: (val) => setStateDialog(() => cityFilter = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${selectedTargetIds.length} seleccionados", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        TextButton(
                          onPressed: () {
                            setStateDialog(() {
                              if (selectedTargetIds.length == filteredCandidates.length) {
                                selectedTargetIds.clear();
                              } else {
                                selectedTargetIds = filteredCandidates.map((c) => c.id).toList();
                              }
                            });
                          },
                          child: Text(
                            selectedTargetIds.length == filteredCandidates.length ? "Desmarcar Todos" : "Marcar Todos",
                            style: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: filteredCandidates.isEmpty
                          ? Center(child: Text("No se encontraron $clientTypeName.", style: const TextStyle(color: Colors.white54)))
                          : ListView.builder(
                              itemCount: filteredCandidates.length,
                              itemBuilder: (context, index) {
                                final client = filteredCandidates[index];
                                final isChecked = selectedTargetIds.contains(client.id);
                                return CheckboxListTile(
                                  activeColor: AppTheme.primaryYellow,
                                  checkColor: Colors.black,
                                  title: Text(client.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                  subtitle: Text("${client.city} • ${client.customPrices.length} precios configurados", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                  value: isChecked,
                                  onChanged: (bool? checked) {
                                    setStateDialog(() {
                                      if (checked == true) {
                                        selectedTargetIds.add(client.id);
                                      } else {
                                        selectedTargetIds.remove(client.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: AppTheme.primaryYellow),
                          icon: const Icon(Icons.public, size: 16),
                          label: const Text("CONVERTIR EN LISTA GLOBAL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          onPressed: isSaving ? null : () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppTheme.surfaceDark,
                                title: const Text("¿Estás seguro?", style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold)),
                                content: Text("Los precios personalizados de '${_currentClient.name}' se establecerán como los PRECIOS BASE GLOBALES para todos los productos en el sistema.", style: const TextStyle(color: Colors.white)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR", style: TextStyle(color: Colors.grey))),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text("SÍ, APLICAR COMO GLOBAL", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              setStateDialog(() => isSaving = true);
                              try {
                                final isWholesale = _currentClient.type == 'revendedor';
                                final isSpecial = _currentClient.type == 'especial';
                                final batch = FirebaseFirestore.instance.batch();

                                for (var entry in _currentClient.customPrices.entries) {
                                  final key = entry.key;
                                  final price = entry.value;

                                  if (key.contains('_')) {
                                    final parts = key.split('_');
                                    final prodId = parts[0];
                                    final vName = parts.sublist(1).join('_');
                                    final prodDoc = await FirebaseFirestore.instance.collection('products').doc(prodId).get();
                                    if (prodDoc.exists) {
                                      final data = prodDoc.data()!;
                                      final List variants = List.from(data['variants'] ?? []);
                                      bool updated = false;
                                      for (var v in variants) {
                                        if (v['name'] == vName) {
                                          if (isWholesale) v['resellerPrice'] = price;
                                          else if (isSpecial) v['specialPrice'] = price;
                                          else v['price'] = price;
                                          updated = true;
                                        }
                                      }
                                      if (updated) {
                                        batch.update(prodDoc.reference, {'variants': variants});
                                      }
                                    }
                                  } else {
                                    final prodRef = FirebaseFirestore.instance.collection('products').doc(key);
                                    if (isWholesale) {
                                      batch.update(prodRef, {'resellerPrice': price});
                                    } else if (isSpecial) {
                                      batch.update(prodRef, {'specialPrice': price});
                                    } else {
                                      batch.update(prodRef, {'price': price});
                                    }
                                  }
                                }

                                await batch.commit();
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("¡Precios guardados como Lista Global Base!"), backgroundColor: Colors.green),
                                  );
                                }
                              } catch (e) {
                                setStateDialog(() => isSaving = false);
                              }
                            }
                          },
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: isSaving ? null : () => Navigator.pop(context),
                              child: const Text("CANCELAR", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ),
                            const SizedBox(width: 6),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow),
                              onPressed: (isSaving || selectedTargetIds.isEmpty)
                                  ? null
                                  : () async {
                                      setStateDialog(() => isSaving = true);
                                      try {
                                        await ClientsActionsV2().copyPricesToClients(_currentClient.id, selectedTargetIds);
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text("¡Lista duplicada a ${selectedTargetIds.length} $clientTypeName!"),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        setStateDialog(() => isSaving = false);
                                      }
                                    },
                              child: isSaving 
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                                  : Text("APLICAR LISTA (${selectedTargetIds.length})", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
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

  void _showImportListDialog() {
    final allClients = ClientsActionsV2().allClients;
    final sameTypeSources = allClients.where((c) => 
      c.id != _currentClient.id && 
      c.type == _currentClient.type && 
      !c.hidden
    ).toList();

    String? selectedSourceId;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              final String clientTypeName = _currentClient.type == 'revendedor' ? "Revendedor" : "Cliente Especial";

              return Container(
                width: 450,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Cargar Lista desde otro $clientTypeName",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryYellow),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      dropdownColor: AppTheme.surfaceDark,
                      decoration: InputDecoration(
                        labelText: "Seleccionar $clientTypeName Origen",
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person, color: AppTheme.primaryYellow),
                      ),
                      value: selectedSourceId,
                      items: [
                        const DropdownMenuItem<String>(
                          value: 'GLOBAL',
                          child: Text("⭐ Lista Global Base (Precios por Defecto)", style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold)),
                        ),
                        ...sameTypeSources.map((c) => DropdownMenuItem<String>(
                          value: c.id,
                          child: Text("${c.name} (${c.city}) - ${c.customPrices.length} precios", style: const TextStyle(color: Colors.white)),
                        )),
                      ],
                      onChanged: (val) => setStateDialog(() => selectedSourceId = val),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSaving ? null : () => Navigator.pop(context),
                          child: const Text("CANCELAR", style: TextStyle(color: Colors.white70)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow),
                          onPressed: (isSaving || selectedSourceId == null)
                              ? null
                              : () async {
                                  setStateDialog(() => isSaving = true);
                                  try {
                                    if (selectedSourceId == 'GLOBAL') {
                                      await FirebaseFirestore.instance
                                          .collection('clients')
                                          .doc(_currentClient.id)
                                          .update({'customPrices': {}});
                                    } else {
                                      await ClientsActionsV2().copyPricesToClients(selectedSourceId!, [_currentClient.id]);
                                    }
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      _reloadClientData();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("¡Lista cargada correctamente!"), backgroundColor: Colors.green),
                                      );
                                    }
                                  } catch (e) {
                                    setStateDialog(() => isSaving = false);
                                  }
                                },
                          child: isSaving 
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : const Text("IMPORTAR LISTA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    final inventory = InventoryActions().products;
    final bool isWholesale = _currentClient.type == 'revendedor';
    final bool isSpecialRole = _currentClient.type == 'especial';

    final List<Map<String, dynamic>> allItems = [];
    for (var prod in inventory) {
      if (prod.variants.isEmpty) {
        final key = prod.id;
        final assignedP = _currentClient.customPrices[key];
        final double globalRoleP = (isWholesale
                ? (prod.resellerPrice ?? prod.specialPrice ?? prod.price)
                : (isSpecialRole ? (prod.specialPrice ?? prod.price) : prod.price))
            .toDouble();
        final normalP = prod.price.toDouble();

        allItems.add({
          'key': key,
          'name': prod.name,
          'category': prod.category,
          'assignedPrice': assignedP,
          'globalRolePrice': globalRoleP,
          'normalPrice': normalP,
        });
      } else {
        for (var v in prod.variants) {
          final key = '${prod.id}_${v.name}';
          final assignedP = _currentClient.customPrices[key];
          final double globalRoleP = (isWholesale
                  ? (v.resellerPrice ?? v.specialPrice ?? v.price ?? prod.price)
                  : (isSpecialRole
                      ? (v.specialPrice ?? v.price ?? prod.price)
                      : (v.price ?? prod.price)))
              .toDouble();
          final normalP = (v.price ?? prod.price).toDouble();

          allItems.add({
            'key': key,
            'name': '${prod.name} (${v.name})',
            'category': prod.category,
            'assignedPrice': assignedP,
            'globalRolePrice': globalRoleP,
            'normalPrice': normalP,
          });
        }
      }
    }

    final filteredItems = allItems.where((item) {
      final key = item['key'] as String;
      final bool isSelected = _selectedProducts[key] ?? false;

      if (!_isEditing && !isSelected) {
        return false;
      }

      return _searchQuery.isEmpty ||
          (item['name'] as String).toLowerCase().contains(_searchQuery) ||
          (item['category'] as String).toLowerCase().contains(_searchQuery);
    }).toList();

    final List<List<Map<String, dynamic>>> pairedItems = [];
    for (int i = 0; i < filteredItems.length; i += 2) {
      if (i + 1 < filteredItems.length) {
        pairedItems.add([filteredItems[i], filteredItems[i + 1]]);
      } else {
        pairedItems.add([filteredItems[i]]);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Lista de Precios: ${_currentClient.name}"),
            Text(
              "${_currentClient.type.toUpperCase()} • ${filteredItems.length} productos en su lista",
              style: const TextStyle(fontSize: 12, color: AppTheme.primaryYellow),
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceDark,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view, color: AppTheme.primaryYellow, size: 24),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
              PreferencesService().setBool('client_price_list_is_grid', _isGridView);
            },
            tooltip: _isGridView ? "Cambiar a Vista Filas" : "Cambiar a Vista Tarjetas",
          ),
          if (_isEditing) ...[
            TextButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save, color: Colors.black),
              label: const Text("GUARDAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(backgroundColor: AppTheme.primaryYellow),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: Container(
        color: AppTheme.backgroundDark,
        child: Column(
          children: [
            // Buscador
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  hintText: 'Buscar producto o categoría...',
                  hintStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.black, size: 18),
                  isDense: true,
                  filled: true,
                  fillColor: AppTheme.primaryYellow,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),

            // BARRA DE REGLA / AJUSTE MASIVO DE PRECIOS (SOLO EN MODO MODIFICAR)
            if (_isEditing)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryYellow.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_fix_high, color: AppTheme.primaryYellow, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      "Regla Rápida:",
                      style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 12),
                    // Base
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
                      child: DropdownButton<String>(
                        value: _massRuleBase,
                        dropdownColor: AppTheme.surfaceDark,
                        underline: const SizedBox(),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        items: const [
                          DropdownMenuItem(value: 'normal', child: Text("Base: Público (Común)")),
                          DropdownMenuItem(value: 'globalRole', child: Text("Base: Mayorista Global")),
                        ],
                        onChanged: (val) => setState(() => _massRuleBase = val ?? 'normal'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tipo
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
                      child: DropdownButton<String>(
                        value: _massRuleType,
                        dropdownColor: AppTheme.surfaceDark,
                        underline: const SizedBox(),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        items: const [
                          DropdownMenuItem(value: 'fixed', child: Text("Monto (\$)")),
                          DropdownMenuItem(value: 'percent', child: Text("Porcentaje (%)")),
                        ],
                        onChanged: (val) => setState(() => _massRuleType = val ?? 'fixed'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Valor (-200 o +200)
                    SizedBox(
                      width: 90,
                      height: 32,
                      child: TextField(
                        controller: _massRuleValueController,
                        keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                        style: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: _massRuleType == 'fixed' ? '-200' : '-10',
                          hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          filled: true,
                          fillColor: Colors.black54,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Botón Aplicar
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryYellow,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      icon: const Icon(Icons.bolt, color: Colors.black, size: 16),
                      label: const Text(
                        "APLICAR A TILDADOS",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                      onPressed: () => _applyMassRule(allItems),
                    ),
                  ],
                ),
              ),

            // CONTENIDO: LISTVIEW EN PARES DE 2 COLUMNAS (ALTO NATURAL FIJO)
            Expanded(
              child: filteredItems.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.inventory_2_outlined, color: Colors.white30, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              !_isEditing
                                  ? "Esta lista no tiene productos tildados todavía.\nTocá 'Modificar' abajo para elegir qué productos compra este revendedor."
                                  : "No se encontraron productos.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      itemCount: pairedItems.length,
                      itemBuilder: (context, index) {
                        final pair = pairedItems[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: _isGridView ? 8.0 : 4.0),
                          child: Row(
                            children: [
                              Expanded(child: _buildTile(pair[0], _isGridView)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: pair.length > 1
                                    ? _buildTile(pair[1], _isGridView)
                                    : const SizedBox(),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Barra Inferior de Acciones
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.surfaceDark,
              child: Row(
                children: [
                  if (!_isEditing) ...[
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit, color: Colors.black, size: 18),
                      label: const Text("Modificar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _showDuplicateListDialog,
                      icon: const Icon(Icons.content_copy, color: Colors.black, size: 18),
                      label: const Text("Duplicar Lista a otros", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _showImportListDialog,
                      icon: const Icon(Icons.download, color: AppTheme.primaryYellow, size: 18),
                      label: const Text("Cargar de otro", style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 12)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.primaryYellow)),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: _saveChanges,
                      icon: const Icon(Icons.save, color: Colors.black, size: 18),
                      label: const Text("GUARDAR CAMBIOS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(() => _isEditing = false),
                      child: const Text("Cancelar", style: TextStyle(color: Colors.white70)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(Map<String, dynamic> item, bool isGridCard) {
    final key = item['key'] as String;
    final name = item['name'] as String;
    final double? assignedPrice = item['assignedPrice'];
    final double globalRolePrice = item['globalRolePrice'];
    final double normalPrice = item['normalPrice'];

    final bool isSelected = _selectedProducts[key] ?? false;
    final controller = _priceControllers[key]!;

    final double effectiveDisplayPrice = assignedPrice ?? globalRolePrice;
    final bool isCustomized = assignedPrice != null;

    if (!_isEditing) {
      // MODO LECTURA
      if (isGridCard) {
        return Container(
          decoration: BoxDecoration(
            color: isCustomized ? AppTheme.surfaceDark : AppTheme.surfaceDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isCustomized ? AppTheme.primaryYellow.withOpacity(0.4) : Colors.white10,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                isCustomized ? Icons.label : Icons.sell_outlined,
                color: isCustomized ? AppTheme.primaryYellow : Colors.greenAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "Público: \$${normalPrice.toStringAsFixed(0)}",
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "\$${effectiveDisplayPrice.toStringAsFixed(0)}",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: isCustomized ? AppTheme.primaryYellow : Colors.greenAccent,
                ),
              ),
            ],
          ),
        );
      } else {
        return Container(
          decoration: BoxDecoration(
            color: isCustomized ? AppTheme.surfaceDark : AppTheme.surfaceDark.withOpacity(0.4),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isCustomized ? AppTheme.primaryYellow.withOpacity(0.3) : Colors.white12,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Icon(
                isCustomized ? Icons.label : Icons.sell_outlined,
                color: isCustomized ? AppTheme.primaryYellow : Colors.greenAccent,
                size: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "Púb: \$${normalPrice.toStringAsFixed(0)}",
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
              const SizedBox(width: 10),
              Text(
                "\$${effectiveDisplayPrice.toStringAsFixed(0)}",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: isCustomized ? AppTheme.primaryYellow : Colors.greenAccent,
                ),
              ),
            ],
          ),
        );
      }
    } else {
      // MODO EDICIÓN ("MODIFICAR")
      if (isGridCard) {
        return Container(
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.surfaceDark : AppTheme.surfaceDark.withOpacity(0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppTheme.primaryYellow.withOpacity(0.5) : Colors.white12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                activeColor: AppTheme.primaryYellow,
                checkColor: Colors.black,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (val) {
                  setState(() {
                    _selectedProducts[key] = val ?? false;
                    if (val == true && controller.text.isEmpty) {
                      controller.text = effectiveDisplayPrice.toStringAsFixed(0);
                    }
                  });
                },
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isSelected ? AppTheme.textPrimary : Colors.white54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "Ant: ${assignedPrice != null ? "\$${assignedPrice.toStringAsFixed(0)}" : "Global"} • Púb: \$${normalPrice.toStringAsFixed(0)}",
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (isSelected)
                SizedBox(
                  width: 85,
                  height: 32,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 13),
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      prefixStyle: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 13),
                      hintText: effectiveDisplayPrice.toStringAsFixed(0),
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      filled: true,
                      fillColor: Colors.black38,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                    ),
                  ),
                )
              else
                const Text("Global", style: TextStyle(color: Colors.white30, fontSize: 11)),
            ],
          ),
        );
      } else {
        return Container(
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.surfaceDark : AppTheme.surfaceDark.withOpacity(0.4),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isSelected ? AppTheme.primaryYellow.withOpacity(0.5) : Colors.white10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isSelected,
                  activeColor: AppTheme.primaryYellow,
                  checkColor: Colors.black,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) {
                    setState(() {
                      _selectedProducts[key] = val ?? false;
                      if (val == true && controller.text.isEmpty) {
                        controller.text = effectiveDisplayPrice.toStringAsFixed(0);
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isSelected ? Colors.white : Colors.white54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              if (isSelected)
                SizedBox(
                  width: 78,
                  height: 28,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 12),
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      prefixStyle: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 12),
                      hintText: effectiveDisplayPrice.toStringAsFixed(0),
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      filled: true,
                      fillColor: Colors.black38,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                    ),
                  ),
                )
              else
                const Text("Global", style: TextStyle(color: Colors.white30, fontSize: 10)),
            ],
          ),
        );
      }
    }
  }
}
