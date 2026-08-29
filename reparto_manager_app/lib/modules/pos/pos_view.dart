import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../widgets/custom_header_filter_bar.dart';
import '../inventory/inventory_actions.dart';
import 'pos_actions.dart';
import '../clients/v2/clients_actions_v2.dart';
import '../clients/client.dart';
import '../printer/printer_actions.dart';
import '../shell/app_drawer.dart';
import '../truck_load/truck_load_actions.dart';
import '../truck_load/truck_load_settings.dart';
import '../../core/preferences_service.dart';
import '../../core/tenant_db.dart';
import '../../models/sale.dart';

class POSView extends StatefulWidget {
  const POSView({super.key});

  @override
  State<POSView> createState() => _POSViewState();
}

class _POSViewState extends State<POSView> {
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _isGridView = PreferencesService().getBool('pos_grid_view') ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 800;
        
        return ListenableBuilder(
          listenable: Listenable.merge([InventoryActions(), POSActions(), ClientsActionsV2(), TruckLoadSettings()]),
          builder: (context, child) {
            final settings = TruckLoadSettings();
            final allProducts = List<Product>.from(InventoryActions().products);
            
            if (settings.sortMethod == 'Personalizado' && settings.customOrder.isNotEmpty) {
              allProducts.sort((a, b) {
                int idxA = settings.customOrder.indexOf(a.id);
                int idxB = settings.customOrder.indexOf(b.id);
                if (idxA == -1 && idxB == -1) return a.name.compareTo(b.name);
                if (idxA == -1) return 1;
                if (idxB == -1) return -1;
                return idxA.compareTo(idxB);
              });
            } else if (settings.sortMethod == 'Nombre') {
              allProducts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            } else if (settings.sortMethod == 'Categoría') {
              allProducts.sort((a, b) => a.category.toLowerCase().compareTo(b.category.toLowerCase()));
            } else if (settings.sortMethod == 'Precio') {
              allProducts.sort((a, b) => a.price.compareTo(b.price));
            }

            final cities = ClientsActionsV2().cities;
            final categories = ['Todas'];
            categories.addAll(allProducts.map((e) => e.category).toSet());
            final selectedCategory = POSActions().selectedCategory;

            final cityFilterWidget = SizedBox(
              width: 240,
              height: 40,
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.location_city, size: 20, color: Colors.black),
                  filled: true,
                  fillColor: AppTheme.primaryYellow,
                ),
                isExpanded: true,
                dropdownColor: AppTheme.primaryYellow,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                hint: const Text("Ciudad", style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold)),
                value: cities.contains(POSActions().selectedCity) ? POSActions().selectedCity : null,
                items: cities.isEmpty 
                  ? [
                      const DropdownMenuItem<String>(value: null, child: Text("Sin ciudades", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                    ]
                  : [
                      const DropdownMenuItem<String>(value: null, child: Text("Todas las ciudades", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                      ...cities.map((c) => DropdownMenuItem<String>(value: c, child: Text(c, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))),
                    ],
                onChanged: (val) {
                  POSActions().setCity(val);
                },
              ),
            );

            final filterBar = CustomHeaderFilterBar(
              showCategoryFilter: true,
              selectedCategory: selectedCategory,
              categoriesList: categories,
              onCategoryChanged: (cat) {
                if (cat != null) POSActions().setCategory(cat);
              },
              showZoneFilter: true,
              selectedZone: POSActions().selectedCity,
              onZoneChanged: (zone) => POSActions().setCity(zone == 'TODAS' ? null : zone),
              enableDatePicker: true,
              anchorDate: POSActions().saleDate,
              onDateChanged: (d) => POSActions().setSaleDate(d),
              onNavigatePrevious: () => POSActions().setSaleDate(POSActions().saleDate.subtract(const Duration(days: 1))),
              onNavigateNext: () => POSActions().setSaleDate(POSActions().saleDate.add(const Duration(days: 1))),
              customTrailingWidgets: [
                if (!POSActions().resellerMode)
                  ElevatedButton.icon(
                    onPressed: () => _showClientSelector(context),
                    icon: Icon(
                      POSActions().selectedClient != null ? Icons.person : Icons.person_add,
                      color: Colors.black,
                      size: 16,
                    ),
                    label: Text(
                      POSActions().selectedClient != null ? POSActions().selectedClient!.name : "Cliente",
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: POSActions().selectedClient != null ? Colors.greenAccent : AppTheme.primaryYellow,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
              ],
            );

            final viewToggleWidget = IconButton(
              icon: Icon(_isGridView ? Icons.list : Icons.grid_view, color: AppTheme.primaryYellow),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                  PreferencesService().setBool('pos_grid_view', _isGridView);
                });
              },
            );

            Widget body;
            if (isMobile) {
              body = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    child: filterBar,
                  ),
                  Expanded(child: _buildCatalog(true, allProducts, selectedCategory, const SizedBox())),
                  _buildMobileBottomBar(context),
                ],
              );
            } else {
              body = Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: filterBar,
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildCatalog(false, allProducts, selectedCategory, const SizedBox()),
                        ),
                        Expanded(
                          flex: 1,
                          child: _buildCart(false),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Scaffold(
              resizeToAvoidBottomInset: false,
              drawer: const AppDrawer(),
              appBar: AppBar(
                elevation: 0,
                title: const Text("Caja / POS"),
                actions: [
                  viewToggleWidget,
                  const SizedBox(width: 16),
                ],
              ),
              body: body,
            );
          }
        );
      }
    );
  }

  Widget _buildMobileBottomBar(BuildContext context) {
    return ListenableBuilder(
      listenable: POSActions(),
      builder: (context, child) {
        final cart = POSActions().cart;
        final total = POSActions().getTotal();
        if (cart.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceDark,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -5))],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("${cart.length} productos", style: const TextStyle(color: AppTheme.textSecondary)),
                    Text('\$${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.greenAccent)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,

                      builder: (context) => Container(
                        height: MediaQuery.of(context).size.height * 0.8,
                        decoration: const BoxDecoration(
                          color: AppTheme.backgroundDark,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 5,
                              width: 40,
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(10)),
                            ),
                            Expanded(child: _buildCart(true)),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart_checkout, color: Colors.black),
                  label: const Text("VER PEDIDO", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                )
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildCatalog(bool isMobile, List<Product> allProducts, String selectedCategory, Widget categoryFilter) {
    final client = POSActions().selectedClient;
    var products = selectedCategory == 'Todas' 
      ? allProducts 
      : allProducts.where((p) => p.category == selectedCategory).toList();

    if (client != null && client.type == 'revendedor') {
      if (client.customPrices.isNotEmpty) {
        products = products.where((p) {
          if (p.variants.isEmpty) {
            return client.customPrices.containsKey(p.id);
          } else {
            return p.variants.any((v) => client.customPrices.containsKey("${p.id}_${v.name}"));
          }
        }).toList();
      } else {
        products = products.where((p) {
          if (p.variants.isEmpty) {
            return p.resellerPrice != null && p.resellerPrice! > 0;
          } else {
            return p.variants.any((v) => v.resellerPrice != null && v.resellerPrice! > 0);
          }
        }).toList();
      }
    } else if (client != null && client.type == 'especial') {
      if (client.customPrices.isNotEmpty) {
        products = products.where((p) {
          if (p.variants.isEmpty) {
            return client.customPrices.containsKey(p.id);
          } else {
            return p.variants.any((v) => client.customPrices.containsKey("${p.id}_${v.name}"));
          }
        }).toList();
      } else {
        products = products.where((p) {
          if (p.variants.isEmpty) {
            return p.specialPrice != null && p.specialPrice! > 0;
          } else {
            return p.variants.any((v) => v.specialPrice != null && v.specialPrice! > 0);
          }
        }).toList();
      }
    }

    return Container(
      padding: EdgeInsets.only(
        left: isMobile ? 16 : 24,
        right: isMobile ? 16 : 24,
        top: isMobile ? 4 : 8,
        bottom: isMobile ? 16 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Catálogo de Productos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 1.5)),
              if (!isMobile) categoryFilter,
            ]
          ),
          const SizedBox(height: 8),
          Expanded(
            child: products.isEmpty
              ? const Center(child: Text("No hay productos en esta categoría.", style: TextStyle(color: AppTheme.textSecondary)))
              : (_isGridView
                  ? GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isMobile ? 2 : 3, 
                        childAspectRatio: isMobile ? 1.1 : 1.3,
                        crossAxisSpacing: isMobile ? 12 : 16,
                        mainAxisSpacing: isMobile ? 12 : 16,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        double displayPrice = product.price;
                        if (product.variants.isEmpty) {
                          displayPrice = POSActions().getPriceForClient(client, product) ?? product.price;
                        } else {
                          double minPrice = double.infinity;
                          for (var v in product.variants) {
                            double p = POSActions().getPriceForClient(client, product, v) ?? v.price ?? product.price;
                            if (p < minPrice) minPrice = p;
                          }
                          if (minPrice != double.infinity) displayPrice = minPrice;
                        }
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            splashColor: AppTheme.primaryYellow.withOpacity(0.3),
                            highlightColor: AppTheme.primaryYellow.withOpacity(0.1),
                            onTap: () {
                              if (product.variants.isEmpty) {
                                POSActions().addToCart(product);
                              } else {
                                _showVariantSelector(context, product);
                              }
                            },
                            onLongPress: () {
                              if (product.variants.isEmpty) {
                                _showManualQuantityDialog(context, product, null);
                              } else {
                                _showVariantSelector(context, product);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      product.name,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.2),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        product.variants.isNotEmpty ? 'Desde \$${displayPrice.toStringAsFixed(0)}' : '\$${displayPrice.toStringAsFixed(0)}',
                                        style: const TextStyle(fontSize: 20, color: AppTheme.primaryYellow, fontWeight: FontWeight.w900),
                                      ),
                                      if (product.variants.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: AppTheme.primaryYellow.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                          child: const Text("+ Variantes", style: TextStyle(color: AppTheme.primaryYellow, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryYellow.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.add, color: AppTheme.primaryYellow, size: 20),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        double displayPrice = product.price;
                        if (product.variants.isEmpty) {
                          displayPrice = POSActions().getPriceForClient(client, product) ?? product.price;
                        } else {
                          double minPrice = double.infinity;
                          for (var v in product.variants) {
                            double p = POSActions().getPriceForClient(client, product, v) ?? v.price ?? product.price;
                            if (p < minPrice) minPrice = p;
                          }
                          if (minPrice != double.infinity) displayPrice = minPrice;
                        }
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () {
                              if (product.variants.isEmpty) {
                                POSActions().addToCart(product);
                              } else {
                                _showVariantSelector(context, product);
                              }
                            },
                            onLongPress: () {
                              if (product.variants.isEmpty) {
                                _showManualQuantityDialog(context, product, null);
                              } else {
                                _showVariantSelector(context, product);
                              }
                            },
                            title: Row(
                              children: [
                                Expanded(child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                                if (product.variants.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: AppTheme.primaryYellow.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                    child: const Text("+ Variantes", style: TextStyle(color: AppTheme.primaryYellow, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                              ]
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(product.variants.isNotEmpty ? 'Desde \$${displayPrice.toStringAsFixed(0)}' : '\$${displayPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, color: AppTheme.primaryYellow, fontWeight: FontWeight.w900)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryYellow.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.add, color: AppTheme.primaryYellow, size: 20),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    )),
          ),
        ],
      ),
    );
  }

  Widget _buildCart(bool isMobile) {
    return Container(
      color: AppTheme.surfaceDark,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: ListenableBuilder(
        listenable: POSActions(),
        builder: (context, child) {
          final cart = POSActions().cart;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Pedido Actual", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  // Ocultar el botón asignar cliente si estamos en modo revendedor
                  if (!POSActions().resellerMode)
                    IconButton(
                      icon: const Icon(Icons.person_add, color: AppTheme.primaryYellow),
                      onPressed: () => _showClientSelector(context),
                      tooltip: "Asignar Cliente",
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryYellow.withOpacity(0.5)),
                      ),
                      child: const Text("REVENDEDOR", style: TextStyle(color: AppTheme.primaryYellow, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              if (POSActions().selectedClient != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Cliente: ${POSActions().selectedClient!.name} (${POSActions().selectedClient!.city})",
                          style: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close, color: AppTheme.danger, size: 24),
                        onPressed: () => POSActions().setClient(null),
                        tooltip: "Desasignar Cliente",
                      )
                    ],
                  )
                ),
              const Divider(color: AppTheme.primaryYellow, height: 32, thickness: 1),
              
              Expanded(
                child: (cart.isEmpty && POSActions().exchanges.isEmpty)
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_basket_outlined, size: 64, color: AppTheme.textSecondary),
                            SizedBox(height: 16),
                            Text("El carrito está vacío", style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                          ],
                        )
                      )
                    : ListView(
                        children: [
                          ...cart.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.selectedVariant == null ? item.product.name : '${item.product.name} (${item.selectedVariant!.name})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                        const SizedBox(height: 2),
                                        // Precio unitario
                                        Text('\$${item.unitPrice.toStringAsFixed(0)} c/u', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                        // Descuento — tappable para editar
                                        if (item.manualDiscount > 0)
                                          GestureDetector(
                                            onTap: () => _showManualDiscountDialog(context, item),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.local_offer, color: Colors.greenAccent, size: 12),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    'Desc. -\$${item.manualDiscount.toStringAsFixed(0)} c/u',
                                                    style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          GestureDetector(
                                            onTap: () => _showManualDiscountDialog(context, item),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.discount_outlined, color: AppTheme.primaryYellow, size: 12),
                                                SizedBox(width: 4),
                                                Text('Agregar descuento', style: TextStyle(color: AppTheme.primaryYellow, fontSize: 11)),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: AppTheme.textSecondary),
                                        onPressed: () => POSActions().updateQuantity(item.product.id, item.selectedVariant?.name, -1),
                                      ),
                                      InkWell(
                                        onTap: () => _showManualQuantityDialog(context, item.product, item.selectedVariant, initialValue: item.quantity, isUpdate: true),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                          child: Text('${item.quantity}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryYellow),
                                        onPressed: () => POSActions().updateQuantity(item.product.id, item.selectedVariant?.name, 1),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: AppTheme.danger),
                                        onPressed: () => POSActions().removeFromCart(item.product.id, item.selectedVariant?.name),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      '\$${item.total.toStringAsFixed(0)}', 
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primaryYellow)
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                          if (POSActions().exchanges.isNotEmpty) ...[
                             const Divider(color: Colors.white10, height: 24),
                             const Padding(
                               padding: EdgeInsets.symmetric(vertical: 8.0),
                               child: Text("Cambios:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                             ),
                             ...POSActions().exchanges.map((item) => Padding(
                               padding: const EdgeInsets.only(bottom: 8.0),
                               child: Row(
                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                 children: [
                                   Expanded(child: Text("${item.quantity}x ${item.product.name}${item.selectedVariant != null ? ' (${item.selectedVariant!.name})' : ''}", style: const TextStyle(color: AppTheme.textSecondary))),
                                   IconButton(
                                     padding: EdgeInsets.zero,
                                     constraints: const BoxConstraints(),
                                     icon: const Icon(Icons.delete, color: AppTheme.danger, size: 20),
                                     onPressed: () => POSActions().removeExchange(item.product.id, item.selectedVariant?.name),
                                   )
                                 ],
                               ),
                             )).toList(),
                          ]
                        ]
                      ),
              ),
              
              const Divider(color: AppTheme.primaryYellow, height: 32, thickness: 1),
              
              if (POSActions().getDiscount() > 0 || POSActions().selectedClient?.balance != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Subtotal Hoy", style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                      Text('\$${POSActions().getSubtotal().toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                    ],
                  ),
                  if (POSActions().getDiscount() > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Descuentos", style: TextStyle(fontSize: 16, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                        Text('-\$${POSActions().getDiscount().toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                  if (POSActions().selectedClient != null) ...[
                    Builder(
                      builder: (context) {
                        double displayBalance = POSActions().selectedClient!.balance;
                        if (POSActions().editingSaleOriginalDebt != null) {
                          displayBalance -= POSActions().editingSaleOriginalDebt!;
                        }
                        if (displayBalance != 0) {
                          return Column(
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Saldo Pendiente", style: TextStyle(fontSize: 16, color: AppTheme.danger, fontWeight: FontWeight.bold)),
                                  Text(
                                    (displayBalance > 0 ? '+' : '') + '\$${displayBalance.toStringAsFixed(0)}', 
                                    style: TextStyle(fontSize: 16, color: displayBalance > 0 ? AppTheme.danger : Colors.greenAccent, fontWeight: FontWeight.bold)
                                  ),
                                ],
                              ),
                            ]
                          );
                        }
                        return const SizedBox.shrink();
                      }
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("TOTAL HOY", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    Text('\$${POSActions().getTotal().toStringAsFixed(0)}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.greenAccent)),
                  ],
                ),
                if (POSActions().selectedClient != null) ...[
                  Builder(
                    builder: (context) {
                      double displayBalance = POSActions().selectedClient!.balance;
                      if (POSActions().editingSaleOriginalDebt != null) {
                        displayBalance -= POSActions().editingSaleOriginalDebt!;
                      }
                      if (displayBalance != 0) {
                        return Column(
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("TOTAL + DEUDA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryYellow)),
                                Text('\$${(POSActions().getTotal() + displayBalance).toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primaryYellow)),
                              ],
                            ),
                          ]
                        );
                      }
                      return const SizedBox.shrink();
                    }
                  ),
                ],

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: cart.isEmpty ? null : () {
                  if (POSActions().selectedClient == null) {
                    _showNoClientConfirmation(context, cart);
                  } else {
                    _showCheckoutOptions(context, cart);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  minimumSize: const Size.fromHeight(60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("COBRAR", style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showExchangeDialog(context),
                      icon: const Icon(Icons.swap_horiz, color: AppTheme.primaryYellow, size: 18),
                      label: const Text("CAMBIOS", style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryYellow),
                        minimumSize: const Size.fromHeight(45),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (cart.isEmpty && POSActions().exchanges.isEmpty && POSActions().selectedClient == null && POSActions().editingSaleId == null) ? null : () => POSActions().clearCart(),
                      icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 18),
                      label: const Text("CANCELAR", style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.danger),
                        minimumSize: const Size.fromHeight(45),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }
      ),
    );
  }

  void _showNoClientConfirmation(BuildContext context, List<CartItem> cart) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text("Falta Cliente", style: TextStyle(color: AppTheme.primaryYellow)),
        content: const Text("¿SEGURO que quieres cerrar la venta sin un cliente asignado? (Venta de paso / mostrador)"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showClientSelector(context);
            },
            child: const Text("ASIGNAR CLIENTE", style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _showCheckoutOptions(context, cart);
            },
            child: const Text("CERRAR ASÍ", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCheckoutOptions(BuildContext context, List<CartItem> cart) {
      double saleSubtotal = POSActions().getSubtotal();
      double saleDiscount = POSActions().getDiscount();
      double saleTotal = POSActions().getTotal();
      double clientDebt = POSActions().selectedClient?.balance ?? 0.0;
      if (POSActions().editingSaleOriginalDebt != null) {
        clientDebt -= POSActions().editingSaleOriginalDebt!;
      }
      double currentTotal = saleTotal + clientDebt;
      
      final paidCtrl = TextEditingController(text: currentTotal.toStringAsFixed(0));
      final cashCtrl = TextEditingController(text: currentTotal.toStringAsFixed(0));
      final transferCtrl = TextEditingController(text: '0');
    String selectedMethod = 'Efectivo';
    bool printReceipt = true;
    bool printDuplicate = false;
    bool printCleanTicket = false;
    bool cashManual = false;
    bool transferManual = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool _isConfirming = false;

            void updateMixtoTotal() {
              double cash = double.tryParse(cashCtrl.text) ?? 0;
              double transfer = double.tryParse(transferCtrl.text) ?? 0;
              paidCtrl.text = (cash + transfer).toStringAsFixed(0);
            }

            void updateTotal() {
              currentTotal = saleTotal + clientDebt;
              if (selectedMethod != 'Pendiente') {
                paidCtrl.text = currentTotal.toStringAsFixed(0);
                if (selectedMethod == 'Mixto') {
                  cashCtrl.text = currentTotal.toStringAsFixed(0);
                  transferCtrl.text = '0';
                  cashManual = false;
                  transferManual = false;
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      const Text("Procesar Pago", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Subtotal Venta:", style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                          Text("\$${saleSubtotal.toStringAsFixed(0)}", style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary)),
                        ],
                      ),
                      if (saleDiscount > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Descuento:", style: TextStyle(fontSize: 16, color: AppTheme.danger)),
                            Text("-\$${saleDiscount.toStringAsFixed(0)}", style: const TextStyle(fontSize: 16, color: AppTheme.danger)),
                          ],
                        ),
                      const Divider(color: Colors.white24, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total Venta Hoy:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          Text("\$${saleTotal.toStringAsFixed(0)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        ],
                      ),
 
                      if (clientDebt != 0) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(clientDebt > 0 ? "El cliente tiene DEUDA: \$${clientDebt.toStringAsFixed(0)}" : "El cliente tiene SALDO A FAVOR: \$${clientDebt.abs().toStringAsFixed(0)}", 
                                style: TextStyle(color: clientDebt > 0 ? AppTheme.danger : Colors.greenAccent, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text("TOTAL A PAGAR: \$${currentTotal.toStringAsFixed(0)}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.greenAccent)),
                      const SizedBox(height: 16),
                      if (selectedMethod != 'Mixto') ...[
                        TextField(
                          controller: paidCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                             labelText: 'Monto entregado por el cliente',
                             prefixIcon: Icon(Icons.attach_money),
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: cashCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                   labelText: 'Pago en Efectivo (\$)',
                                   prefixIcon: Icon(Icons.money),
                                ),
                                onChanged: (v) {
                                  setState(() {
                                    cashManual = v.isNotEmpty && v != '0';
                                    if (cashManual && !transferManual) {
                                      double cashVal = double.tryParse(v) ?? 0;
                                      double transVal = currentTotal - cashVal;
                                      if (transVal < 0) transVal = 0;
                                      transferCtrl.text = transVal.toStringAsFixed(0);
                                    }
                                    if (v.isEmpty || v == '0') {
                                      cashManual = false;
                                    }
                                    updateMixtoTotal();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: transferCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                   labelText: 'Pago por Transf. (\$)',
                                   prefixIcon: Icon(Icons.account_balance),
                                ),
                                onChanged: (v) {
                                  setState(() {
                                    transferManual = v.isNotEmpty && v != '0';
                                    if (transferManual && !cashManual) {
                                      double transVal = double.tryParse(v) ?? 0;
                                      double cashVal = currentTotal - transVal;
                                      if (cashVal < 0) cashVal = 0;
                                      cashCtrl.text = cashVal.toStringAsFixed(0);
                                    }
                                    if (v.isEmpty || v == '0') {
                                      transferManual = false;
                                    }
                                    updateMixtoTotal();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Total Entregado (Mixto): \$${paidCtrl.text}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    const SizedBox(height: 16),
                    Row(
                       children: [
                         Expanded(
                           child: RadioListTile<String>(
                             title: const Text('Efectivo', style: TextStyle(fontSize: 13)),
                             value: 'Efectivo',
                             groupValue: selectedMethod,
                             onChanged: (val) => setState(() {
                               selectedMethod = val!;
                               updateTotal();
                             }),
                             activeColor: AppTheme.primaryYellow,
                             contentPadding: EdgeInsets.zero,
                           )
                         ),
                         Expanded(
                           child: RadioListTile<String>(
                             title: const Text('Transf.', style: TextStyle(fontSize: 13)),
                             value: 'Transferencia',
                             groupValue: selectedMethod,
                             onChanged: (val) => setState(() {
                               selectedMethod = val!;
                               updateTotal();
                             }),
                             activeColor: AppTheme.primaryYellow,
                             contentPadding: EdgeInsets.zero,
                           )
                         ),
                         Expanded(
                           child: RadioListTile<String>(
                             title: const Text('Mixto', style: TextStyle(fontSize: 13)),
                             value: 'Mixto',
                             groupValue: selectedMethod,
                             onChanged: (val) => setState(() {
                               selectedMethod = val!;
                               updateTotal();
                             }),
                             activeColor: AppTheme.primaryYellow,
                             contentPadding: EdgeInsets.zero,
                           )
                         ),
                       ]
                    ),
                    RadioListTile<String>(
                      title: const Text('Dejar Pendiente (No pagó)'),
                      value: 'Pendiente',
                      groupValue: selectedMethod,
                      onChanged: (val) {
                        setState(() {
                          selectedMethod = val!;
                          paidCtrl.text = "0";
                        });
                      },
                      activeColor: AppTheme.primaryYellow,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Imprimir Ticket"),
                        Switch(
                          value: printReceipt,
                          onChanged: (v) => setState(() {
                            printReceipt = v;
                            if (!v) printDuplicate = false;
                          }),
                          activeColor: AppTheme.primaryYellow,
                        )
                      ]
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Imprimir Duplicado", style: TextStyle(color: printReceipt ? Colors.white : Colors.grey)),
                        Switch(
                          value: printDuplicate,
                          onChanged: printReceipt ? (v) => setState(() => printDuplicate = v) : null,
                          activeColor: AppTheme.primaryYellow,
                        )
                      ]
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Ticket Limpio (Sin Saldos)", style: TextStyle(color: printReceipt ? Colors.white : Colors.grey)),
                        Switch(
                          value: printCleanTicket,
                          onChanged: printReceipt ? (v) => setState(() => printCleanTicket = v) : null,
                          activeColor: AppTheme.primaryYellow,
                        )
                      ]
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isConfirming ? null : () async {
                        // Check for low stock
                        final truckActions = TruckLoadActions();
                        List<String> lowStockWarnings = [];
                        for (var item in cart) {
                          if (!POSActions().resellerMode && POSActions().editingSaleId == null) {
                            String vName = item.selectedVariant?.name ?? "Única";
                            int? currentStock = truckActions.getStockForVariant(item.product.id, vName);
                            if (currentStock != null) {
                              int futureStock = currentStock - item.quantity;
                              int threshold = item.selectedVariant?.lowStockThreshold ?? 0;
                              if (futureStock <= threshold) {
                                lowStockWarnings.add("${item.product.name} $vName (Quedarán $futureStock)");
                              }
                            }
                          }
                        }

                        if (lowStockWarnings.isNotEmpty) {
                          bool? proceed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppTheme.surfaceDark,
                              title: const Text('Stock Bajo Detectado', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Los siguientes productos quedarán con stock bajo o negativo:'),
                                  const SizedBox(height: 8),
                                  ...lowStockWarnings.map((w) => Text("• $w", style: const TextStyle(color: AppTheme.primaryYellow))),
                                  const SizedBox(height: 16),
                                  const Text('¿Deseas continuar con la venta de todos modos?'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Sí, continuar', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (proceed != true) return;
                        }

                        setState(() {
                          _isConfirming = true;
                        });
                        try {
                          double paid = double.tryParse(paidCtrl.text) ?? 0;
                          if (selectedMethod == 'Pendiente') paid = 0;
                          
                          double cashAmt = 0;
                          double transferAmt = 0;
                          if (selectedMethod == 'Efectivo') {
                            cashAmt = paid;
                          } else if (selectedMethod == 'Transferencia') {
                            transferAmt = paid;
                          } else if (selectedMethod == 'Mixto') {
                            cashAmt = double.tryParse(cashCtrl.text) ?? 0;
                            transferAmt = double.tryParse(transferCtrl.text) ?? 0;
                            paid = cashAmt + transferAmt;
                          }

                          double includedDebt = clientDebt;
                          
                          // Cerrar el diálogo flotante de cobro de inmediato (0ms)
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                          
                          await _processSale(
                            context, 
                            cart, 
                            printReceipt: printReceipt, 
                            printDuplicate: printDuplicate,
                            printCleanTicket: printCleanTicket,
                            paidAmount: paid, 
                            paymentMethod: selectedMethod, 
                            cashAmount: cashAmt,
                            transferAmount: transferAmt,
                            includedDebt: includedDebt, 
                            saleDate: POSActions().saleDate,
                          );
                        } catch (e) {
                          // Error manejado en processSale
                        } finally {
                          if (context.mounted) {
                            setState(() {
                              _isConfirming = false;
                            });
                          }
                        }
                      },
                      icon: _isConfirming 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Icon(Icons.check, color: Colors.black),
                      label: Text(_isConfirming ? "PROCESANDO..." : "CONFIRMAR VENTA", style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        minimumSize: const Size.fromHeight(60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ]
                ),
              ),
            );
            }
          );
       }
     );
  }

  Future<void> _processSale(BuildContext context, List<CartItem> cart, {
    bool printReceipt = true, 
    bool printDuplicate = false,
    bool printCleanTicket = false,
    required double paidAmount, 
    required String paymentMethod, 
    double cashAmount = 0,
    double transferAmount = 0,
    double includedDebt = 0, 
    required DateTime saleDate
  }) async {
    final posActions = POSActions();
    final selectedClient = posActions.selectedClient;
    
    // Capturar datos del carrito ANTES de limpiar (para imprimir después)
    final cartSnapshot = List<CartItem>.from(cart);
    final exchangesSnapshot = List<ExchangeItem>.from(posActions.exchanges);
    final subtotalSnap = posActions.getSubtotal();
    final discountSnap = posActions.getDiscount();
    final totalSnap = posActions.getTotal();
    final promoNamesSnap = List<String>.from(posActions.appliedPromoNames);

    // ─── 1. PRIMERO GUARDAR LA VENTA (no depende de la impresora) ───
    try {
      final selectedCity = posActions.selectedCity;
      final editingSaleId = posActions.editingSaleId;
      
      final double totalSale = totalSnap;
      final double prevBal = selectedClient?.balance ?? 0.0;
      final double remBal = prevBal + totalSale - paidAmount;

      final saleData = {
        'total': totalSale,
        'discountAmount': discountSnap,
        'appliedPromos': promoNamesSnap,
        'paidAmount': paidAmount,
        'paymentMethod': paymentMethod,
        'cashAmount': cashAmount,
        'transferAmount': transferAmount,

        'previousBalance': prevBal,
        'remainingBalance': remBal,
        'items': cartSnapshot.map((e) => {
          'productId': e.product.id,
          'productName': e.product.name,
          'price': e.unitPrice,
          'quantity': e.quantity,
          'variantName': e.selectedVariant?.name,
        }).toList(),
        'exchanges': exchangesSnapshot.map((e) => {
          'productId': e.product.id,
          'productName': e.product.name,
          'quantity': e.quantity,
          'variantName': e.selectedVariant?.name,
        }).toList(),
        'clientId': selectedClient?.id,
        'clientName': selectedClient?.name,
        'city': selectedCity,
      };

      // Limpiar carrito inmediatamente (UI responde antes de ir a red)
      posActions.clearCart();

      final batch = FirebaseFirestore.instance.batch();

      if (editingSaleId == null) {
        DateTime now = DateTime.now();
        DateTime finalDate = DateTime(saleDate.year, saleDate.month, saleDate.day, now.hour, now.minute, now.second);
        saleData['date'] = Timestamp.fromDate(finalDate);
        
        final newSaleRef = TenantDB.collection('sales').doc();
        batch.set(newSaleRef, saleData);
        
        if (selectedClient != null) {
          if (saleDate.day == now.day && saleDate.month == now.month && saleDate.year == now.year) {
             ClientsActionsV2().markVisit(selectedClient.id, 'visited');
          }
          double debtAdded = totalSnap - paidAmount;
          if (debtAdded != 0) {
            ClientsActionsV2().updateLocalBalance(selectedClient.id, debtAdded); // Actualización local inmediata
            final clientRef = TenantDB.collection('clients').doc(selectedClient.id);
            batch.update(clientRef, {'balance': FieldValue.increment(debtAdded)});
          }
        }
      } else {
        // Read old sale to revert debt
        DocumentSnapshot oldSaleSnap;
        try {
          oldSaleSnap = await TenantDB.collection('sales').doc(editingSaleId).get(const GetOptions(source: Source.cache));
        } catch (_) {
          oldSaleSnap = await TenantDB.collection('sales').doc(editingSaleId).get();
        }
        Map<String, dynamic>? oldData = oldSaleSnap.data() as Map<String, dynamic>?;
        double oldTotal = (oldData?['total'] ?? 0.0).toDouble();
        
        double oldPaid;
        if (oldData != null && oldData.containsKey('paidAmount') && oldData['paidAmount'] != null) {
          oldPaid = (oldData['paidAmount'] as num).toDouble();
        } else if (oldData?['paymentMethod'] == 'Pendiente') {
          oldPaid = 0.0;
        } else {
          oldPaid = oldTotal;
        }
        double oldDebt = oldTotal - oldPaid;
        String? oldClientId = oldData?['clientId'];

        double oldPrevBal = (oldData?['previousBalance'] ?? 0.0).toDouble();
        saleData['previousBalance'] = oldPrevBal;
        saleData['remainingBalance'] = oldPrevBal + totalSnap - paidAmount;

        Timestamp? oldTimestamp = oldData?['date'];
        DateTime oldDate = oldTimestamp?.toDate() ?? DateTime.now();
        DateTime finalDate = DateTime(saleDate.year, saleDate.month, saleDate.day, oldDate.hour, oldDate.minute, oldDate.second);
        saleData['date'] = Timestamp.fromDate(finalDate);

        final editSaleRef = TenantDB.collection('sales').doc(editingSaleId);
        batch.update(editSaleRef, saleData);
        
        double newDebt = totalSnap - paidAmount;
        
        if (oldClientId == selectedClient?.id && selectedClient != null) {
            double debtDiff = newDebt - oldDebt;
            if (debtDiff != 0) {
                ClientsActionsV2().updateLocalBalance(selectedClient.id, debtDiff); // Actualización local inmediata
                final clientRef = TenantDB.collection('clients').doc(selectedClient.id);
                batch.update(clientRef, {'balance': FieldValue.increment(debtDiff)});
            }
        } else {
            if (oldClientId != null && oldDebt != 0) {
                ClientsActionsV2().updateLocalBalance(oldClientId, -oldDebt); // Revertir saldo local anterior
                final oldClientRef = TenantDB.collection('clients').doc(oldClientId);
                batch.update(oldClientRef, {'balance': FieldValue.increment(-oldDebt)});
            }
            if (selectedClient != null && newDebt != 0) {
                ClientsActionsV2().updateLocalBalance(selectedClient.id, newDebt); // Asignar nuevo saldo local
                final newClientRef = TenantDB.collection('clients').doc(selectedClient.id);
                batch.update(newClientRef, {'balance': FieldValue.increment(newDebt)});
            }
        }
      }

      // Escribir en la base de datos local de Firestore de forma instantánea (0ms)
      // y forzar el envío inmediato de datos a la nube en segundo plano.
      batch.commit().then((_) {
        FirebaseFirestore.instance.waitForPendingWrites().timeout(
          const Duration(seconds: 4),
          onTimeout: () => debugPrint("La sincronización de la venta continuará en segundo plano."),
        );
      }).catchError((e) {
        debugPrint("Aviso: Error guardando lote en segundo plano: $e");
      });

      // Descontar del stock de la camioneta SOLO si es venta nueva (no edición)
      if (editingSaleId == null) {
        final truckActions = TruckLoadActions();
        for (var item in cartSnapshot) {
          String vName = item.selectedVariant?.name ?? "Única";
          truckActions.updateStock(item.product.id, vName, -item.quantity, 'sale_deduction');
        }
        for (var ex in exchangesSnapshot) {
          String vName = ex.selectedVariant?.name ?? "Única";
          truckActions.updateStock(ex.product.id, vName, ex.quantity, 'sale_return');
        }
      }

      // ─── 2. IMPRIMIR DESPUÉS DE GUARDAR (si falla, la venta ya quedó guardada) ───
      if (printReceipt && mounted) {
        bool showDetails = paidAmount > 0 || includedDebt != 0;
        bool printed = await PrinterActions.printTicket(
          cartSnapshot, subtotalSnap, discountSnap, promoNamesSnap, totalSnap,
          exchangesSnapshot, paidAmount, paymentMethod, selectedClient, includedDebt, false, showDetails, cleanTicket: printCleanTicket
        );
        if (!mounted) return;
        if (!printed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Venta guardada. ⚠️ No se pudo imprimir (impresora no conectada).'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        } else if (printDuplicate) {
          final bool userConfirmed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              title: const Text("Cortar Ticket Físico", style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold)),
              content: const Text(
                "El primer ticket se ha enviado a la impresora.\n\n"
                "Corta el papel del primer ticket y luego presiona 'IMPRIMIR DUPLICADO' para imprimir la copia.",
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Omitir Duplicado", style: TextStyle(color: AppTheme.textSecondary))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow, foregroundColor: Colors.black),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("IMPRIMIR DUPLICADO", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ) ?? false;
          if (userConfirmed && mounted) {
            bool showDetails = paidAmount > 0 || includedDebt != 0;
            await PrinterActions.printTicket(
              cartSnapshot, subtotalSnap, discountSnap, promoNamesSnap, totalSnap,
              exchangesSnapshot, paidAmount, paymentMethod, selectedClient, includedDebt, true, showDetails, cleanTicket: printCleanTicket
            );
          }
        }
      }
    } catch (e) {
      print("Error saving sale: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar la venta: $e'),
            backgroundColor: AppTheme.danger,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showExchangeDialog(BuildContext context) {
    Product? selectedProduct;
    ProductVariant? selectedVariant;
    int quantity = 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: AppTheme.backgroundDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: 500,
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Registrar Cambio / Devolución", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryYellow)),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppTheme.primaryYellow),
                            onPressed: () => Navigator.pop(context),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      Autocomplete<Product>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<Product>.empty();
                          }
                          return InventoryActions().products.where((Product p) {
                            return p.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        displayStringForOption: (Product p) => p.name,
                        onSelected: (Product p) {
                          setState(() {
                            selectedProduct = p;
                            selectedVariant = p.variants.isNotEmpty ? p.variants.first : null;
                          });
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: "Buscar producto",
                              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryYellow),
                              filled: true,
                              fillColor: AppTheme.surfaceDark,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      if (selectedProduct != null && selectedProduct!.variants.isNotEmpty) ...[
                        DropdownButtonFormField<ProductVariant>(
                          value: selectedVariant,
                          decoration: InputDecoration(
                            labelText: "Variante",
                            filled: true,
                            fillColor: AppTheme.surfaceDark,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          items: selectedProduct!.variants.map((v) {
                            int? currentStock = TruckLoadActions().getStockForVariant(selectedProduct!.id, v.name);
                            bool isLowStock = currentStock != null && v.lowStockThreshold != null && currentStock <= v.lowStockThreshold!;
                            return DropdownMenuItem<ProductVariant>(
                              value: v, 
                              child: Row(
                                children: [
                                  Text(v.name),
                                  if (isLowStock) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.warning_amber, color: AppTheme.danger, size: 16),
                                    const SizedBox(width: 4),
                                    Text('($currentStock)', style: const TextStyle(color: AppTheme.danger, fontSize: 12)),
                                  ]
                                ],
                              )
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => selectedVariant = val),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {
                              if (quantity > 1) setState(() => quantity--);
                            },
                            icon: const Icon(Icons.remove_circle_outline, size: 36, color: AppTheme.textSecondary),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text("$quantity", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                          ),
                          IconButton(
                            onPressed: () => setState(() => quantity++),
                            icon: const Icon(Icons.add_circle_outline, size: 36, color: AppTheme.primaryYellow),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: selectedProduct == null ? null : () {
                          POSActions().addExchange(selectedProduct!, selectedVariant, quantity);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryYellow,
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("AGREGAR CAMBIO", style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
              ),
            );
          }
        );
      }
    );
  }

  void _showVariantSelector(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.backgroundDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48), // Balance for the icon button to keep text perfectly centered
                    Expanded(
                      child: Text(
                        "Variantes de ${product.name}", 
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                      )
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.primaryYellow),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: product.variants.where((variant) {
                        final client = POSActions().selectedClient;
                        if (client != null && (client.type == 'especial' || client.type == 'revendedor')) {
                          if (client.customPrices.isNotEmpty) {
                            final key = "${product.id}_${variant.name}";
                            return client.customPrices.containsKey(key);
                          }
                        }
                        return true;
                      }).map((variant) {
                        final client = POSActions().selectedClient;
                        final price = POSActions().getPriceForClient(client, product, variant) ?? variant.price ?? product.price;
                        return Card(
                          color: AppTheme.surfaceDark,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(color: AppTheme.primaryYellow, width: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            splashColor: AppTheme.primaryYellow.withOpacity(0.3),
                            highlightColor: AppTheme.primaryYellow.withOpacity(0.1),
                            onTap: () {
                              POSActions().addToCart(product, variant);
                            },
                            onLongPress: () {
                              _showManualQuantityDialog(context, product, variant);
                            },
                            child: Container(
                              width: 140, // Fixed width for variants so they look like buttons
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    variant.name, 
                                    textAlign: TextAlign.center, 
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '\$${price.toStringAsFixed(0)}', 
                                    style: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.w900)
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  void _showClientSelector(BuildContext context) {
    String searchQuery = '';
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Container(
                width: 400,
                constraints: BoxConstraints(maxHeight: (MediaQuery.of(context).size.height - MediaQuery.of(context).viewInsets.bottom) * 0.85),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Seleccionar Cliente", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      cursorColor: AppTheme.primaryYellow,
                      decoration: const InputDecoration(
                        hintText: 'Buscar por nombre o dirección...',
                        hintStyle: TextStyle(color: AppTheme.textSecondary),
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (val) {
                        setState(() {
                          searchQuery = val.toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListenableBuilder(
                        listenable: ClientsActionsV2(),
                        builder: (context, child) {
                          final currentCity = POSActions().selectedCity;
                          var clients = ClientsActionsV2().allClients;
                          clients = clients.where((c) => c.type != 'revendedor').toList();
                          clients.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                          if (currentCity != null && currentCity.isNotEmpty) {
                            clients = clients.where((c) => c.city == currentCity).toList();
                          }
                          
                          if (searchQuery.isNotEmpty) {
                            clients = clients.where((c) => 
                              c.name.toLowerCase().contains(searchQuery) ||
                              c.address.toLowerCase().contains(searchQuery) ||
                              c.city.toLowerCase().contains(searchQuery) ||
                              c.nickname.toLowerCase().contains(searchQuery)
                            ).toList();
                          } else {
                            final today = DateTime.now().toString().substring(0, 10);
                            clients = clients.where((c) => c.lastVisitDate != today || c.lastVisitStatus == '').toList();
                          }
                          
                          if (clients.isEmpty) {
                            return Center(
                              child: Text(
                                currentCity != null && currentCity.isNotEmpty 
                                ? "No hay clientes en $currentCity que coincidan." 
                                : "No hay clientes que coincidan."
                              )
                            );
                          }
                          
                          return ListView.builder(
                            itemCount: clients.length,
                            itemBuilder: (context, index) {
                              final client = clients[index];
                              return ListTile(
                                leading: const Icon(Icons.person, color: AppTheme.primaryYellow),
                                title: Text(client.name),
                                subtitle: Text('${client.city} • ${client.address}'),
                                onTap: () {
                                  POSActions().setClient(client);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          );
                        }
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Cerramos el selector
                        _showCreateClientFromPOS(context); // Abrimos el formulario
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryYellow.withOpacity(0.2),
                        foregroundColor: AppTheme.primaryYellow,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppTheme.primaryYellow, width: 1),
                        )
                      ),
                      icon: const Icon(Icons.person_add),
                      label: const Text("CREAR NUEVO CLIENTE", style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              );
            }
          ),
        );
      }
    );
  }

  void _showManualQuantityDialog(BuildContext context, Product product, ProductVariant? variant, {int? initialValue, bool isUpdate = false}) {
    final ctrl = TextEditingController(text: initialValue != null ? initialValue.toString() : '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: Text("Cantidad para ${product.name}", style: const TextStyle(color: AppTheme.primaryYellow)),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(labelText: "Cantidad", border: OutlineInputBorder()),
            onSubmitted: (val) {
               final int q = int.tryParse(val) ?? 0;
               if (q > 0) {
                 if (isUpdate) {
                    final current = POSActions().cart.firstWhere((item) => item.product.id == product.id && item.selectedVariant?.name == variant?.name).quantity;
                    POSActions().updateQuantity(product.id, variant?.name, q - current);
                 } else {
                    for (int i=0; i<q; i++) {
                       POSActions().addToCart(product, variant);
                    }
                 }
               }
               Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow, foregroundColor: Colors.black),
              onPressed: () {
                 final int q = int.tryParse(ctrl.text) ?? 0;
                 if (q > 0) {
                   if (isUpdate) {
                      final current = POSActions().cart.firstWhere((item) => item.product.id == product.id && item.selectedVariant?.name == variant?.name).quantity;
                      POSActions().updateQuantity(product.id, variant?.name, q - current);
                   } else {
                      for (int i=0; i<q; i++) {
                         POSActions().addToCart(product, variant);
                      }
                   }
                 }
                 Navigator.pop(context);
              },
              child: const Text("GUARDAR"),
            )
          ]
        );
      }
    );
  }

  void _showManualDiscountDialog(BuildContext context, CartItem item) {
    // Detectar si el descuento actual era % (guardamos en $ siempre, pero mostramos el modo previo)
    bool isPercent = false;
    final ctrl = TextEditingController(
      text: item.manualDiscount > 0 ? item.manualDiscount.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          void _apply() {
            final val = double.tryParse(ctrl.text) ?? 0.0;
            double discountInPesos;
            if (isPercent) {
              // Convertir % a $ por unidad
              discountInPesos = item.unitPrice * val / 100.0;
            } else {
              discountInPesos = val;
            }
            // Clamp: no puede ser mayor que el precio unitario
            discountInPesos = discountInPesos.clamp(0, item.unitPrice);
            POSActions().updateManualDiscount(item.product.id, item.selectedVariant?.name, discountInPesos);
            Navigator.pop(ctx);
          }

          return AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: Text(
              "Descuento: ${item.product.name}${item.selectedVariant != null ? ' (${item.selectedVariant!.name})' : ''}",
              style: const TextStyle(color: AppTheme.primaryYellow, fontSize: 15),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Toggle $ / %
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setStateDialog(() => isPercent = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isPercent ? AppTheme.primaryYellow : Colors.white10,
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                          ),
                          child: Center(
                            child: Text('\$ Pesos',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !isPercent ? Colors.black : AppTheme.textSecondary,
                              )),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setStateDialog(() => isPercent = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isPercent ? AppTheme.primaryYellow : Colors.white10,
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                          ),
                          child: Center(
                            child: Text('% Porcentaje',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isPercent ? Colors.black : AppTheme.textSecondary,
                              )),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: isPercent ? 'Porcentaje de descuento' : 'Descuento en \$ por unidad',
                    hintText: isPercent ? 'Ej: 10 (= 10%)' : 'Ej: 500',
                    border: const OutlineInputBorder(),
                    prefixText: isPercent ? '' : '\$ ',
                    suffixText: isPercent ? '%' : '',
                    prefixStyle: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold),
                    suffixStyle: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold),
                  ),
                  onSubmitted: (_) => _apply(),
                ),
                const SizedBox(height: 8),
                // Preview
                if (ctrl.text.isNotEmpty)
                  Builder(builder: (_) {
                    final val = double.tryParse(ctrl.text) ?? 0.0;
                    final pesos = isPercent
                      ? (item.unitPrice * val / 100).clamp(0, item.unitPrice)
                      : val.clamp(0, item.unitPrice);
                    final precioFinal = item.unitPrice - pesos;
                    return Text(
                      'Precio final c/u: \$${precioFinal.toStringAsFixed(0)}  (antes: \$${item.unitPrice.toStringAsFixed(0)})',
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                    );
                  }),
              ],
            ),
            actions: [
              if (item.manualDiscount > 0)
                TextButton(
                  onPressed: () {
                    POSActions().updateManualDiscount(item.product.id, item.selectedVariant?.name, 0.0);
                    Navigator.pop(ctx);
                  },
                  child: const Text("QUITAR", style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
                ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow, foregroundColor: Colors.black),
                onPressed: _apply,
                child: const Text("APLICAR", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCreateClientFromPOS(BuildContext context) {
    final currentCity = POSActions().selectedCity ?? '';
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: currentCity);
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 400,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Nuevo Cliente", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre / Negocio', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  Autocomplete<String>(
                    initialValue: TextEditingValue(text: currentCity),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      final text = textEditingValue.text.toLowerCase();
                      final available = ClientsActionsV2().cities;
                      if (text.isEmpty) return available;
                      return available.where((c) => c.toLowerCase().contains(text));
                    },
                    onSelected: (String selection) {
                      cityCtrl.text = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onChanged: (val) => cityCtrl.text = val,
                        decoration: const InputDecoration(
                          labelText: 'Ciudad de Reparto',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder(), prefixIcon: Icon(Icons.map)),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryYellow,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          final phone = phoneCtrl.text.trim();
                          final city = cityCtrl.text.trim();
                          final address = addressCtrl.text.trim();

                          if (name.isNotEmpty && city.isNotEmpty) {
                            final client = await ClientsActionsV2().addClient(name, phone, city, address);
                            POSActions().setClient(client);
                            Navigator.pop(context); // Cierra modal creacion
                          }
                        },
                        child: const Text('Guardar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
  void _showPromosDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24.0),
            child: ListenableBuilder(
              listenable: POSActions(),
              builder: (context, _) {
                final applied = POSActions().appliedPromoNames;
                final ignored = POSActions().ignoredPromoNames;
                final allRelevant = {...applied, ...ignored}.toList();
                
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Gestionar Promociones", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryYellow)),
                    const SizedBox(height: 16),
                    if (allRelevant.isEmpty)
                      const Text("No hay promociones aplicables en este pedido.", style: TextStyle(color: AppTheme.textSecondary))
                    else
                      ...allRelevant.map((promoName) {
                        bool isIgnored = ignored.contains(promoName);
                        return SwitchListTile(
                          title: Text(promoName, style: TextStyle(color: isIgnored ? AppTheme.textSecondary : Colors.greenAccent, fontWeight: FontWeight.bold)),
                          value: !isIgnored,
                          activeColor: Colors.greenAccent,
                          onChanged: (val) {
                            POSActions().togglePromoIgnore(promoName);
                          },
                        );
                      }).toList(),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CERRAR", style: TextStyle(color: AppTheme.primaryYellow)),
                    )
                  ],
                );
              }
            ),
          ),
        );
      }
    );
  }
}
