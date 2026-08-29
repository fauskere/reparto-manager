import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../models/sale.dart';
import '../inventory/inventory_actions.dart';
import '../printer/printer_actions.dart';
import 'client.dart';
import 'clients_actions.dart';

class ResellerSalesView extends StatefulWidget {
  final Client client;
  const ResellerSalesView({super.key, required this.client});

  @override
  State<ResellerSalesView> createState() => _ResellerSalesViewState();
}

class _ResellerSalesViewState extends State<ResellerSalesView> {
  final List<CartItem> _cart = [];
  String _searchQuery = '';
  bool _isSaving = false;

  double _getPrice(Product prod, [ProductVariant? variant]) {
    final key = variant != null ? "${prod.id}_${variant.name}" : prod.id;
    
    // 1. Precio personalizado del revendedor
    if (widget.client.customPrices.containsKey(key)) {
      return widget.client.customPrices[key]!;
    }
    
    // 2. Precio mayorista global
    if (variant != null) {
      if (variant.resellerPrice != null) return variant.resellerPrice!;
      return variant.price ?? prod.price;
    } else {
      if (prod.resellerPrice != null) return prod.resellerPrice!;
      return prod.price;
    }
  }

  void _addToCart(Product prod, [ProductVariant? variant]) {
    final idx = _cart.indexWhere((item) => 
      item.product.id == prod.id && item.selectedVariant?.name == variant?.name
    );

    final double price = _getPrice(prod, variant);

    setState(() {
      if (idx != -1) {
        _cart[idx] = CartItem(
          product: prod,
          selectedVariant: variant,
          quantity: _cart[idx].quantity + 1,
          overridePrice: price,
        );
      } else {
        _cart.add(CartItem(
          product: prod,
          selectedVariant: variant,
          quantity: 1,
          overridePrice: price,
        ));
      }
    });
  }

  void _updateQuantity(String productId, String? variantName, int delta) {
    final idx = _cart.indexWhere((item) => 
      item.product.id == productId && item.selectedVariant?.name == variantName
    );
    if (idx != -1) {
      setState(() {
        final newQty = _cart[idx].quantity + delta;
        if (newQty <= 0) {
          _cart.removeAt(idx);
        } else {
          _cart[idx] = CartItem(
            product: _cart[idx].product,
            selectedVariant: _cart[idx].selectedVariant,
            quantity: newQty,
            overridePrice: _cart[idx].unitPrice,
          );
        }
      });
    }
  }

  double _getTotal() {
    return _cart.fold(0.0, (sum, item) => sum + item.total);
  }

  Future<void> _processSale(BuildContext context, double total, double paid, String method, double cashAmt, double transferAmt, bool printReceipt, bool printDuplicate) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final double prevBal = widget.client.balance;
      final double remBal = prevBal + total - paid;

      final saleData = {
        'total': total,
        'discountAmount': 0.0,
        'appliedPromos': <String>[],
        'paidAmount': paid,
        'paymentMethod': method,
        'cashAmount': cashAmt,
        'transferAmount': transferAmt,
        'previousBalance': prevBal,
        'remainingBalance': remBal,
        'items': _cart.map((e) => {
          'productId': e.product.id,
          'productName': e.product.name,
          'price': e.unitPrice,
          'quantity': e.quantity,
          'variantName': e.selectedVariant?.name,
        }).toList(),
        'exchanges': <Map<String, dynamic>>[],
        'clientId': widget.client.id,
        'clientName': widget.client.name,
        'city': widget.client.city,
        'date': Timestamp.now(),
      };

      // 1. Guardar venta en Firebase
      await FirebaseFirestore.instance.collection('sales').add(saleData);

      // 2. Actualizar saldo local y en la nube
      double debtAdded = total - paid;
      ClientsActions().updateLocalBalance(widget.client.id, debtAdded);
      await FirebaseFirestore.instance.collection('clients').doc(widget.client.id).update({
        'balance': FieldValue.increment(debtAdded)
      });

      // 3. Imprimir ticket
      if (printReceipt) {
        await PrinterActions.printTicket(
          _cart, total, 0.0, [], total, [], paid, method, widget.client, 0.0, false
        );
        if (printDuplicate) {
          await Future.delayed(const Duration(milliseconds: 1500));
          await PrinterActions.printTicket(
            _cart, total, 0.0, [], total, [], paid, method, widget.client, 0.0, true
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Venta registrada con éxito."), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Volver
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al registrar venta: $e"), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showCheckoutDialog() {
    final double total = _getTotal();
    final paidCtrl = TextEditingController(text: total.toStringAsFixed(0));
    final cashCtrl = TextEditingController(text: total.toStringAsFixed(0));
    final transferCtrl = TextEditingController(text: '0');
    String method = 'Efectivo';
    bool printReceipt = true;
    bool printDuplicate = false;
    bool cashManual = false;
    bool transferManual = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            void updateMixtoTotal() {
              double c = double.tryParse(cashCtrl.text) ?? 0;
              double t = double.tryParse(transferCtrl.text) ?? 0;
              paidCtrl.text = (c + t).toStringAsFixed(0);
            }

            void updatePaymentValues() {
              if (method != 'Pendiente') {
                paidCtrl.text = total.toStringAsFixed(0);
                if (method == 'Mixto') {
                  cashCtrl.text = total.toStringAsFixed(0);
                  transferCtrl.text = '0';
                  cashManual = false;
                  transferManual = false;
                }
              } else {
                paidCtrl.text = '0';
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("Cobrar Revendedor", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Text("TOTAL VENTA: \$${total.toStringAsFixed(0)}", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.greenAccent), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    if (method != 'Mixto') ...[
                      TextField(
                        controller: paidCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Monto cobrado (\$)", prefixIcon: Icon(Icons.attach_money)),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: cashCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: "Efectivo (\$)", prefixIcon: Icon(Icons.attach_money)),
                              onChanged: (v) {
                                setModalState(() {
                                  cashManual = v.isNotEmpty && v != '0';
                                  if (cashManual && !transferManual) {
                                    double cashVal = double.tryParse(v) ?? 0;
                                    double transVal = total - cashVal;
                                    if (transVal < 0) transVal = 0;
                                    transferCtrl.text = transVal.toStringAsFixed(0);
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
                              decoration: const InputDecoration(labelText: "Transferencia (\$)", prefixIcon: Icon(Icons.account_balance)),
                              onChanged: (v) {
                                setModalState(() {
                                  transferManual = v.isNotEmpty && v != '0';
                                  if (transferManual && !cashManual) {
                                    double transVal = double.tryParse(v) ?? 0;
                                    double cashVal = total - transVal;
                                    if (cashVal < 0) cashVal = 0;
                                    cashCtrl.text = cashVal.toStringAsFixed(0);
                                  }
                                  updateMixtoTotal();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text("Total Cobrado Mixto: \$${paidCtrl.text}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent), textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Efectivo', style: TextStyle(fontSize: 12)),
                            value: 'Efectivo',
                            groupValue: method,
                            onChanged: (v) => setModalState(() { method = v!; updatePaymentValues(); }),
                            activeColor: AppTheme.primaryYellow,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Transf.', style: TextStyle(fontSize: 12)),
                            value: 'Transferencia',
                            groupValue: method,
                            onChanged: (v) => setModalState(() { method = v!; updatePaymentValues(); }),
                            activeColor: AppTheme.primaryYellow,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Mixto', style: TextStyle(fontSize: 12)),
                            value: 'Mixto',
                            groupValue: method,
                            onChanged: (v) => setModalState(() { method = v!; updatePaymentValues(); }),
                            activeColor: AppTheme.primaryYellow,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    RadioListTile<String>(
                      title: const Text('Dejar Pendiente (A Cuenta Corriente)'),
                      value: 'Pendiente',
                      groupValue: method,
                      onChanged: (v) => setModalState(() { method = v!; updatePaymentValues(); }),
                      activeColor: AppTheme.primaryYellow,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Imprimir Ticket"),
                        Switch(
                          value: printReceipt,
                          onChanged: (v) => setModalState(() { printReceipt = v; if(!v) printDuplicate = false; }),
                          activeColor: AppTheme.primaryYellow,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Imprimir Duplicado", style: TextStyle(color: printReceipt ? Colors.white : Colors.grey)),
                        Switch(
                          value: printDuplicate,
                          onChanged: printReceipt ? (v) => setModalState(() => printDuplicate = v) : null,
                          activeColor: AppTheme.primaryYellow,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSaving ? null : () {
                        double paid = double.tryParse(paidCtrl.text) ?? 0;
                        if (method == 'Pendiente') paid = 0;
                        double cashAmt = 0;
                        double transferAmt = 0;
                        if (method == 'Efectivo') cashAmt = paid;
                        if (method == 'Transferencia') transferAmt = paid;
                        if (method == 'Mixto') {
                          cashAmt = double.tryParse(cashCtrl.text) ?? 0;
                          transferAmt = double.tryParse(transferCtrl.text) ?? 0;
                          paid = cashAmt + transferAmt;
                        }

                        Navigator.pop(ctx); // Cierra bottomsheet
                        _processSale(context, total, paid, method, cashAmt, transferAmt, printReceipt, printDuplicate);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text("CONFIRMAR Y REGISTRAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _getTotal();
    return Scaffold(
      appBar: AppBar(
        title: Text("Nueva Venta: ${widget.client.name}"),
        backgroundColor: AppTheme.surfaceDark,
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: "Buscar producto...",
                      hintStyle: const TextStyle(color: Colors.black54),
                      prefixIcon: const Icon(Icons.search, color: Colors.black),
                      filled: true,
                      fillColor: AppTheme.primaryYellow,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: InventoryActions(),
                    builder: (context, child) {
                      var list = InventoryActions().products;
                      if (_searchQuery.isNotEmpty) {
                        list = list.where((p) => p.name.toLowerCase().contains(_searchQuery)).toList();
                      }

                      if (list.isEmpty) {
                        return const Center(child: Text("No hay productos disponibles."));
                      }

                      return ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final prod = list[index];
                          if (prod.variants.isEmpty) {
                            final price = _getPrice(prod);
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              child: ListTile(
                                title: Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("\$${price.toStringAsFixed(0)}", style: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle, color: AppTheme.primaryYellow),
                                      onPressed: () => _addToCart(prod),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            return ExpansionTile(
                              title: Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              initiallyExpanded: true,
                              children: prod.variants.map((v) {
                                final price = _getPrice(prod, v);
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 32),
                                  title: Text(v.name),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text("\$${price.toStringAsFixed(0)}", style: const TextStyle(color: AppTheme.primaryYellow, fontSize: 15)),
                                      const SizedBox(width: 16),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryYellow),
                                        onPressed: () => _addToCart(prod, v),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: AppTheme.surfaceDark,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Pedido del Revendedor", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Expanded(
                    child: _cart.isEmpty
                        ? const Center(child: Text("El pedido está vacío.", style: TextStyle(color: AppTheme.textSecondary)))
                        : ListView.builder(
                            itemCount: _cart.length,
                            itemBuilder: (context, index) {
                              final item = _cart[index];
                              final vName = item.selectedVariant != null ? ' (${item.selectedVariant!.name})' : '';
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text("${item.product.name}$vName", maxLines: 2, overflow: TextOverflow.ellipsis),
                                subtitle: Text("\$${item.unitPrice.toStringAsFixed(0)} c/u"),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 18),
                                      onPressed: () => _updateQuantity(item.product.id, item.selectedVariant?.name, -1),
                                    ),
                                    Text("${item.quantity}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 18),
                                      onPressed: () => _updateQuantity(item.product.id, item.selectedVariant?.name, 1),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("TOTAL:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("\$${total.toStringAsFixed(0)}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.greenAccent)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _cart.isEmpty || _isSaving ? null : _showCheckoutDialog,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _isSaving 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black))
                        : const Text("COBRAR VENTA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
