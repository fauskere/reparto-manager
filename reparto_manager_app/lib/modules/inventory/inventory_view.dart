import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../core/preferences_service.dart';
import '../../widgets/custom_header_filter_bar.dart';
import '../shell/app_drawer.dart';
import 'inventory_actions.dart';

class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  String _sortBy = 'Alfabeto (A-Z)';
  String _searchQuery = '';
  late bool _isGridView;

  @override
  void initState() {
    super.initState();
    _isGridView = PreferencesService().getBool('inventory_is_grid') ?? true;
  }

  void _showAddDialog() {
    final addNameController = TextEditingController();
    final addPriceController = TextEditingController();
    final addCategoryController = TextEditingController();
    List<Map<String, dynamic>> variantsData = [];

    showDialog(
      context: context,
      builder: (context) {
        final scrollController = ScrollController();
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Nuevo Producto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: addNameController, 
                        decoration: const InputDecoration(labelText: 'Nombre del Producto', border: OutlineInputBorder(), prefixIcon: Icon(Icons.inventory_2))
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: addPriceController, 
                        decoration: const InputDecoration(labelText: 'Precio Base (\$)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)), 
                        keyboardType: const TextInputType.numberWithOptions(decimal: true)
                      ),
                      const SizedBox(height: 16),
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          final text = textEditingValue.text.toLowerCase();
                          final available = InventoryActions().products.map((e) => e.category).toSet().toList();
                          if (text.isEmpty) return available;
                          return available.where((c) => c.toLowerCase().contains(text));
                        },
                        onSelected: (String selection) {
                          addCategoryController.text = selection;
                        },
                        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            onChanged: (val) => addCategoryController.text = val,
                            decoration: const InputDecoration(
                              labelText: 'Categoría (Ej: Bebidas)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 32),
                      const Text("Variantes (Opcional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryYellow)),
                      const SizedBox(height: 12),
                      ...variantsData.asMap().entries.map((entry) {
                        int index = entry.key;
                        var v = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(color: Colors.white10, width: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: v['nameCtrl'],
                                        decoration: const InputDecoration(
                                          labelText: 'Nombre de Variante (Ej: Batata)', 
                                          isDense: true,
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.danger.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8)
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                                        onPressed: () {
                                          setStateDialog(() {
                                            variantsData.removeAt(index);
                                          });
                                        },
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                CheckboxListTile(
                                  title: const Text("Tendrá un precio distinto al base", style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                                  value: v['hasCustomPrice'],
                                  contentPadding: EdgeInsets.zero,
                                  activeColor: AppTheme.primaryYellow,
                                  checkColor: Colors.black,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  onChanged: (val) {
                                    setStateDialog(() {
                                      v['hasCustomPrice'] = val;
                                    });
                                  },
                                ),
                                if (v['hasCustomPrice']) ...[
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: v['priceCtrl'],
                                    decoration: const InputDecoration(
                                      labelText: 'Precio Específico (\$)', 
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.attach_money, size: 20),
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                TextField(
                                  controller: v['thresholdCtrl'],
                                  decoration: const InputDecoration(
                                    labelText: 'Umbral Stock Bajo (Opcional)',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.warning_amber, size: 20, color: AppTheme.primaryYellow),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryYellow.withOpacity(0.1),
                          foregroundColor: AppTheme.primaryYellow,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppTheme.primaryYellow, width: 1),
                          )
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            variantsData.add(<String, dynamic>{
                              'nameCtrl': TextEditingController(),
                              'priceCtrl': TextEditingController(),
                              'thresholdCtrl': TextEditingController(),
                              'hasCustomPrice': false,
                            });
                          });
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (scrollController.hasClients) {
                              scrollController.animateTo(
                                scrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text("AÑADIR OTRA VARIANTE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      )
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    final n = addNameController.text.trim();
                    final pStr = addPriceController.text.trim();
                    final c = addCategoryController.text.trim();
                    final p = double.tryParse(pStr);
                    
                    if (n.isNotEmpty && p != null) {
                      List<ProductVariant> finalVariants = [];
                      for (var v in variantsData) {
                        String vName = v['nameCtrl'].text.trim();
                        if (vName.isEmpty) continue;
                        double? vPrice;
                        if (v['hasCustomPrice']) {
                          vPrice = double.tryParse(v['priceCtrl'].text.trim());
                        }
                        int? vThreshold = int.tryParse(v['thresholdCtrl'].text.trim());
                        finalVariants.add(ProductVariant(name: vName, price: vPrice, lowStockThreshold: vThreshold));
                      }
                      InventoryActions().addProduct(n, p, c, finalVariants);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Guardar', style: TextStyle(color: Colors.black)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  void _showEditDialog(Product product) {
    final editNameController = TextEditingController(text: product.name);
    final editPriceController = TextEditingController(text: product.price.toStringAsFixed(2));
    final editCategoryController = TextEditingController(text: product.category);

    List<Map<String, dynamic>> variantsData = product.variants.map<Map<String, dynamic>>((v) => <String, dynamic>{
        'nameCtrl': TextEditingController(text: v.name),
        'priceCtrl': TextEditingController(text: v.price?.toStringAsFixed(2) ?? ''),
        'thresholdCtrl': TextEditingController(text: v.lowStockThreshold?.toString() ?? ''),
        'hasCustomPrice': v.price != null,
        'resellerPrice': v.resellerPrice,
        'specialPrice': v.specialPrice,
      }).toList();

    showDialog(
      context: context,
      builder: (context) {
        final scrollController = ScrollController();
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Editar Producto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: editNameController, 
                        decoration: const InputDecoration(labelText: 'Nombre del Producto', border: OutlineInputBorder(), prefixIcon: Icon(Icons.inventory_2))
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: editPriceController, 
                        decoration: const InputDecoration(labelText: 'Precio Base (\$)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)), 
                        keyboardType: const TextInputType.numberWithOptions(decimal: true)
                      ),
                      const SizedBox(height: 16),
                      Autocomplete<String>(
                        initialValue: TextEditingValue(text: product.category),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          final text = textEditingValue.text.toLowerCase();
                          final available = InventoryActions().products.map((e) => e.category).toSet().toList();
                          if (text.isEmpty) return available;
                          return available.where((c) => c.toLowerCase().contains(text));
                        },
                        onSelected: (String selection) {
                          editCategoryController.text = selection;
                        },
                        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            onChanged: (val) => editCategoryController.text = val,
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 32),
                      const Text("Variantes (Opcional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryYellow)),
                      const SizedBox(height: 12),
                      ...variantsData.asMap().entries.map((entry) {
                        int index = entry.key;
                        var v = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(color: Colors.white10, width: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: v['nameCtrl'],
                                        decoration: const InputDecoration(
                                          labelText: 'Nombre de Variante (Ej: Batata)', 
                                          isDense: true,
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.danger.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8)
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                                        onPressed: () {
                                          setStateDialog(() {
                                            variantsData.removeAt(index);
                                          });
                                        },
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                CheckboxListTile(
                                  title: const Text("Tendrá un precio distinto al base", style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                                  value: v['hasCustomPrice'],
                                  contentPadding: EdgeInsets.zero,
                                  activeColor: AppTheme.primaryYellow,
                                  checkColor: Colors.black,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  onChanged: (val) {
                                    setStateDialog(() {
                                      v['hasCustomPrice'] = val;
                                    });
                                  },
                                ),
                                if (v['hasCustomPrice']) ...[
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: v['priceCtrl'],
                                    decoration: const InputDecoration(
                                      labelText: 'Precio Específico (\$)', 
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.attach_money, size: 20),
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                TextField(
                                  controller: v['thresholdCtrl'],
                                  decoration: const InputDecoration(
                                    labelText: 'Umbral Stock Bajo (Opcional)',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.warning_amber, size: 20, color: AppTheme.primaryYellow),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryYellow.withOpacity(0.1),
                          foregroundColor: AppTheme.primaryYellow,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppTheme.primaryYellow, width: 1),
                          )
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            variantsData.add(<String, dynamic>{
                              'nameCtrl': TextEditingController(),
                              'priceCtrl': TextEditingController(),
                              'thresholdCtrl': TextEditingController(),
                              'hasCustomPrice': false,
                            });
                          });
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (scrollController.hasClients) {
                              scrollController.animateTo(
                                scrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text("AÑADIR OTRA VARIANTE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      )
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    final n = editNameController.text.trim();
                    final pStr = editPriceController.text.trim();
                    final c = editCategoryController.text.trim();
                    final p = double.tryParse(pStr);
                    
                    if (n.isNotEmpty && p != null) {
                      List<ProductVariant> finalVariants = [];
                      for (var v in variantsData) {
                        String vName = v['nameCtrl'].text.trim();
                        if (vName.isEmpty) continue;
                        double? vPrice;
                        if (v['hasCustomPrice']) {
                          vPrice = double.tryParse(v['priceCtrl'].text.trim());
                        }
                        int? vThreshold = int.tryParse(v['thresholdCtrl'].text.trim());
                        finalVariants.add(ProductVariant(name: vName, price: vPrice, lowStockThreshold: vThreshold, resellerPrice: v['resellerPrice'], specialPrice: v['specialPrice']));
                      }
                      InventoryActions().updateProduct(product.id, n, p, c, finalVariants);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Guardar', style: TextStyle(color: Colors.black)),
                ),
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
        return ListenableBuilder(
          listenable: InventoryActions(),
          builder: (context, child) {
            final allProducts = InventoryActions().products;

            final searchBar = SizedBox(
              width: 350,
              height: 40,
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  hintText: 'Buscar producto...',
                  hintStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                  prefixIcon: const Icon(Icons.search, color: Colors.black),
                  isDense: true,
                  filled: true,
                  fillColor: AppTheme.primaryYellow,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            );

            final filterOnlyDropdown = SizedBox(
              width: 180,
              height: 40,
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: AppTheme.primaryYellow,
                ),
                dropdownColor: AppTheme.primaryYellow,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                value: _sortBy,
                items: const [
                  DropdownMenuItem<String>(value: 'Alfabeto (A-Z)', child: Text('A-Z', style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold))),
                  DropdownMenuItem<String>(value: 'Alfabeto (Z-A)', child: Text('Z-A', style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold))),
                  DropdownMenuItem<String>(value: 'Precio (Menor a Mayor)', child: Text('Precio Asc', style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold))),
                  DropdownMenuItem<String>(value: 'Precio (Mayor a Menor)', child: Text('Precio Desc', style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _sortBy = val);
                },
              ),
            );

            final filterBar = CustomHeaderFilterBar(
              showSearchBar: true,
              searchQuery: _searchQuery,
              onSearchChanged: (val) => setState(() => _searchQuery = val),
              searchHint: 'Buscar producto...',
              showZoneFilter: false,
              showSortDropdown: true,
              sortOption: _sortBy,
              sortOptions: const ['Alfabeto (A-Z)', 'Alfabeto (Z-A)', 'Precio (Menor a Mayor)', 'Precio (Mayor a Menor)'],
              onSortChanged: (sort) {
                if (sort != null) setState(() => _sortBy = sort);
              },
              anchorDate: DateTime.now(),
            );

            return Scaffold(
              drawer: const AppDrawer(),
              appBar: AppBar(
                elevation: 0,
                title: const Text("Inventario"),
                actions: [
                  IconButton(
                    icon: Icon(_isGridView ? Icons.list : Icons.grid_view, color: AppTheme.primaryYellow),
                    onPressed: () {
                      setState(() {
                        _isGridView = !_isGridView;
                      });
                      PreferencesService().setBool('inventory_is_grid', _isGridView);
                    },
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              body: Padding(
                padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
                child: Column(
                  children: [
                    filterBar,
                    const SizedBox(height: 12),
                    Expanded(
                      child: _buildList(allProducts, isMobile, const SizedBox(), const SizedBox(), isPhone: constraints.maxWidth <= 500),
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
                            onPressed: _showAddDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryYellow,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            icon: const Icon(Icons.add_shopping_cart, size: 20),
                            label: const Text("Agregar Producto", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              String searchQ = '';
                              showDialog(
                                context: context,
                                builder: (ctx) {
                                  return StatefulBuilder(
                                    builder: (ctx, setStateDialog) {
                                      final prods = InventoryActions().products;
                                      final List<Map<String, dynamic>> itemsList = [];
                                      for (var p in prods) {
                                        if (p.variants.isEmpty) {
                                          if (searchQ.isEmpty || p.name.toLowerCase().contains(searchQ.toLowerCase())) {
                                            itemsList.add({'product': p, 'name': p.name, 'price': p.price, 'variantName': ''});
                                          }
                                        } else {
                                          for (var v in p.variants) {
                                            final vName = "${p.name} (${v.name})";
                                            if (searchQ.isEmpty || vName.toLowerCase().contains(searchQ.toLowerCase())) {
                                              itemsList.add({'product': p, 'name': vName, 'price': v.price ?? p.price, 'variantName': v.name});
                                            }
                                          }
                                        }
                                      }

                                      return Dialog(
                                        backgroundColor: AppTheme.surfaceDark,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        child: Container(
                                          width: 450,
                                          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
                                          padding: const EdgeInsets.all(20.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text("Actualizar Precio (Historial)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryYellow)),
                                                  IconButton(
                                                    icon: const Icon(Icons.close, color: Colors.white70),
                                                    onPressed: () => Navigator.pop(ctx),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              TextField(
                                                autofocus: true,
                                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                                                cursorColor: Colors.black,
                                                decoration: InputDecoration(
                                                  hintText: 'Buscar producto...',
                                                  hintStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 13),
                                                  prefixIcon: const Icon(Icons.search, color: Colors.black, size: 18),
                                                  isDense: true,
                                                  filled: true,
                                                  fillColor: AppTheme.primaryYellow,
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                                ),
                                                onChanged: (val) => setStateDialog(() => searchQ = val),
                                              ),
                                              const SizedBox(height: 12),
                                              Expanded(
                                                child: itemsList.isEmpty
                                                    ? const Center(child: Text("No se encontraron coincidencias.", style: TextStyle(color: Colors.white54)))
                                                    : ListView.builder(
                                                        itemCount: itemsList.length,
                                                        itemBuilder: (context, index) {
                                                          final item = itemsList[index];
                                                          final Product p = item['product'];
                                                          final double currentP = item['price'];
                                                          final String vName = item['variantName'];

                                                          return ListTile(
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                            leading: const Icon(Icons.sell_outlined, color: AppTheme.primaryYellow),
                                                            title: Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                                            subtitle: Text("Precio Actual: \$${currentP.toStringAsFixed(0)}", style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                                                            trailing: const Icon(Icons.edit_note, color: AppTheme.primaryYellow),
                                                            onTap: () {
                                                              final newPriceCtrl = TextEditingController(text: currentP.toStringAsFixed(0));
                                                              showDialog(
                                                                context: context,
                                                                builder: (ctxEdit) => AlertDialog(
                                                                  backgroundColor: AppTheme.surfaceDark,
                                                                  title: Text("Nuevo precio para ${item['name']}", style: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 15)),
                                                                  content: TextField(
                                                                    controller: newPriceCtrl,
                                                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                                    autofocus: true,
                                                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                                    decoration: InputDecoration(
                                                                      labelText: 'Nuevo Precio (\$)',
                                                                      labelStyle: const TextStyle(color: AppTheme.primaryYellow),
                                                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryYellow)),
                                                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryYellow, width: 2)),
                                                                    ),
                                                                  ),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed: () => Navigator.pop(ctxEdit),
                                                                      child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
                                                                    ),
                                                                    ElevatedButton(
                                                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow),
                                                                      onPressed: () async {
                                                                        final newP = double.tryParse(newPriceCtrl.text.trim());
                                                                        if (newP != null && newP != currentP) {
                                                                          await InventoryActions().updateProductPriceWithHistory(
                                                                            p.id,
                                                                            item['name'],
                                                                            currentP,
                                                                            newP,
                                                                            variantName: vName,
                                                                          );
                                                                          Navigator.pop(ctxEdit);
                                                                          Navigator.pop(ctx);
                                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                                            SnackBar(
                                                                              content: Text("Precio actualizado e historial registrado para ${item['name']}"),
                                                                              backgroundColor: Colors.greenAccent,
                                                                            ),
                                                                          );
                                                                        }
                                                                      },
                                                                      child: const Text("GUARDAR E HISTORIAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.surfaceDark,
                              foregroundColor: AppTheme.primaryYellow,
                              side: const BorderSide(color: AppTheme.primaryYellow),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            icon: const Icon(Icons.trending_up, size: 20),
                            label: const Text("Actualizar Precio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          const Spacer(),
                          Text(
                            "TOTAL PRODUCTOS: ${allProducts.length}",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildList(List<Product> allProducts, bool isMobile, Widget filterDropdown, Widget searchBar, {bool isPhone = false}) {
    if (allProducts.isEmpty) {
      return const Center(
        child: Text("No hay productos cargados", style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    List<Product> products = List.from(allProducts);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      products = products.where((p) => p.name.toLowerCase().contains(q) || p.category.toLowerCase().contains(q)).toList();
    }

    if (_sortBy == 'Alfabeto (A-Z)') {
      products.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortBy == 'Alfabeto (Z-A)') {
      products.sort((a, b) => b.name.compareTo(a.name));
    } else if (_sortBy == 'Precio (Menor a Mayor)') {
      products.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'Precio (Mayor a Menor)') {
      products.sort((a, b) => b.price.compareTo(a.price));
    }

    final isTablet = MediaQuery.of(context).size.width > 500 && MediaQuery.of(context).size.width <= 1024;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: products.isEmpty ? const Center(child: Text("No hay productos con estos filtros", style: TextStyle(color: AppTheme.textSecondary))) : (!_isGridView ? ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductCard(product, isGrid: false, isPhone: isPhone);
            },
          ) : GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isPhone ? 1 : (isMobile ? 2 : 3),
              childAspectRatio: isPhone ? 3.5 : (isMobile ? 1.8 : 2.5),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductCard(product, isGrid: true, isPhone: isPhone);
            },
          )),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product, {bool isGrid = false, bool isPhone = false}) {
    return Card(
      margin: isGrid ? const EdgeInsets.only(bottom: 12) : const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      shape: isGrid ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)) : const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ListTile(
        contentPadding: isGrid ? (isPhone ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2) : null) : const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        dense: !isGrid || isPhone,
        title: Text(product.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isPhone ? 14 : 16)),
        subtitle: Text('Precio: \$${product.price.toStringAsFixed(0)} • ${product.category}${product.variants.isNotEmpty ? ' • ${product.variants.length} var' : ''}', style: TextStyle(color: AppTheme.primaryYellow, fontSize: isPhone ? 11 : 13)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: AppTheme.primaryYellow, size: isPhone ? 18 : (isGrid ? 24 : 20)),
              onPressed: () => _showEditDialog(product),
              tooltip: 'Editar',
              padding: isGrid ? const EdgeInsets.all(8.0) : EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppTheme.danger, size: isPhone ? 18 : (isGrid ? 24 : 20)),
              onPressed: () => InventoryActions().removeProduct(product.id),
              tooltip: 'Eliminar',
              padding: isGrid ? const EdgeInsets.all(8.0) : EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
