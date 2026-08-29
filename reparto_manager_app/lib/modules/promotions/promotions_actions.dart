import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/promotion.dart';
import '../../core/tenant_db.dart';

class PromotionsActions extends ChangeNotifier {
  static final PromotionsActions _instance = PromotionsActions._internal();
  factory PromotionsActions() => _instance;

  List<Promotion> _promotions = [];
  bool _isLoading = true;

  List<Promotion> get promotions => _promotions;
  bool get isLoading => _isLoading;

  PromotionsActions._internal() {
    _listenToPromotions();
  }

  void _listenToPromotions() {
    TenantDB.collection('promotions').snapshots().listen((snapshot) {
      _promotions = snapshot.docs.map((doc) => Promotion.fromMap(doc.id, doc.data())).toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      print("Error fetching promotions: $e");
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addPromotion(String name, double discountPercentage, List<PromoRequirement> requiredItems) async {
    await TenantDB.collection('promotions').add({
      'name': name,
      'discountPercentage': discountPercentage,
      'requiredItems': requiredItems.map((e) => e.toMap()).toList(),
      'isActive': true,
    });
  }

  Future<void> updatePromotion(String id, String name, double discountPercentage, List<PromoRequirement> requiredItems) async {
    await TenantDB.collection('promotions').doc(id).update({
      'name': name,
      'discountPercentage': discountPercentage,
      'requiredItems': requiredItems.map((e) => e.toMap()).toList(),
    });
  }

  Future<void> togglePromotionStatus(String id, bool currentStatus) async {
    await TenantDB.collection('promotions').doc(id).update({
      'isActive': !currentStatus,
    });
  }

  Future<void> deletePromotion(String id) async {
    await TenantDB.collection('promotions').doc(id).delete();
  }
}
