import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/preferences_service.dart';
import '../../core/tenant_db.dart';

class TruckStock {
  final String productId;
  final String variantName;
  final int quantity;

  TruckStock({
    required this.productId,
    required this.variantName,
    required this.quantity,
  });

  factory TruckStock.fromDocument(DocumentSnapshot doc) {
    return TruckStock(
      productId: doc['productId'] ?? '',
      variantName: doc['variantName'] ?? '',
      quantity: doc['quantity'] ?? 0,
    );
  }
}

class TruckLoadActions extends ChangeNotifier {
  static final TruckLoadActions _instance = TruckLoadActions._internal();
  factory TruckLoadActions() => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _activeTruckId = 'truck_principal';
  String get activeTruckId => _activeTruckId;

  List<TruckStock> _currentStock = [];
  List<TruckStock> get currentStock => _currentStock;

  TruckLoadActions._internal() {
    _initActiveTruck();
  }

  Future<void> _initActiveTruck() async {
    String? savedTruck = PreferencesService().getString('active_truck_id');
    if (savedTruck != null && savedTruck.isNotEmpty) {
      _activeTruckId = savedTruck;
    }
    await _ensureTruckExists();
    _listenToStock();
  }

  void setActiveTruck(String truckId) {
    _activeTruckId = truckId;
    PreferencesService().setString('active_truck_id', truckId);
    _listenToStock();
  }

  Future<void> _ensureTruckExists() async {
    final doc = await TenantDB.collection('trucks').doc(_activeTruckId).get();
    if (!doc.exists) {
      await TenantDB.collection('trucks').doc(_activeTruckId).set({
        'name': 'Camioneta Principal',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _listenToStock() {
    TenantDB.collection('trucks').doc(_activeTruckId).collection('stock').snapshots().listen((snapshot) {
      _currentStock = snapshot.docs.map((doc) => TruckStock.fromDocument(doc)).toList();
      notifyListeners();
    });
  }

  int? getStockForVariant(String productId, String variantName) {
    try {
      return _currentStock.firstWhere((s) => s.productId == productId && s.variantName == variantName).quantity;
    } catch (_) {
      return null;
    }
  }

  Future<void> updateStock(String productId, String variantName, int quantityDelta, String type) async {
    final stockId = '${productId}_$variantName';
    final stockRef = TenantDB.collection('trucks').doc(_activeTruckId).collection('stock').doc(stockId);

    final currentQuantity = getStockForVariant(productId, variantName);
    
    int newQuantity;
    if (currentQuantity != null) {
      newQuantity = currentQuantity + quantityDelta;
    } else {
      if (type.startsWith('sale_')) {
        return; // Maintain infinite stock
      }
      newQuantity = quantityDelta < 0 ? 0 : quantityDelta;
    }
      
    if (newQuantity < 0) newQuantity = 0;

    final batch = _db.batch();
    batch.set(stockRef, {
      'productId': productId,
      'variantName': variantName,
      'quantity': newQuantity,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Guardar log
    final logRef = TenantDB.collection('cargo_logs').doc();
    batch.set(logRef, {
      'date': FieldValue.serverTimestamp(),
      'truckId': _activeTruckId,
      'productId': productId,
      'variantName': variantName,
      'addedQuantity': newQuantity - (currentQuantity ?? 0), // Use the actual applied delta
      'type': type, // 'manual_add', 'manual_remove', 'manual_set', 'sale_deduction', 'clear'
    });
    
    await batch.commit();
  }
  
  // Set explicit quantity
  Future<void> setStock(String productId, String variantName, int quantity) async {
    if (quantity < 0) quantity = 0;
    await updateStock(productId, variantName, quantity - (getStockForVariant(productId, variantName) ?? 0), 'manual_set');
  }

  // Remove stock constraint (set to infinite)
  Future<void> setStockInfinite(String productId, String variantName) async {
    final stockId = '${productId}_$variantName';
    final stockRef = _db.collection('trucks').doc(_activeTruckId).collection('stock').doc(stockId);
    
    await stockRef.delete();

    // Log deletion
    final logRef = _db.collection('cargo_logs').doc();
    await logRef.set({
      'date': FieldValue.serverTimestamp(),
      'truckId': _activeTruckId,
      'productId': productId,
      'variantName': variantName,
      'addedQuantity': 0,
      'type': 'clear',
    });
  }

  Future<void> clearAllStock() async {
    final batch = _db.batch();
    final stockDocs = await _db.collection('trucks').doc(_activeTruckId).collection('stock').get();
    
    for (var doc in stockDocs.docs) {
      batch.delete(doc.reference); // Return to infinite
      
      final logRef = _db.collection('cargo_logs').doc();
      batch.set(logRef, {
        'date': FieldValue.serverTimestamp(),
        'truckId': _activeTruckId,
        'productId': doc.data()['productId'],
        'variantName': doc.data()['variantName'],
        'addedQuantity': -doc.data()['quantity'],
        'type': 'clear',
      });
    }
    
    await batch.commit();
  }
}
