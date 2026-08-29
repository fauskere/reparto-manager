import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../models/sale.dart';
import '../clients/v2/clients_actions_v2.dart';
import '../clients/client.dart';
import '../../core/tenant_db.dart';

class ReportsActions extends ChangeNotifier {
  static final ReportsActions _instance = ReportsActions._internal();
  factory ReportsActions() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Sale> _sales = [];
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _payments = [];
  
  String _selectedPeriod = 'Día'; // 'Día', 'Semana', 'Mes', 'Historial'
  DateTime _currentReferenceDate = DateTime.now();
  String? _selectedCity;
  
  bool _isLoadingMore = false;
  bool _hasMore = true;
  double _totalSales = 0;
  double _totalCash = 0;
  double _totalTransfer = 0;
  double _totalPending = 0;

  List<Sale> get sales => _sales;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get payments => _payments;
  String get selectedPeriod => _selectedPeriod;
  DateTime get currentReferenceDate => _currentReferenceDate;
  String? get selectedCity => _selectedCity;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  double get totalSales => _totalSales;
  double get totalCash => _totalCash;
  double get totalTransfer => _totalTransfer;
  double get totalPending => _totalPending;

  ReportsActions._internal() {
    _fetchSales();
  }

  void setPeriod(String period) {
    _selectedPeriod = period;
    notifyListeners();
    _fetchSales();
  }

  void setReferenceDate(DateTime date) {
    _currentReferenceDate = date;
    notifyListeners();
    _fetchSales();
  }

  void nextPeriod() {
    if (_selectedPeriod == 'Día') {
      _currentReferenceDate = _currentReferenceDate.add(const Duration(days: 1));
    } else if (_selectedPeriod == 'Semana') {
      _currentReferenceDate = _currentReferenceDate.add(const Duration(days: 7));
    } else if (_selectedPeriod == 'Mes') {
      _currentReferenceDate = DateTime(_currentReferenceDate.year, _currentReferenceDate.month + 1, _currentReferenceDate.day);
    }
    notifyListeners();
    _fetchSales();
  }

  void previousPeriod() {
    if (_selectedPeriod == 'Día') {
      _currentReferenceDate = _currentReferenceDate.subtract(const Duration(days: 1));
    } else if (_selectedPeriod == 'Semana') {
      _currentReferenceDate = _currentReferenceDate.subtract(const Duration(days: 7));
    } else if (_selectedPeriod == 'Mes') {
      _currentReferenceDate = DateTime(_currentReferenceDate.year, _currentReferenceDate.month - 1, _currentReferenceDate.day);
    }
    notifyListeners();
    _fetchSales();
  }

  void setCity(String? city) {
    if (city == 'Todas' || city == 'Todas las ciudades' || city == null) {
      _selectedCity = null;
    } else {
      _selectedCity = city;
    }
    notifyListeners();
    _fetchSales();
  }

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query = TenantDB.collection('sales');
    
    DateTime ref = _currentReferenceDate;

    if (_selectedPeriod == 'Día') {
      DateTime start = DateTime(ref.year, ref.month, ref.day);
      DateTime end = start.add(const Duration(days: 1));
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
                   .where('date', isLessThan: Timestamp.fromDate(end));
    } else if (_selectedPeriod == 'Semana') {
      int weekday = ref.weekday; // 1 = Monday
      DateTime startOfWeek = DateTime(ref.year, ref.month, ref.day).subtract(Duration(days: weekday - 1));
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
                   .where('date', isLessThan: Timestamp.fromDate(endOfWeek));
    } else if (_selectedPeriod == 'Mes') {
      DateTime startOfMonth = DateTime(ref.year, ref.month, 1);
      DateTime endOfMonth = DateTime(ref.year, ref.month + 1, 1);
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
                   .where('date', isLessThan: Timestamp.fromDate(endOfMonth));
    }

    if (_selectedCity != null) {
      query = query.where('city', isEqualTo: _selectedCity);
    }

    query = query.orderBy('date', descending: true);
    return query;
  }

  Query<Map<String, dynamic>> buildPaymentsQuery() {
    Query<Map<String, dynamic>> payQuery = TenantDB.collection('payments');
    
    DateTime ref = _currentReferenceDate;

    if (_selectedPeriod == 'Día') {
      DateTime start = DateTime(ref.year, ref.month, ref.day);
      DateTime end = start.add(const Duration(days: 1));
      payQuery = payQuery.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
                         .where('date', isLessThan: Timestamp.fromDate(end));
    } else if (_selectedPeriod == 'Semana') {
      int weekday = ref.weekday;
      DateTime startOfWeek = DateTime(ref.year, ref.month, ref.day).subtract(Duration(days: weekday - 1));
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));
      payQuery = payQuery.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
                         .where('date', isLessThan: Timestamp.fromDate(endOfWeek));
    } else if (_selectedPeriod == 'Mes') {
      DateTime startOfMonth = DateTime(ref.year, ref.month, 1);
      DateTime endOfMonth = DateTime(ref.year, ref.month + 1, 1);
      payQuery = payQuery.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
                         .where('date', isLessThan: Timestamp.fromDate(endOfMonth));
    }

    if (_selectedCity != null) {
      payQuery = payQuery.where('clientCity', isEqualTo: _selectedCity);
    }
    
    return payQuery;
  }

  StreamSubscription<QuerySnapshot>? _salesSubscription;
  StreamSubscription<QuerySnapshot>? _paymentsSubscription;
  int _currentLimit = 150;

  Future<void> _fetchSales() async {
    _currentLimit = 150;
    _hasMore = true;
    _setupListeners();
  }

  void _setupListeners() {
    _salesSubscription?.cancel();
    _paymentsSubscription?.cancel();
    
    final query = _buildQuery();
    Query<Map<String, dynamic>> listenQuery = query;

    if (_selectedPeriod == 'Historial') {
      listenQuery = query.limit(_currentLimit);
    }
    
    _salesSubscription = listenQuery.snapshots().listen((snapshot) {
      _sales.clear();
      for (var doc in snapshot.docs) {
        try {
          _sales.add(Sale.fromMap(doc.id, doc.data()));
        } catch (e) {
          print("Error parseando venta ${doc.id}: $e");
        }
      }
      
      _hasMore = _selectedPeriod == 'Historial' ? snapshot.docs.length >= _currentLimit : false;
      _calculateFinalTotals();
    });

    _paymentsSubscription = buildPaymentsQuery().snapshots().listen((snapshot) {
      _payments.clear();
      _payments.addAll(snapshot.docs);
      _calculateFinalTotals();
    });
  }

  void _calculateFinalTotals() {
    try {
      double tSales = 0, tCash = 0, tTrans = 0, tPend = 0;
      for (var sale in _sales) {
        double total = sale.total;
        double paid = sale.paidAmount;
        String method = sale.paymentMethod;
        
        tSales += total;
        if (method == 'Efectivo') {
          tCash += paid;
        } else if (method == 'Transferencia') {
          tTrans += paid;
        } else if (method == 'Mixto') {
          tCash += (sale.cashAmount ?? 0.0);
          tTrans += (sale.transferAmount ?? 0.0);
        }

        if (method == 'Pendiente') {
          tPend += total;
        } else if (paid < total) {
          tPend += (total - paid);
        }
      }

      for (var doc in _payments) {
        final data = doc.data();
        double amount = (data['amount'] ?? 0).toDouble();
        String method = data['method'] ?? 'Efectivo';
        
        // Acumular los pagos sin aplicar deduplicación vieja
        if (data['isAdjustment'] == true || data['type'] == 'adjustment') continue;
        
        if (amount > 0) {
          if (method == 'Efectivo') {
            tCash += amount;
          } else if (method == 'Transferencia') {
            tTrans += amount;
          } else if (method == 'Mixto') {
            tCash += (data['cashAmount'] ?? 0.0).toDouble();
            tTrans += (data['transferAmount'] ?? 0.0).toDouble();
          }
        }
      }
      
      _totalSales = tSales;
      _totalCash = tCash;
      _totalTransfer = tTrans;
      _totalPending = tPend;
      notifyListeners();
    } catch (e) {
      print("Error calculating payments totals: $e");
    }
  }

  Future<void> loadMoreSales() async {
    if (_isLoadingMore || !_hasMore) return;
    
    _isLoadingMore = true;
    notifyListeners();

    _currentLimit += 100;
    _setupListeners();
    
    _isLoadingMore = false;
  }

  Future<void> collectSale(Sale sale, double amount, String method, {double? cashAmount, double? transferAmount}) async {
    try {
      final batch = _firestore.batch();
      final newPaidAmount = sale.paidAmount + amount;
      double finalCash = (sale.cashAmount ?? 0.0) + (method == 'Efectivo' ? amount : (cashAmount ?? 0.0));
      double finalTransfer = (sale.transferAmount ?? 0.0) + (method == 'Transferencia' ? amount : (transferAmount ?? 0.0));
      double clientNewBalance = sale.total - newPaidAmount; // Default to ticket remaining if no client
        
        if (sale.clientId != null) {
          // 1. Incrementar balance en cliente (restamos la deuda pagada)
          final clientRef = _firestore.collection('clients').doc(sale.clientId);
          batch.update(clientRef, {
            'balance': FieldValue.increment(-amount)
          });
          
          final client = ClientsActionsV2().allClients.firstWhere(
            (c) => c.id == sale.clientId, 
            orElse: () => Client(id: '', name: '', phone: '', city: '', address: '')
          );
          if (client.id.isNotEmpty) {
            clientNewBalance = client.balance - amount;
          }
        }

        // 2. Actualizar la venta
        String newPaymentMethod = sale.paymentMethod;
        if (newPaidAmount >= sale.total) {
          newPaymentMethod = method;
        } else {
          newPaymentMethod = 'Mixto';
        }

        final saleRef = _firestore.collection('sales').doc(sale.id);
        batch.update(saleRef, {
          'paidAmount': newPaidAmount,
          'paymentMethod': newPaymentMethod,
          'cashAmount': finalCash > 0 ? finalCash : null,
          'transferAmount': finalTransfer > 0 ? finalTransfer : null,
          'remainingBalance': clientNewBalance,
        });

        // 3. Crear pago en colección de pagos general
        final paymentRef = _firestore.collection('payments').doc();
        batch.set(paymentRef, {
          'clientId': sale.clientId,
          'clientName': sale.clientName,
          'amount': amount,
          'method': method,
          'cashAmount': finalCash > 0 ? finalCash : null,
          'transferAmount': finalTransfer > 0 ? finalTransfer : null,
          'type': 'sale_payment',
          'details': 'Cobro Ticket',
          'date': Timestamp.now(),
          'remainingBalance': clientNewBalance,
          'saleId': sale.id,
        });

      batch.commit().catchError((e) => print("Firestore offline batch error in collectSale: $e"));

    } catch (e) {
      print("Error collecting sale: $e");
      rethrow;
    }
  }

  Future<void> changePaymentMethod(Sale sale, String newMethod) async {
    try {
      if (sale.paymentMethod == newMethod || newMethod == 'Mixto') return; // Mixto no se puede setear directo as
      
      final batch = _firestore.batch();
      double oldPaidAmount = sale.paidAmount;
      double newPaidAmount = newMethod == 'Pendiente' ? 0.0 : sale.total;
      
      if (sale.clientId != null) {
        // Si estaba pago (paid > 0) y ahora es pendiente, la deuda sube (incrementamos).
        // Si era pendiente (paid = 0) y ahora es pago, la deuda baja (decrementamos).
        double debtDiff = oldPaidAmount - newPaidAmount; 
        if (debtDiff != 0) {
          final clientRef = _firestore.collection('clients').doc(sale.clientId);
          batch.update(clientRef, {
            'balance': FieldValue.increment(debtDiff)
          });
        }
      }
      
      final saleRef = _firestore.collection('sales').doc(sale.id);
      batch.update(saleRef, {
        'paidAmount': newPaidAmount,
        'paymentMethod': newMethod,
        'cashAmount': newMethod == 'Efectivo' ? sale.total : null,
        'transferAmount': newMethod == 'Transferencia' ? sale.total : null,
        'remainingBalance': sale.total - newPaidAmount,
      });
      
      await batch.commit();
    } catch (e) {
      print("Error changing payment method: $e");
      rethrow;
    }
  }

  final Set<String> _processingDeletions = {};

  void deleteSale(String id, {String? clientId, double total = 0, double paidAmount = 0}) async {
    if (_processingDeletions.contains(id)) return;
    _processingDeletions.add(id);

    // Optimistic UI update to prevent multiple clicks when offline
    _sales.removeWhere((s) => s.id == id);
    _calculateFinalTotals();
    notifyListeners();

    try {
      final batch = _firestore.batch();
      double debt = total - paidAmount;
      if (clientId != null && debt != 0) {
        batch.update(_firestore.collection('clients').doc(clientId), {
          'balance': FieldValue.increment(-debt)
        });
      }
      batch.delete(_firestore.collection('sales').doc(id));
      
      final paymentsQuery = await _firestore.collection('payments').where('saleId', isEqualTo: id).get();
      for (var p in paymentsQuery.docs) {
        batch.delete(p.reference);
      }
      
      await batch.commit();
    } catch (e) {
      print("Error deleting sale: $e");
    } finally {
      _processingDeletions.remove(id);
    }
  }
  
  Future<void> updatePaymentDate(String paymentId, DateTime newDate) async {
    try {
      final Timestamp timestamp = Timestamp.fromDate(newDate);
      await _firestore.collection('payments').doc(paymentId).update({
        'date': timestamp
      });
    } catch (e) {
      print("Error updating payment date: $e");
    }
  }

  @override
  void dispose() {
    _salesSubscription?.cancel();
    _paymentsSubscription?.cancel();
    super.dispose();
  }
}
