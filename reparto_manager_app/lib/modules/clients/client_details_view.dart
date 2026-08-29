import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/preferences_service.dart';
import '../../core/tenant_db.dart';
import 'client.dart';
import '../../models/sale.dart';
import '../../models/payment.dart';
import '../../models/manual_debt.dart';
import '../printer/printer_actions.dart';
import '../pos/pos_actions.dart';
import '../shell/app_shell.dart';
import 'v2/client_price_list_view_v2.dart';

import 'dart:async';

class ClientDetailsView extends StatefulWidget {
  final Client client;

  const ClientDetailsView({super.key, required this.client});

  @override
  State<ClientDetailsView> createState() => _ClientDetailsViewState();
}

class _ClientDetailsViewState extends State<ClientDetailsView> {
  bool _isLoading = true;
  double _currentDebt = 0.0;
  List<dynamic> _transactions = [];
  bool _showCabinet = true;

  StreamSubscription<QuerySnapshot>? _salesSub;
  StreamSubscription<QuerySnapshot>? _paymentsSub;
  StreamSubscription<QuerySnapshot>? _debtsSub;
  StreamSubscription<DocumentSnapshot>? _clientSub;

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
    _clientSub?.cancel();
    super.dispose();
  }

  void _listenToAccountData() {
    final clientId = widget.client.id;
    _clientSub = TenantDB.collection('clients').doc(clientId).snapshots().listen((doc) {
      if (doc.exists && mounted) {
        setState(() {
          _currentDebt = (doc.data()?['balance'] ?? 0).toDouble();
        });
      }
    });

    _salesSub = TenantDB.collection('sales').where('clientId', isEqualTo: clientId).snapshots().listen((snap) {
      _sales = snap.docs.map((doc) => Sale.fromMap(doc.id, doc.data())).toList();
      _combineAndSortTransactions();
    });

    _paymentsSub = TenantDB.collection('payments').where('clientId', isEqualTo: clientId).snapshots().listen((snap) {
      _payments = snap.docs.map((doc) => Payment.fromMap(doc.id, doc.data())).toList();
      _combineAndSortTransactions();
    });

    _debtsSub = TenantDB.collection('manual_debts').where('clientId', isEqualTo: clientId).snapshots().listen((snap) {
      _debts = snap.docs.map((doc) => ManualDebt.fromMap(doc.id, doc.data())).toList();
      _combineAndSortTransactions();
    });
  }

  void _combineAndSortTransactions() {
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
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
                ElevatedButton(
                  onPressed: () {
                    final double amount = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
                      if (amount > 0) {
                        TenantDB.collection('manual_debts').add(
                          ManualDebt(
                            id: '',
                            clientId: widget.client.id,
                            amount: amount,
                            date: selectedDate,
                            description: descCtrl.text.isEmpty ? "Deuda Manual" : descCtrl.text,
                          ).toMap(),
                        );
                        TenantDB.collection('clients').doc(widget.client.id).update({'balance': FieldValue.increment(amount)});
                        Navigator.pop(context);
                      }
                  },
                  child: const Text("GUARDAR DEUDA"),
                )
              ],
            );
          }
        );
      }
    );
  }

  void _showAddAdjustmentDialog() {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String type = 'a_favor';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              title: const Text("Ajuste Manual de Saldo", style: TextStyle(color: Colors.orange)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Usá esto SOLO para arreglar cuentas desfasadas.", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Monto del Ajuste (\$)", prefixIcon: Icon(Icons.attach_money, color: Colors.orange)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(labelText: "Razón/Nota", prefixIcon: Icon(Icons.note, color: Colors.orange)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('A favor (Resta deuda)', style: TextStyle(fontSize: 11)),
                            value: 'a_favor',
                            groupValue: type,
                            onChanged: (val) => setDialogState(() => type = val!),
                            activeColor: Colors.orange,
                            contentPadding: EdgeInsets.zero,
                          )
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('En contra (Suma deuda)', style: TextStyle(fontSize: 11)),
                            value: 'en_contra',
                            groupValue: type,
                            onChanged: (val) => setDialogState(() => type = val!),
                            activeColor: Colors.orange,
                            contentPadding: EdgeInsets.zero,
                          )
                        ),
                      ]
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text("CANCELAR")
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: isSaving ? null : () async {
                    double amount = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
                    if (amount > 0) {
                      setDialogState(() => isSaving = true);
                      final batch = FirebaseFirestore.instance.batch();
                      final clientRef = TenantDB.collection('clients').doc(widget.client.id);

                      if (type == 'a_favor') {
                        final paymentRef = TenantDB.collection('payments').doc();
                        batch.set(paymentRef, {
                          'id': paymentRef.id,
                          'clientId': widget.client.id,
                          'amount': amount,
                          'date': Timestamp.fromDate(selectedDate),
                          'method': 'Ajuste',
                          'type': 'adjustment',
                          'isAdjustment': true,
                          'note': noteCtrl.text.isEmpty ? 'Ajuste Manual' : noteCtrl.text,
                        });
                        batch.update(clientRef, {'balance': FieldValue.increment(-amount)});
                      } else {
                        final debtRef = TenantDB.collection('manual_debts').doc();
                        batch.set(debtRef, {
                          'id': debtRef.id,
                          'clientId': widget.client.id,
                          'amount': amount,
                          'date': Timestamp.fromDate(selectedDate),
                          'description': 'Ajuste Manual',
                          'isAdjustment': true,
                          'note': noteCtrl.text.isEmpty ? 'Ajuste Manual' : noteCtrl.text,
                        });
                        batch.update(clientRef, {'balance': FieldValue.increment(amount)});
                      }
                      
                      await batch.commit();
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("GUARDAR AJUSTE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    bool cashManual = false;
    bool transferManual = false;

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
                              onChanged: (v) {
                                setDialogState(() {
                                  cashManual = v.isNotEmpty && v != '0';
                                  double clientBal = widget.client.balance;
                                  if (clientBal > 0 && cashManual && !transferManual) {
                                    double cashVal = double.tryParse(v) ?? 0;
                                    double transVal = clientBal - cashVal;
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: transferCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: "Transferencia (\$)", prefixIcon: Icon(Icons.account_balance)),
                              onChanged: (v) {
                                setDialogState(() {
                                  transferManual = v.isNotEmpty && v != '0';
                                  double clientBal = widget.client.balance;
                                  if (clientBal > 0 && transferManual && !cashManual) {
                                    double transVal = double.tryParse(v) ?? 0;
                                    double cashVal = clientBal - transVal;
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
                              double clientBal = widget.client.balance;
                              if (clientBal > 0) {
                                cashCtrl.text = clientBal.toStringAsFixed(0);
                              } else {
                                cashCtrl.text = '0';
                              }
                              transferCtrl.text = '0';
                              updateMixtoTotal();
                              cashManual = false;
                              transferManual = false;
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
                  child: const Text("CANCELAR")
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
                      setDialogState(() {
                        isSaving = true;
                      });

                      try {
                        final double prevBal = _currentDebt;
                        final double remBal = prevBal - amount;
                        final DateTime finalDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
                        
                        final payment = Payment(
                          id: '',
                          clientId: widget.client.id,
                          amount: amount,
                          date: finalDate,
                          method: method,
                          cashAmount: cashAmt,
                          transferAmount: transferAmt,
                          previousBalance: prevBal,
                          remainingBalance: remBal,
                        );

                        final batch = FirebaseFirestore.instance.batch();
                        final paymentRef = TenantDB.collection('payments').doc();
                        final clientRef = TenantDB.collection('clients').doc(widget.client.id);
                        
                        final paymentMap = payment.toMap();
                        paymentMap['id'] = paymentRef.id;
                        
                        batch.set(paymentRef, paymentMap);
                        batch.update(clientRef, {'balance': FieldValue.increment(-amount)});
                        
                        await batch.commit();
                        
                        if (printReceipt) {
                          PrinterActions.printPaymentTicket(widget.client, amount, method, remBal);
                        }
                        
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        debugPrint("Error registering payment: $e");
                        if (context.mounted) {
                          setDialogState(() {
                            isSaving = false;
                          });
                        }
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

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Cuenta Corriente"),
            if (isPhone) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _showCabinet ? Icons.expand_less : Icons.expand_more,
                  color: AppTheme.primaryYellow,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _showCabinet = !_showCabinet;
                  });
                  PreferencesService().setBool('show_cc_cabinet', _showCabinet);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
        backgroundColor: AppTheme.surfaceDark,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: EdgeInsets.all(isPhone ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera Cliente
                if (!isPhone || _showCabinet) ...[
                  Card(
                    color: AppTheme.surfaceDark,
                    child: Padding(
                      padding: EdgeInsets.all(isPhone ? 16.0 : 24.0),
                      child: isPhone
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.client.name, 
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text("${widget.client.city} • ${widget.client.address}", style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("SALDO RESTANTE", style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                  Text(
                                    "\$${_currentDebt.toStringAsFixed(0)}", 
                                    style: TextStyle(
                                      fontSize: 24, 
                                      fontWeight: FontWeight.w900, 
                                      color: _currentDebt > 0 ? AppTheme.danger : Colors.greenAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.client.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                  const SizedBox(height: 8),
                                  Text("${widget.client.city} • ${widget.client.address}", style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text("SALDO RESTANTE", style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                                  Text("\$${_currentDebt.toStringAsFixed(0)}", style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: _currentDebt > 0 ? AppTheme.danger : Colors.greenAccent)),
                                ],
                              ),
                            ],
                          ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Botones de acción
                  isPhone
                    ? Column(
                        children: [
                          if (widget.client.type == 'revendedor') ...[
                            ElevatedButton.icon(
                              onPressed: () {
                                POSActions().setResellerMode(widget.client);
                                AppShell.globalKey.currentState?.switchTab(0);
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              },
                              icon: const Icon(Icons.add_shopping_cart, color: Colors.black, size: 20),
                              label: const Text("NUEVA VENTA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryYellow,
                                minimumSize: const Size.fromHeight(44),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ClientPriceListViewV2(client: widget.client)),
                              );
                            },
                            icon: const Icon(Icons.format_list_bulleted, color: Colors.black, size: 20),
                            label: const Text("LISTA DE PRECIOS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryYellow,
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: _showAddPaymentDialog,
                            icon: const Icon(Icons.attach_money, color: Colors.black, size: 20),
                            label: const Text("REGISTRAR PAGO", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _showAddDebtDialog,
                            icon: const Icon(Icons.history, color: AppTheme.primaryYellow, size: 20),
                            label: const Text("AÑADIR DEUDA ANTIGUA", style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.primaryYellow),
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _showAddAdjustmentDialog,
                            icon: const Icon(Icons.build, color: Colors.orange, size: 20),
                            label: const Text("AJUSTE DE SALDO MANUAL", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.orange),
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () {
                               PrinterActions.printAccountStatement(widget.client, _transactions, _currentDebt);
                            },
                            icon: const Icon(Icons.print, color: Colors.white, size: 20),
                            label: const Text("IMPRIMIR RESUMEN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white),
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () {
                               PrinterActions.printLastBalance(widget.client, _transactions);
                            },
                            icon: const Icon(Icons.receipt, color: Colors.white, size: 20),
                            label: const Text("IMPRIMIR SALDO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white),
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Row(
                            children: [
                              if (widget.client.type == 'revendedor') ...[
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      POSActions().setResellerMode(widget.client);
                                      AppShell.globalKey.currentState?.switchTab(0);
                                      Navigator.of(context).popUntil((route) => route.isFirst);
                                    },
                                    icon: const Icon(Icons.add_shopping_cart, color: Colors.black),
                                    label: const Text("NUEVA VENTA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryYellow,
                                      minimumSize: const Size.fromHeight(50),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                              ],
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _showAddPaymentDialog,
                                  icon: const Icon(Icons.attach_money, color: Colors.black),
                                  label: const Text("REGISTRAR PAGO", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.greenAccent,
                                    minimumSize: const Size.fromHeight(50),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => ClientPriceListViewV2(client: widget.client)),
                                    );
                                  },
                                  icon: const Icon(Icons.format_list_bulleted, color: Colors.black, size: 20),
                                  label: const Text("LISTA DE PRECIOS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryYellow,
                                    minimumSize: const Size.fromHeight(50),
                                  ),
                                ),
                              ),
                              if (widget.client.type != 'revendedor') ...[
                                const SizedBox(width: 16),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _showAddDebtDialog,
                                    icon: const Icon(Icons.history, color: AppTheme.primaryYellow),
                                    label: const Text("AÑADIR DEUDA ANTIGUA", style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppTheme.primaryYellow),
                                      minimumSize: const Size.fromHeight(50),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _showAddAdjustmentDialog,
                                    icon: const Icon(Icons.build, color: Colors.orange),
                                    label: const Text("AJUSTE MANUAL", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.orange),
                                      minimumSize: const Size.fromHeight(50),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (widget.client.type == 'revendedor') ...[
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _showAddDebtDialog,
                                    icon: const Icon(Icons.history, color: AppTheme.primaryYellow),
                                    label: const Text("AÑADIR DEUDA ANTIGUA", style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppTheme.primaryYellow),
                                      minimumSize: const Size.fromHeight(50),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                              ],
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                     PrinterActions.printAccountStatement(widget.client, _transactions, _currentDebt);
                                  },
                                  icon: const Icon(Icons.print, color: Colors.white),
                                  label: const Text("IMPRIMIR RESUMEN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.white),
                                    minimumSize: const Size.fromHeight(50),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                     PrinterActions.printLastBalance(widget.client, _transactions);
                                  },
                                  icon: const Icon(Icons.receipt, color: Colors.white),
                                  label: const Text("IMPRIMIR SALDO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.white),
                                    minimumSize: const Size.fromHeight(50),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  const SizedBox(height: 32),
                ],
                
                // Historial de Movimientos
                const Text("Historial de Movimientos", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final tx = _transactions[index];
                      
                      if (tx is Sale) {
                        return _buildSaleTile(tx);
                      } else if (tx is Payment) {
                        return _buildPaymentTile(tx);
                      } else if (tx is ManualDebt) {
                        return _buildDebtTile(tx);
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

  void _showSaleDetailsDialog(Sale sale) {
    final fmt = NumberFormat.currency(locale: 'es_ES', symbol: '\$', decimalDigits: 0);
    showDialog(
      context: context,
      builder: (context) {
        final double prev = sale.previousBalance ?? 0.0;
        final double rem = sale.remainingBalance ?? 0.0;
        final bool hasAudit = sale.previousBalance != null;

        double cash = sale.cashAmount ?? 0.0;
        double transfer = sale.transferAmount ?? 0.0;
        if (!hasAudit) {
          if (sale.paymentMethod == 'Efectivo') cash = sale.paidAmount;
          if (sale.paymentMethod == 'Transferencia') transfer = sale.paidAmount;
        }

        final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
        final maxHeightItems = isPortrait ? MediaQuery.of(context).size.height * 0.65 : 200.0;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          backgroundColor: AppTheme.backgroundDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Detalle de Venta", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primaryYellow)),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.primaryYellow),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                Text("Cliente: ${widget.client.name}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text("Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(sale.date)}", style: const TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 16),
                
                const Text("Productos Comprados:", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Container(
                  constraints: BoxConstraints(maxHeight: maxHeightItems),
                  child: SingleChildScrollView(
                    child: Column(
                      children: sale.items.map((item) {
                        final vName = item.selectedVariant?.name != null && item.selectedVariant!.name.isNotEmpty ? ' (${item.selectedVariant!.name})' : '';
                        final double itemTotal = item.unitPrice * item.quantity;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text("${item.quantity}x ${item.product.name}$vName", style: const TextStyle(fontSize: 14)),
                                  ),
                                  Text("${fmt.format(item.unitPrice)} c/u  •  ${fmt.format(itemTotal)}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            if (item.manualDiscount > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 12, bottom: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.local_offer, color: Colors.greenAccent, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Desc. manual (${((item.manualDiscount / item.unitPrice) * 100).toStringAsFixed(0)}%)",
                                          style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      "-${fmt.format(item.manualDiscount * item.quantity)}",
                                      style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                if (sale.exchanges.isNotEmpty) ...[
                  const Divider(color: Colors.white12),
                  const Text("Cambios / Devoluciones:", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  ...sale.exchanges.map((ex) {
                    final vName = ex.selectedVariant?.name != null && ex.selectedVariant!.name.isNotEmpty ? ' (${ex.selectedVariant!.name})' : '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text("- Devolvió: ${ex.quantity}x ${ex.product.name}$vName", style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
                    );
                  }).toList(),
                ],
                const Divider(color: Colors.white24),
                if (sale.discountAmount > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Bonificación:", style: TextStyle(color: Colors.greenAccent)),
                      Text("-${fmt.format(sale.discountAmount)}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("TOTAL VENTA:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(fmt.format(sale.total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primaryYellow)),
                  ],
                ),
                const SizedBox(height: 12),
                
                const Text("Detalle de Pago:", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Método de Pago: ${sale.paymentMethod}", style: const TextStyle(fontSize: 14)),
                    Text(fmt.format(sale.paidAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.greenAccent)),
                  ],
                ),
                if (sale.paymentMethod == 'Mixto') ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("• Efectivo: ${fmt.format(cash)}", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        Text("• Transferencia: ${fmt.format(transfer)}", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                
                const Text("Saldos de Cuenta Corriente:", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                if (hasAudit) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Saldo Anterior:", style: TextStyle(fontSize: 14)),
                      Text(fmt.format(prev), style: TextStyle(fontWeight: FontWeight.bold, color: prev > 0 ? AppTheme.danger : Colors.greenAccent)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Saldo Resultante:", style: TextStyle(fontSize: 14)),
                      Text(fmt.format(rem), style: TextStyle(fontWeight: FontWeight.w900, color: rem > 0 ? AppTheme.danger : Colors.greenAccent)),
                    ],
                  ),
                ] else ...[
                  const Text("Saldos no registrados en esta versión antigua.", style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          POSActions().loadOrderIntoPos(widget.client, sale.items);
                          Navigator.pop(context);
                          AppShell.globalKey.currentState?.switchTab(0);
                        },
                        icon: const Icon(Icons.shopping_cart_checkout, color: Colors.black),
                        label: const Text("CARGAR EN POS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          PrinterActions.printTicket(
                            sale.items,
                            sale.items.fold(0.0, (sum, item) => sum + item.unitPrice * item.quantity),
                            sale.discountAmount,
                            sale.appliedPromos,
                            sale.total,
                            sale.exchanges,
                            sale.paidAmount,
                            sale.paymentMethod,
                            widget.client,
                            prev,
                            false,
                            true, // showPaymentDetails = true
                          );
                        },
                        icon: const Icon(Icons.print, color: Colors.black),
                        label: const Text("REIMPRIMIR TICKET", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryYellow,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  void _showPaymentDetailsDialog(Payment payment) {
    final fmt = NumberFormat.currency(locale: 'es_ES', symbol: '\$', decimalDigits: 0);
    showDialog(
      context: context,
      builder: (context) {
        final double prev = payment.previousBalance ?? 0.0;
        final double rem = payment.remainingBalance ?? 0.0;
        final bool hasAudit = payment.previousBalance != null;

        double cash = payment.cashAmount ?? 0.0;
        double transfer = payment.transferAmount ?? 0.0;
        if (!hasAudit) {
          if (payment.method == 'Efectivo') cash = payment.amount;
          if (payment.method == 'Transferencia') transfer = payment.amount;
        }

        return Dialog(
          backgroundColor: AppTheme.backgroundDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Detalle de Pago", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.greenAccent)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.greenAccent),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                Text("Cliente: ${widget.client.name}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text("Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(payment.date)}", style: const TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 16),
                
                const Text("Detalle del Pago:", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Monto Total:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(fmt.format(payment.amount), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.greenAccent)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Método: ${payment.method}", style: const TextStyle(fontSize: 14)),
                  ],
                ),
                if (payment.method == 'Mixto') ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("• Efectivo: ${fmt.format(cash)}", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        Text("• Transferencia: ${fmt.format(transfer)}", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                
                const Text("Saldos de Cuenta Corriente:", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                if (hasAudit) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Saldo Anterior:", style: TextStyle(fontSize: 14)),
                      Text(fmt.format(prev), style: TextStyle(fontWeight: FontWeight.bold, color: prev > 0 ? AppTheme.danger : Colors.greenAccent)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Saldo Resultante:", style: TextStyle(fontSize: 14)),
                      Text(
                        rem == 0 ? "Saldado" : fmt.format(rem), 
                        style: TextStyle(
                          fontWeight: FontWeight.w900, 
                          color: rem == 0 ? Colors.greenAccent : (rem > 0 ? AppTheme.danger : Colors.greenAccent)
                        )
                      ),
                    ],
                  ),
                ] else ...[
                  const Text("Saldos no registrados en esta versión antigua.", style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Cierra detalle
                    _confirmDeletePayment(context, payment);
                  },
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text("ELIMINAR PAGO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.danger,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  void _confirmDeletePayment(BuildContext context, Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text("Eliminar Pago"),
        content: const Text("¿Estás seguro de que deseas eliminar este pago de forma permanente? El saldo pendiente del cliente se incrementará."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              final batch = FirebaseFirestore.instance.batch();
              batch.delete(TenantDB.collection('payments').doc(payment.id));
              batch.update(TenantDB.collection('clients').doc(payment.clientId), {'balance': FieldValue.increment(payment.amount)});
              await batch.commit();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Pago eliminado exitosamente."), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleTile(Sale sale) {
    double debt = sale.total - sale.paidAmount;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _showSaleDetailsDialog(sale),
        leading: const CircleAvatar(backgroundColor: AppTheme.primaryYellow, child: Icon(Icons.shopping_cart, color: Colors.black)),
        title: const Text("Venta de Mercadería", style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${DateFormat('dd/MM/yyyy HH:mm').format(sale.date)}\nTotal: \$${sale.total.toStringAsFixed(0)} | Pagó: \$${sale.paidAmount.toStringAsFixed(0)}"),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text("Deuda sumada", style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            Text("+\$${debt.toStringAsFixed(0)}", style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTile(Payment payment) {
    if (payment.isAdjustment == true) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: Colors.orange.withOpacity(0.1),
        child: ListTile(
          onTap: () => _showPaymentDetailsDialog(payment),
          leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.build, color: Colors.white)),
          title: const Text("AJUSTE MANUAL (A favor)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          subtitle: Text("${DateFormat('dd/MM/yyyy').format(payment.date)}\nNota: ${payment.note ?? ''}"),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("Deuda restada", style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
              Text("-\$${payment.amount.toStringAsFixed(0)}", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _showPaymentDetailsDialog(payment),
        leading: const CircleAvatar(backgroundColor: Colors.greenAccent, child: Icon(Icons.attach_money, color: Colors.black)),
        title: Text("Pago (${payment.method})", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(DateFormat('dd/MM/yyyy').format(payment.date)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text("Deuda restada", style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            Text("-\$${payment.amount.toStringAsFixed(0)}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtTile(ManualDebt debt) {
    if (debt.isAdjustment == true) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: Colors.orange.withOpacity(0.1),
        child: ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.build, color: Colors.white)),
          title: const Text("AJUSTE MANUAL (En contra)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          subtitle: Text("${DateFormat('dd/MM/yyyy').format(debt.date)}\nNota: ${debt.note ?? debt.description}"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Deuda sumada", style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                  Text("+\$${debt.amount.toStringAsFixed(0)}", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.orange),
                onPressed: () async {
                  final batch = FirebaseFirestore.instance.batch();
                  batch.delete(TenantDB.collection('manual_debts').doc(debt.id));
                  batch.update(TenantDB.collection('clients').doc(debt.clientId), {'balance': FieldValue.increment(-debt.amount)});
                  await batch.commit();
                },
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: AppTheme.danger, child: Icon(Icons.history, color: Colors.white)),
        title: Text(debt.description, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(DateFormat('dd/MM/yyyy').format(debt.date)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text("Deuda sumada", style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                Text("+\$${debt.amount.toStringAsFixed(0)}", style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
              onPressed: () async {
                final batch = FirebaseFirestore.instance.batch();
                batch.delete(TenantDB.collection('manual_debts').doc(debt.id));
                batch.update(TenantDB.collection('clients').doc(debt.clientId), {'balance': FieldValue.increment(-debt.amount)});
                await batch.commit();
              },
            ),
          ],
        ),
      ),
    );
  }
}

