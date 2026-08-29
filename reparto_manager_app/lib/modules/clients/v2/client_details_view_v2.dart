import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../core/preferences_service.dart';
import '../client.dart';
import '../../../models/sale.dart';
import '../../../models/payment.dart';
import '../../../models/manual_debt.dart';
import '../../printer/printer_actions.dart';
import '../../pos/pos_actions.dart';
import '../../shell/app_shell.dart';
import 'clients_actions_v2.dart';
import 'client_details_dialogs_v2.dart';
import 'client_dialogs_v2.dart';
import 'client_price_list_view_v2.dart';

class ClientDetailsViewV2 extends StatefulWidget {
  final Client client;

  const ClientDetailsViewV2({super.key, required this.client});

  @override
  State<ClientDetailsViewV2> createState() => _ClientDetailsViewV2State();
}

class _ClientDetailsViewV2State extends State<ClientDetailsViewV2> {
  bool _isLoading = true;
  double _calculatedDebt = 0.0;
  List<dynamic> _transactions = [];
  bool _showCabinet = true;

  StreamSubscription<QuerySnapshot>? _salesSub;
  StreamSubscription<QuerySnapshot>? _paymentsSub;
  StreamSubscription<QuerySnapshot>? _debtsSub;

  List<Sale> _sales = [];
  List<Payment> _payments = [];
  List<ManualDebt> _debts = [];

  @override
  void initState() {
    super.initState();
    _showCabinet = PreferencesService().getBool('show_cc_cabinet') ?? true;
    _listenToAccountData();
  }

  @override
  void dispose() {
    _salesSub?.cancel();
    _paymentsSub?.cancel();
    _debtsSub?.cancel();
    super.dispose();
  }

  void _listenToAccountData() {
    final clientId = widget.client.id;
    final db = FirebaseFirestore.instance;

    _salesSub = db.collection('sales').where('clientId', isEqualTo: clientId).snapshots().listen((snap) {
      _sales = snap.docs.map((doc) => Sale.fromMap(doc.id, doc.data())).toList();
      _recalculateAndCombine();
    });

    _paymentsSub = db.collection('payments').where('clientId', isEqualTo: clientId).snapshots().listen((snap) {
      _payments = snap.docs.map((doc) => Payment.fromMap(doc.id, doc.data())).toList();
      _recalculateAndCombine();
    });

    _debtsSub = db.collection('manual_debts').where('clientId', isEqualTo: clientId).snapshots().listen((snap) {
      _debts = snap.docs.map((doc) => ManualDebt.fromMap(doc.id, doc.data())).toList();
      _recalculateAndCombine();
    });
  }

  /// Recalcula el saldo REAL de forma matemática infalible
  void _recalculateAndCombine() {
    double salesDebt = 0.0;
    for (var sale in _sales) {
      salesDebt += (sale.total - sale.paidAmount);
    }

    double manualDebt = 0.0;
    for (var debt in _debts) {
      manualDebt += debt.amount;
    }

    double generalPayments = 0.0;
    for (var pay in _payments) {
      if (pay.type != 'sale_payment') {
        generalPayments += pay.amount;
      }
    }

    final double realBalance = (salesDebt + manualDebt - generalPayments);

    List<dynamic> allTx = [];
    for (var sale in _sales) {
      allTx.add(sale);
    }
    for (var payment in _payments) {
      if (payment.type != 'sale_payment') {
        allTx.add(payment);
      }
    }
    for (var manualDebt in _debts) {
      allTx.add(manualDebt);
    }

    allTx.sort((a, b) {
      DateTime dateA = a is Sale ? a.date : (a is Payment ? a.date : (a as ManualDebt).date);
      DateTime dateB = b is Sale ? b.date : (b is Payment ? b.date : (b as ManualDebt).date);
      return dateB.compareTo(dateA);
    });

    if (mounted) {
      setState(() {
        _calculatedDebt = realBalance;
        _transactions = allTx;
        _isLoading = false;
      });
    }
  }

  void _showAddDebtDialog() {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController(text: "Saldo anterior");
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              title: const Text("Añadir Deuda Antigua", style: TextStyle(color: AppTheme.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Monto de la Deuda (\$)", prefixIcon: Icon(Icons.attach_money)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: "Descripción", prefixIcon: Icon(Icons.description)),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text("Fecha de la Deuda"),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                    trailing: const Icon(Icons.calendar_today, color: AppTheme.primaryYellow),
                    onTap: () async {
                      final dt = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (dt != null) setDialogState(() => selectedDate = dt);
                    },
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context), 
                  child: const Text("CANCELAR", style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    final double amount = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
                    if (amount > 0) {
                      setDialogState(() => isSaving = true);
                      try {
                        await ClientsActionsV2().addManualDebt(
                          clientId: widget.client.id,
                          amount: amount,
                          date: selectedDate,
                          description: descCtrl.text,
                        );
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                      }
                    }
                  },
                  child: isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text("GUARDAR DEUDA"),
                )
              ],
            );
          }
        );
      }
    );
  }

  void _showAddPaymentDialog() {
    final amountCtrl = TextEditingController();
    final cashCtrl = TextEditingController(text: '0');
    final transferCtrl = TextEditingController(text: '0');
    DateTime selectedDate = DateTime.now();
    String method = 'Efectivo';
    bool printReceipt = false;

    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            void updateMixtoTotal() {
              double cash = double.tryParse(cashCtrl.text) ?? 0;
              double transfer = double.tryParse(transferCtrl.text) ?? 0;
              amountCtrl.text = (cash + transfer).toStringAsFixed(0);
            }

            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              title: const Text("Registrar Pago de Cliente", style: TextStyle(color: AppTheme.textPrimary)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (method != 'Mixto') ...[
                      TextField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Monto Entregado (\$)", prefixIcon: Icon(Icons.attach_money)),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: cashCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: "Efectivo (\$)", prefixIcon: Icon(Icons.money)),
                              onChanged: (_) {
                                setDialogState(() => updateMixtoTotal());
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: transferCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: "Transferencia (\$)", prefixIcon: Icon(Icons.account_balance)),
                              onChanged: (_) {
                                setDialogState(() => updateMixtoTotal());
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text("Total Pago Mixto: \$${amountCtrl.text}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent, fontSize: 16)),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Efectivo', style: TextStyle(fontSize: 11)),
                            value: 'Efectivo',
                            groupValue: method,
                            onChanged: (val) => setDialogState(() {
                              method = val!;
                              amountCtrl.clear();
                            }),
                            activeColor: AppTheme.primaryYellow,
                            contentPadding: EdgeInsets.zero,
                          )
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Transf.', style: TextStyle(fontSize: 11)),
                            value: 'Transferencia',
                            groupValue: method,
                            onChanged: (val) => setDialogState(() {
                              method = val!;
                              amountCtrl.clear();
                            }),
                            activeColor: AppTheme.primaryYellow,
                            contentPadding: EdgeInsets.zero,
                          )
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Mixto', style: TextStyle(fontSize: 11)),
                            value: 'Mixto',
                            groupValue: method,
                            onChanged: (val) => setDialogState(() {
                              method = val!;
                              cashCtrl.text = _calculatedDebt > 0 ? _calculatedDebt.toStringAsFixed(0) : '0';
                              transferCtrl.text = '0';
                              updateMixtoTotal();
                            }),
                            activeColor: AppTheme.primaryYellow,
                            contentPadding: EdgeInsets.zero,
                          )
                        ),
                      ]
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Imprimir Recibo"),
                        Switch(
                          value: printReceipt,
                          onChanged: (v) => setDialogState(() => printReceipt = v),
                          activeColor: AppTheme.primaryYellow,
                        )
                      ]
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text("Fecha del Pago"),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                      trailing: const Icon(Icons.calendar_today, color: AppTheme.primaryYellow),
                      onTap: () async {
                        final dt = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (dt != null) setDialogState(() => selectedDate = dt);
                      },
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context), 
                  child: const Text("CANCELAR", style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    double amount = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
                    double cashAmt = 0;
                    double transferAmt = 0;
                    
                    if (method == 'Efectivo') {
                      cashAmt = amount;
                    } else if (method == 'Transferencia') {
                      transferAmt = amount;
                    } else if (method == 'Mixto') {
                      cashAmt = double.tryParse(cashCtrl.text) ?? 0;
                      transferAmt = double.tryParse(transferCtrl.text) ?? 0;
                      amount = cashAmt + transferAmt;
                    }

                    if (amount > 0) {
                      setDialogState(() => isSaving = true);
                      try {
                        final remBal = _calculatedDebt - amount;
                        await ClientsActionsV2().registerPayment(
                          clientId: widget.client.id,
                          amount: amount,
                          method: method,
                          date: selectedDate,
                          cashAmt: cashAmt,
                          transferAmt: transferAmt,
                        );

                        if (printReceipt) {
                          PrinterActions.printPaymentTicket(widget.client, amount, method, remBal);
                        }

                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                      }
                    }
                  },
                  child: isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text("REGISTRAR PAGO"),
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
    final isPhone = MediaQuery.of(context).size.width <= 500;
    final client = widget.client;
    final fmt = NumberFormat.currency(locale: 'es_ES', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text("Cuenta Corriente: ${client.name}"),
        backgroundColor: AppTheme.surfaceDark,
        actions: [
          IconButton(
            icon: Icon(_showCabinet ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppTheme.primaryYellow),
            onPressed: () {
              setState(() {
                _showCabinet = !_showCabinet;
              });
              PreferencesService().setBool('show_cc_cabinet', _showCabinet);
            },
            tooltip: "Desplegar/Ocultar Cabecera",
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: EdgeInsets.all(isPhone ? 12.0 : 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera Desplegable
                if (_showCabinet) ...[
                  Card(
                    color: AppTheme.surfaceDark,
                    child: Padding(
                      padding: EdgeInsets.all(isPhone ? 14.0 : 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(client.name, style: TextStyle(fontSize: isPhone ? 18 : 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                const SizedBox(height: 4),
                                Text("${client.city} • ${client.address}", style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                if (client.phone.isNotEmpty) Text("Tel: ${client.phone}", style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text("SALDO REAL", style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                              Text(
                                _calculatedDebt == 0 ? "\$0" : (_calculatedDebt > 0 ? fmt.format(_calculatedDebt) : "-${fmt.format(_calculatedDebt.abs())}"), 
                                style: TextStyle(
                                  fontSize: isPhone ? 20 : 28, 
                                  fontWeight: FontWeight.w900, 
                                  color: _calculatedDebt > 0 ? AppTheme.danger : (_calculatedDebt < 0 ? Colors.greenAccent : AppTheme.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Botones Principales de Acción
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          POSActions().setResellerMode(client);
                          if (Navigator.canPop(context)) {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          }
                          AppShell.globalKey.currentState?.switchTab(0);
                        },
                        icon: const Icon(Icons.shopping_cart, color: Colors.black, size: 18),
                        label: const Text("NUEVA VENTA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _showAddPaymentDialog,
                        icon: const Icon(Icons.attach_money, color: Colors.black, size: 18),
                        label: const Text("REGISTRAR PAGO", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ClientPriceListViewV2(client: client)),
                          );
                        },
                        icon: const Icon(Icons.format_list_bulleted, color: Colors.black, size: 20),
                        label: const Text("LISTA DE PRECIOS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _showAddDebtDialog,
                        icon: const Icon(Icons.history, color: AppTheme.primaryYellow, size: 18),
                        label: const Text("DEUDA ANTIGUA", style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 12)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.primaryYellow)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => ClientDetailsDialogsV2.showAdjustmentDialog(context, client, _calculatedDebt),
                        icon: const Icon(Icons.build, color: Colors.orange, size: 18),
                        label: const Text("AJUSTE MANUAL", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => PrinterActions.printAccountStatement(client, _transactions, _calculatedDebt),
                        icon: const Icon(Icons.print, color: Colors.white, size: 18),
                        label: const Text("RESUMEN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => PrinterActions.printLastBalance(client, _transactions),
                        icon: const Icon(Icons.receipt_long, color: Colors.white, size: 18),
                        label: const Text("TICKET SALDO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text("HISTORIAL DE MOVIMIENTOS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 8),

                // Lista del Historial Estilizada (Calco de OLD)
                Expanded(
                  child: _transactions.isEmpty
                    ? const Center(child: Text("No hay movimientos registrados."))
                    : ListView.builder(
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final item = _transactions[index];

                          if (item is Sale) {
                            final double debt = item.total - item.paidAmount;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                onTap: () => ClientDetailsDialogsV2.showSaleDetailsDialog(context, item, client),
                                leading: const CircleAvatar(
                                  backgroundColor: AppTheme.primaryYellow,
                                  child: Icon(Icons.shopping_cart, color: Colors.black),
                                ),
                                title: const Text("Venta de Mercadería", style: TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("${DateFormat('dd/MM/yyyy HH:mm').format(item.date)}\nTotal: \$${item.total.toStringAsFixed(0)} | Pagó: \$${item.paidAmount.toStringAsFixed(0)}"),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text("Deuda sumada", style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                    Text("+\$${debt.toStringAsFixed(0)}", style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 18)),
                                  ],
                                ),
                              ),
                            );
                          } else if (item is Payment) {
                            final isAdj = item.isAdjustment == true || item.type == 'adjustment';
                            Color pColor = isAdj ? Colors.orange : (item.method == 'Transferencia' ? Colors.lightBlueAccent : Colors.greenAccent);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: isAdj ? Colors.orange.withOpacity(0.1) : null,
                              child: ListTile(
                                onTap: () => ClientDetailsDialogsV2.showPaymentDetailsDialog(context, item, client),
                                leading: CircleAvatar(
                                  backgroundColor: pColor,
                                  child: Icon(isAdj ? Icons.build : Icons.attach_money, color: Colors.black),
                                ),
                                title: Text(
                                  isAdj ? "AJUSTE MANUAL (A favor)" : "Pago (${item.method})", 
                                  style: TextStyle(fontWeight: FontWeight.bold, color: isAdj ? Colors.orange : AppTheme.textPrimary)
                                ),
                                subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(item.date)),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text("Deuda restada", style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                    Text("-\$${item.amount.toStringAsFixed(0)}", style: TextStyle(color: pColor, fontWeight: FontWeight.bold, fontSize: 18)),
                                  ],
                                ),
                              ),
                            );
                          } else if (item is ManualDebt) {
                            final isAdj = item.isAdjustment == true;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: isAdj ? Colors.orange.withOpacity(0.1) : null,
                              child: ListTile(
                                onTap: () => ClientDetailsDialogsV2.showDebtDetailsDialog(context, item, client),
                                leading: CircleAvatar(
                                  backgroundColor: isAdj ? Colors.orange : AppTheme.danger,
                                  child: Icon(isAdj ? Icons.build : Icons.history, color: Colors.black),
                                ),
                                title: Text(
                                  isAdj ? "AJUSTE MANUAL (En contra)" : item.description, 
                                  style: TextStyle(fontWeight: FontWeight.bold, color: isAdj ? Colors.orange : AppTheme.textPrimary)
                                ),
                                subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(item.date)),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text("Deuda sumada", style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                    Text("+\$${item.amount.toStringAsFixed(0)}", style: TextStyle(color: isAdj ? Colors.orange : AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 18)),
                                  ],
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                ),
              ],
            ),
          ),
    );
  }
}
