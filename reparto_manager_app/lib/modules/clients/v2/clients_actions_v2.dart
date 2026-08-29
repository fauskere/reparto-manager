import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/tenant_db.dart';
import 'package:flutter/foundation.dart';
import '../client.dart';
import '../../../models/sale.dart';
import '../../../models/payment.dart';
import '../../../models/manual_debt.dart';

class ClientsActionsV2 extends ChangeNotifier {
  static final ClientsActionsV2 _instance = ClientsActionsV2._internal();
  factory ClientsActionsV2() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Client> _allClients = [];
  Map<String, double> _calculatedBalances = {};
  String? _selectedFilterCity;

  StreamSubscription<QuerySnapshot>? _clientsSub;
  StreamSubscription<QuerySnapshot>? _salesSub;
  StreamSubscription<QuerySnapshot>? _paymentsSub;
  StreamSubscription<QuerySnapshot>? _debtsSub;

  List<Sale> _allSales = [];
  List<Payment> _allPayments = [];
  List<ManualDebt> _allDebts = [];

  List<Client> get allClients {
    return _allClients.map((c) {
      final calcB = getCalculatedBalance(c.id);
      return Client(
        id: c.id,
        name: c.name,
        phone: c.phone,
        city: c.city,
        address: c.address,
        balance: calcB,
        customPrices: c.customPrices,
        type: c.type,
        hidden: c.hidden,
        nickname: c.nickname,
        isOpenContinuous: c.isOpenContinuous,
        lastVisitDate: c.lastVisitDate,
        lastVisitStatus: c.lastVisitStatus,
      );
    }).toList();
  }

  List<String> get cities {
    final setCities = _allClients.where((c) => !c.hidden && c.city.isNotEmpty).map((c) => c.city).toSet().toList();
    setCities.sort((a, b) => a.compareTo(b));
    return setCities;
  }
  void updateLocalBalance(String clientId, double delta) {
    notifyListeners();
  }
  String? get selectedFilterCity => _selectedFilterCity;

  ClientsActionsV2._internal() {
    _initGlobalListeners();
  }

  void _initGlobalListeners() {
    _clientsSub?.cancel();
    _salesSub?.cancel();
    _paymentsSub?.cancel();
    _debtsSub?.cancel();

    _clientsSub = TenantDB.collection('clients').snapshots().listen((snap) {
      _allClients = snap.docs.map((doc) => Client.fromMap(doc.data(), doc.id)).toList();
      _computeGlobalMath();
    });

    _salesSub = TenantDB.collection('sales').snapshots().listen((snap) {
      _allSales = snap.docs.map((doc) => Sale.fromMap(doc.id, doc.data())).toList();
      _computeGlobalMath();
    });

    _paymentsSub = TenantDB.collection('payments').snapshots().listen((snap) {
      _allPayments = snap.docs.map((doc) => Payment.fromMap(doc.id, doc.data())).toList();
      _computeGlobalMath();
    });

    _debtsSub = TenantDB.collection('manual_debts').snapshots().listen((snap) {
      _allDebts = snap.docs.map((doc) => ManualDebt.fromMap(doc.id, doc.data())).toList();
      _computeGlobalMath();
    });
  }

  void _computeGlobalMath() {
    final Map<String, double> salesDebtMap = {};
    for (var s in _allSales) {
      if (s.clientId != null && s.clientId!.isNotEmpty) {
        final cid = s.clientId!;
        salesDebtMap[cid] = (salesDebtMap[cid] ?? 0.0) + (s.total - s.paidAmount);
      }
    }

    final Map<String, double> manualDebtMap = {};
    for (var d in _allDebts) {
      manualDebtMap[d.clientId] = (manualDebtMap[d.clientId] ?? 0.0) + d.amount;
    }

    final Map<String, double> generalPaymentsMap = {};
    for (var p in _allPayments) {
      if (p.type != 'sale_payment') {
        generalPaymentsMap[p.clientId] = (generalPaymentsMap[p.clientId] ?? 0.0) + p.amount;
      }
    }

    final Map<String, double> newBalances = {};
    for (var c in _allClients) {
      final sDebt = salesDebtMap[c.id] ?? 0.0;
      final mDebt = manualDebtMap[c.id] ?? 0.0;
      final gPay = generalPaymentsMap[c.id] ?? 0.0;
      newBalances[c.id] = (sDebt + mDebt - gPay);
    }

    _calculatedBalances = newBalances;
    notifyListeners();
  }

  /// Obtiene el saldo real instantáneo (0ms) de cualquier cliente
  double getCalculatedBalance(String clientId) {
    return _calculatedBalances[clientId] ?? 0.0;
  }

  /// Añadir cliente
  Future<Client> addClient(
    String name,
    String phone,
    String city,
    String address, {
    String nickname = '',
    bool isOpenContinuous = false,
  }) async {
    final newDoc = TenantDB.collection('clients').doc();
    final client = Client(
      id: newDoc.id,
      name: name.trim(),
      phone: phone.trim(),
      city: city.trim(),
      address: address.trim(),
      nickname: nickname.trim(),
      isOpenContinuous: isOpenContinuous,
    );
    await newDoc.set(client.toMap());
    notifyListeners();
    return client;
  }

  /// Añadir Ajuste Manual A Favor (tipo pago, registrado con isAdjustment: true)
  Future<void> addAdjustmentPayment({
    required String clientId,
    required double amount,
    required DateTime date,
    required String note,
  }) async {
    if (amount <= 0) return;
    try {
      final batch = _firestore.batch();
      final paymentRef = TenantDB.collection('payments').doc();
      final clientRef = TenantDB.collection('clients').doc(clientId);

      batch.set(paymentRef, {
        'id': paymentRef.id,
        'clientId': clientId,
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'type': 'adjustment',
        'method': 'Ajuste',
        'isAdjustment': true,
        'note': note.isEmpty ? "Ajuste manual a favor" : note,
      });

      batch.update(clientRef, {'balance': FieldValue.increment(-amount)});
      await batch.commit();
      notifyListeners();
    } catch (e) {
      debugPrint("Error añadiendo ajuste a favor: $e");
      rethrow;
    }
  }

  /// Añadir Ajuste Manual En Contra (tipo deuda, registrado con isAdjustment: true)
  Future<void> addAdjustmentDebt({
    required String clientId,
    required double amount,
    required DateTime date,
    required String note,
  }) async {
    if (amount <= 0) return;
    try {
      final batch = _firestore.batch();
      final debtRef = TenantDB.collection('manual_debts').doc();
      final clientRef = TenantDB.collection('clients').doc(clientId);

      batch.set(debtRef, {
        'id': debtRef.id,
        'clientId': clientId,
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'description': 'AJUSTE MANUAL (En contra)',
        'isAdjustment': true,
        'note': note.isEmpty ? "Ajuste manual en contra" : note,
      });

      batch.update(clientRef, {'balance': FieldValue.increment(amount)});
      await batch.commit();
      notifyListeners();
    } catch (e) {
      debugPrint("Error añadiendo ajuste en contra: $e");
      rethrow;
    }
  }

  /// Añadir deuda manual con await obligatorio
  Future<void> addManualDebt({
    required String clientId,
    required double amount,
    required DateTime date,
    required String description,
  }) async {
    if (amount <= 0) return;
    try {
      final batch = _firestore.batch();
      final debtRef = TenantDB.collection('manual_debts').doc();
      final clientRef = TenantDB.collection('clients').doc(clientId);

      final debt = ManualDebt(
        id: debtRef.id,
        clientId: clientId,
        amount: amount,
        date: date,
        description: description.isEmpty ? "Deuda Manual" : description,
      );

      batch.set(debtRef, debt.toMap());
      batch.update(clientRef, {'balance': FieldValue.increment(amount)});

      await batch.commit().timeout(const Duration(seconds: 2), onTimeout: () {
        debugPrint("Commit de deuda manual procesado offline.");
      });
      notifyListeners();
    } catch (e) {
      debugPrint("Error al añadir deuda manual v2: $e");
      rethrow;
    }
  }

  /// Cobrar ticket con await obligatorio y transacción segura
  Future<void> collectTicketSale({
    required Sale sale,
    required double amount,
    required String method,
    double? cashAmount,
    double? transferAmount,
    DateTime? date,
  }) async {
    if (amount <= 0) return;
    try {
      final batch = _firestore.batch();
      final newPaidAmount = sale.paidAmount + amount;
      double finalCash = (sale.cashAmount ?? 0.0) + (method == 'Efectivo' ? amount : (cashAmount ?? 0.0));
      double finalTransfer = (sale.transferAmount ?? 0.0) + (method == 'Transferencia' ? amount : (transferAmount ?? 0.0));

      if (sale.clientId != null && sale.clientId!.isNotEmpty) {
        final clientRef = TenantDB.collection('clients').doc(sale.clientId);
        batch.update(clientRef, {'balance': FieldValue.increment(-amount)});
      }

      String newPaymentMethod = sale.paymentMethod;
      if (newPaidAmount >= sale.total) {
        newPaymentMethod = method;
      } else {
        newPaymentMethod = 'Mixto';
      }

      final saleRef = TenantDB.collection('sales').doc(sale.id);
      batch.update(saleRef, {
        'paidAmount': newPaidAmount,
        'paymentMethod': newPaymentMethod,
        'cashAmount': finalCash > 0 ? finalCash : null,
        'transferAmount': finalTransfer > 0 ? finalTransfer : null,
      });

      final paymentRef = TenantDB.collection('payments').doc();
      batch.set(paymentRef, {
        'id': paymentRef.id,
        'clientId': sale.clientId,
        'clientName': sale.clientName,
        'amount': amount,
        'method': method,
        'cashAmount': finalCash > 0 ? finalCash : null,
        'transferAmount': finalTransfer > 0 ? finalTransfer : null,
        'type': 'sale_payment',
        'details': 'Cobro Ticket',
        'date': date != null ? Timestamp.fromDate(date) : Timestamp.now(),
        'saleId': sale.id,
      });

      await batch.commit().timeout(const Duration(seconds: 2), onTimeout: () {
        debugPrint("Commit de cobro ticket procesado offline.");
      });
      notifyListeners();
    } catch (e) {
      debugPrint("Error cobrando ticket v2: $e");
      rethrow;
    }
  }

  /// Eliminar cliente
  Future<void> deleteClient(String id) async {
    await TenantDB.collection('clients').doc(id).delete();
    notifyListeners();
  }

  /// Eliminar deuda manual con await obligatorio
  Future<void> deleteManualDebt(String debtId, String clientId, double amount) async {
    final batch = _firestore.batch();
    final debtRef = TenantDB.collection('manual_debts').doc(debtId);
    final clientRef = TenantDB.collection('clients').doc(clientId);

    batch.delete(debtRef);
    batch.update(clientRef, {'balance': FieldValue.increment(-amount)});
    await batch.commit();
    notifyListeners();
  }

  /// Eliminar pago con await obligatorio
  Future<void> deletePayment(String paymentId, String clientId, double amount) async {
    final batch = _firestore.batch();
    final paymentRef = TenantDB.collection('payments').doc(paymentId);
    final clientRef = TenantDB.collection('clients').doc(clientId);

    batch.delete(paymentRef);
    batch.update(clientRef, {'balance': FieldValue.increment(amount)});
    await batch.commit();
    notifyListeners();
  }

  /// Eliminar venta
  Future<void> deleteSale(String saleId) async {
    await TenantDB.collection('sales').doc(saleId).delete();
    notifyListeners();
  }

  /// Marcar visita de cliente
  Future<void> markVisit(String id, String status) async {
    final today = DateTime.now().toString().substring(0, 10);
    await TenantDB.collection('clients').doc(id).update({
      'lastVisitDate': status.isEmpty ? '' : today,
      'lastVisitStatus': status,
    });
    notifyListeners();
  }

  /// Registrar Pago general en Cuenta Corriente con await obligatorio
  Future<void> registerPayment({
    required String clientId,
    required double amount,
    required String method,
    required DateTime date,
    double cashAmt = 0,
    double transferAmt = 0,
  }) async {
    if (amount <= 0) return;
    try {
      final batch = _firestore.batch();
      final paymentRef = TenantDB.collection('payments').doc();
      final clientRef = TenantDB.collection('clients').doc(clientId);

      final payment = Payment(
        id: paymentRef.id,
        clientId: clientId,
        amount: amount,
        date: date,
        method: method,
        cashAmount: cashAmt,
        transferAmount: transferAmt,
      );

      final pMap = payment.toMap();
      pMap['id'] = paymentRef.id;

      batch.set(paymentRef, pMap);
      batch.update(clientRef, {'balance': FieldValue.increment(-amount)});

      await batch.commit().timeout(const Duration(seconds: 2), onTimeout: () {
        debugPrint("Commit de pago procesado offline/localmente.");
      });
      notifyListeners();
    } catch (e) {
      debugPrint("Error registrando pago v2: $e");
      rethrow;
    }
  }

  void setFilterCity(String? city) {
    _selectedFilterCity = (city == 'Todas' || city == 'Todas las ciudades') ? null : city;
    notifyListeners();
  }

  /// Cambiar horario continuo
  Future<void> toggleOpenContinuous(String id, bool currentValue) async {
    await TenantDB.collection('clients').doc(id).update({
      'isOpenContinuous': !currentValue,
    });
    notifyListeners();
  }

  /// Editar cliente
  Future<void> updateClient(
    String id,
    String name,
    String phone,
    String city,
    String address, {
    String nickname = '',
    bool isOpenContinuous = false,
  }) async {
    final Map<String, dynamic> updateData = {
      'name': name.trim(),
      'phone': phone.trim(),
      'city': city.trim(),
      'address': address.trim(),
      'nickname': nickname.trim(),
      'isOpenContinuous': isOpenContinuous,
    };
    await TenantDB.collection('clients').doc(id).update(updateData);
    notifyListeners();
  }

  /// Copiar mapa de precios personalizados desde un cliente origen hacia clientes destino
  Future<void> copyPricesToClients(String sourceClientId, List<String> targetClientIds) async {
    if (targetClientIds.isEmpty) return;
    final sourceClient = _allClients.firstWhere((c) => c.id == sourceClientId);
    final Map<String, dynamic> pricesToCopy = Map<String, dynamic>.from(sourceClient.customPrices);

    final batch = _firestore.batch();
    for (var targetId in targetClientIds) {
      final ref = TenantDB.collection('clients').doc(targetId);
      batch.update(ref, {'customPrices': pricesToCopy});
    }
    await batch.commit();
    notifyListeners();
  }

  @override
  void dispose() {
    _clientsSub?.cancel();
    _salesSub?.cancel();
    _paymentsSub?.cancel();
    _debtsSub?.cancel();
    super.dispose();
  }
}
