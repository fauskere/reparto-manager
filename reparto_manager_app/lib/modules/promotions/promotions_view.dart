import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'promotions_actions.dart';
import '../inventory/inventory_actions.dart';
import '../../models/product.dart';
import '../../models/promotion.dart';
import '../shell/app_drawer.dart';
class PromotionsView extends StatelessWidget {
  const PromotionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 800;
        final isPhone = constraints.maxWidth <= 500;
        return Scaffold(

          drawer: const AppDrawer(),
          appBar: AppBar(

            elevation: 0,
            title: const Row(
              children: [
                Icon(Icons.sell, color: AppTheme.primaryYellow, size: 24),
                SizedBox(width: 8),
                Text("Promociones", style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          body: Padding(
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListenableBuilder(
                    listenable: Listenable.merge([PromotionsActions(), InventoryActions()]),
                    builder: (context, child) {
                      final actions = PromotionsActions();
                      final inventory = InventoryActions();
                      
                      if (actions.isLoading) {
                        return const Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow));
                      }
                      
                      if (actions.promotions.isEmpty) {
                        return const Center(
                          child: Text("No hay promociones creadas. ¡Crea una para impulsar tus ventas!", style: TextStyle(color: AppTheme.textSecondary)),
                        );
                      }

                      return ListView.builder(
                        itemCount: actions.promotions.length,
                        itemBuilder: (context, index) {
                          final promo = actions.promotions[index];
                          final productNames = promo.requiredItems.map((req) {
                            final p = inventory.products.where((prod) => prod.id == req.productId).firstOrNull;
                            final vName = req.variantName != null ? ' (${req.variantName})' : '';
                            return '${req.quantity}x ${p?.name ?? 'Eliminado'}$vName';
                          }).join(', ');

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: isPhone ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8) : null,
                              leading: Icon(
                                Icons.sell, 
                                color: promo.isActive ? AppTheme.primaryYellow : AppTheme.textSecondary,
                                size: isPhone ? 20 : 24,
                              ),
                              title: Text(promo.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isPhone ? 15 : 18)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Descuento: ${promo.discountPercentage.toStringAsFixed(0)}%", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text("Requiere: $productNames", style: const TextStyle(color: AppTheme.textSecondary)),
                                    if (isPhone) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Text("Activa:", style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                              Transform.scale(
                                                scale: 0.8,
                                                child: Switch(
                                                  value: promo.isActive,
                                                  onChanged: (val) {
                                                    PromotionsActions().togglePromotionStatus(promo.id, promo.isActive);
                                                  },
                                                  activeColor: AppTheme.primaryYellow,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: AppTheme.primaryYellow, size: 20),
                                                onPressed: () => _showCreatePromotionDialog(context, promo),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                              const SizedBox(width: 16),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: AppTheme.danger, size: 20),
                                                onPressed: () => _confirmDelete(context, promo.id),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              trailing: isPhone ? null : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: promo.isActive,
                                    onChanged: (val) {
                                      PromotionsActions().togglePromotionStatus(promo.id, promo.isActive);
                                    },
                                    activeColor: AppTheme.primaryYellow,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: AppTheme.primaryYellow),
                                    onPressed: () => _showCreatePromotionDialog(context, promo),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: AppTheme.danger),
                                    onPressed: () => _confirmDelete(context, promo.id),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
                  ),
                ),
                // Barra inferior con botón Nueva Promoción
                ListenableBuilder(
                  listenable: PromotionsActions(),
                  builder: (context, child) {
                    final promoCount = PromotionsActions().promotions.length;
                    return Container(
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
                            onPressed: () => _showCreatePromotionDialog(context, null),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryYellow,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            icon: const Icon(Icons.add_shopping_cart, size: 20),
                            label: const Text("Nueva Promoción", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          const Spacer(),
                          Text(
                            "TOTAL PROMOCIONES: $promoCount",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text("Eliminar Promoción"),
        content: const Text("¿Estás seguro de que deseas eliminar esta promoción de forma permanente?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white),
            onPressed: () {
              PromotionsActions().deletePromotion(id);
              Navigator.pop(context);
            },
            child: const Text("Eliminar"),
          ),
        ],
      )
    );
  }

  void _showCreatePromotionDialog(BuildContext context, Promotion? promo) {
    final nameCtrl = TextEditingController(text: promo?.name ?? '');
    final discountCtrl = TextEditingController(text: promo != null ? promo.discountPercentage.toStringAsFixed(0) : '');
    final searchCtrl = TextEditingController();
    // Key format: "productId|" or "productId|variantName"
    Map<String, int> selectedItems = {};
    if (promo != null) {
      for (var req in promo.requiredItems) {
        final key = "${req.productId}|${req.variantName ?? ''}";
        selectedItems[key] = req.quantity;
      }
    }
    String searchQuery = '';
    
    // Refresh inventory if needed
    if (InventoryActions().products.isEmpty) {
      InventoryActions(); // just touch it
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 500,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
            padding: const EdgeInsets.all(24.0),
            child: StatefulBuilder(
              builder: (context, setState) {
                final allProducts = InventoryActions().products.where((p) => 
                  p.name.toLowerCase().contains(searchQuery.toLowerCase()) || 
                  p.category.toLowerCase().contains(searchQuery.toLowerCase())
                ).toList();
                
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(promo == null ? "Nueva Promoción" : "Editar Promoción", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre de la Promo (Ej: Promo Aldea)', prefixIcon: Icon(Icons.sell)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: discountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Porcentaje de Descuento (Ej: 5)', prefixIcon: Icon(Icons.percent)),
                    ),
                    const SizedBox(height: 16),
                    const Text("Selecciona los productos requeridos:", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: searchCtrl,
                      onChanged: (val) {
                        setState(() {
                          searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Buscar producto...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryYellow),
                        filled: true,
                        fillColor: AppTheme.backgroundDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.textSecondary.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListView.builder(
                          itemCount: allProducts.length,
                          itemBuilder: (context, index) {
                            final p = allProducts[index];
                            final generalKey = "${p.id}|";
                            final generalQty = selectedItems[generalKey] ?? 0;

                            return ExpansionTile(
                              title: Text(p.name),
                              subtitle: Text(p.category, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              children: [
                                // Opción general (Cualquier variante)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Cualquier variante (Total):"),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: () {
                                            setState(() {
                                              if (generalQty > 0) {
                                                selectedItems[generalKey] = generalQty - 1;
                                                if (selectedItems[generalKey] == 0) selectedItems.remove(generalKey);
                                              }
                                            });
                                          }
                                        ),
                                        Text("$generalQty", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () {
                                            setState(() {
                                              selectedItems[generalKey] = generalQty + 1;
                                            });
                                          }
                                        ),
                                      ]
                                    )
                                  ]
                                ),
                                if (p.variants.isNotEmpty) const Divider(),
                                // Por variante
                                ...p.variants.map((v) {
                                   final varKey = "${p.id}|${v.name}";
                                   final varQty = selectedItems[varKey] ?? 0;
                                   return Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(" - Variante '${v.name}':", style: const TextStyle(color: AppTheme.textSecondary)),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove),
                                              onPressed: () {
                                                setState(() {
                                                  if (varQty > 0) {
                                                    selectedItems[varKey] = varQty - 1;
                                                    if (selectedItems[varKey] == 0) selectedItems.remove(varKey);
                                                  }
                                                });
                                              }
                                            ),
                                            Text("$varQty", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            IconButton(
                                              icon: const Icon(Icons.add),
                                              onPressed: () {
                                                setState(() {
                                                  selectedItems[varKey] = varQty + 1;
                                                });
                                              }
                                            ),
                                          ]
                                        )
                                      ]
                                   );
                                }),
                              ],
                            );
                          },
                        ),
                      ),
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
                          onPressed: () async {
                            final name = nameCtrl.text.trim();
                            final discount = double.tryParse(discountCtrl.text.trim()) ?? 0;
                            
                            if (name.isNotEmpty && discount > 0 && selectedItems.isNotEmpty) {
                              Navigator.pop(context);
                              List<PromoRequirement> reqs = [];
                              selectedItems.forEach((key, qty) {
                                final parts = key.split('|');
                                final pid = parts[0];
                                final vname = parts[1].isEmpty ? null : parts[1];
                                reqs.add(PromoRequirement(productId: pid, variantName: vname, quantity: qty));
                              });
                              if (promo == null) {
                                await PromotionsActions().addPromotion(name, discount, reqs);
                              } else {
                                await PromotionsActions().updatePromotion(promo.id, name, discount, reqs);
                              }
                            } else {
                              // Removed snackbars
                            }
                          },
                          child: const Text('Guardar'),
                        ),
                      ],
                    ),
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
