import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product.dart';
import '../../core/preferences_service.dart';
import '../../core/tenant_db.dart';

class InventoryActions extends ChangeNotifier {
  static final InventoryActions _instance = InventoryActions._internal();
  factory InventoryActions() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Product> _products = [];
  List<Product> get products => _products;

  String _selectedCategory = 'Todas';
  String get selectedCategory => _selectedCategory;

  InventoryActions._internal() {
    _selectedCategory = PreferencesService().getString('inventory_category') ?? 'Todas';
    _listenToInventory();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    PreferencesService().setString('inventory_category', category);
    notifyListeners();
  }

  void _listenToInventory() {
    TenantDB.collection('inventory').orderBy('name').snapshots().listen((snapshot) {
      _products.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        var variantsList = data['variants'] as List<dynamic>? ?? [];
        _products.add(Product(
          id: doc.id,
          name: data['name'] ?? '',
          price: (data['price'] ?? 0).toDouble(),
          resellerPrice: data['resellerPrice'] != null ? (data['resellerPrice'] as num).toDouble() : null,
          specialPrice: data['specialPrice'] != null ? (data['specialPrice'] as num).toDouble() : null,
          category: data['category'] ?? 'Sin Categoría',
          variants: variantsList.map((v) => ProductVariant.fromMap(Map<String,dynamic>.from(v))).toList(),
        ));
      }
      notifyListeners();
    });
  }

  void addProduct(String name, double price, String category, List<ProductVariant> variants, {double? resellerPrice, double? specialPrice}) {
    TenantDB.collection('inventory').add({
      'name': name,
      'price': price,
      'resellerPrice': resellerPrice,
      'specialPrice': specialPrice,
      'category': category.isEmpty ? 'Sin Categoría' : category,
      'variants': variants.map((v) => v.toMap()).toList(),
    });
  }

  void updateProduct(String id, String name, double price, String category, List<ProductVariant> variants, {double? resellerPrice, double? specialPrice}) {
    final updateData = {
      'name': name,
      'price': price,
      'category': category.isEmpty ? 'Sin Categoría' : category,
      'variants': variants.map((v) => v.toMap()).toList(),
    };
    if (resellerPrice != null) updateData['resellerPrice'] = resellerPrice;
    if (specialPrice != null) updateData['specialPrice'] = specialPrice;
    TenantDB.collection('inventory').doc(id).update(updateData);
  }

  Future<void> updateProductPriceWithHistory(String productId, String productName, double oldPrice, double newPrice, {String variantName = ''}) async {
    final now = DateTime.now();
    await TenantDB.collection('inventory').doc(productId).update({
      'price': newPrice,
    });

    await TenantDB.collection('price_history').add({
      'productId': productId,
      'productName': productName,
      'variantName': variantName,
      'oldPrice': oldPrice,
      'newPrice': newPrice,
      'date': Timestamp.fromDate(now),
    });
  }

  Future<void> updateResellerPrice(String id, double? price, List<ProductVariant> variants) async {
    await TenantDB.collection('inventory').doc(id).update({
      'resellerPrice': price,
      'variants': variants.map((v) => v.toMap()).toList(),
    });
  }

  Future<void> updateSpecialPrice(String id, double? price, List<ProductVariant> variants) async {
    await TenantDB.collection('inventory').doc(id).update({
      'specialPrice': price,
      'variants': variants.map((v) => v.toMap()).toList(),
    });
  }

  void deleteProduct(String id) {
    TenantDB.collection('inventory').doc(id).delete();
  }

  void removeProduct(String id) {
    _firestore.collection('inventory').doc(id).delete();
  }
}
