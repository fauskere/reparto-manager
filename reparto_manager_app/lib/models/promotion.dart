class PromoRequirement {
  final String productId;
  final String? variantName; // null means "any variant"
  final int quantity;

  PromoRequirement({
    required this.productId,
    this.variantName,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'variantName': variantName,
      'quantity': quantity,
    };
  }

  factory PromoRequirement.fromMap(Map<String, dynamic> map) {
    return PromoRequirement(
      productId: map['productId'] ?? '',
      variantName: map['variantName'],
      quantity: map['quantity'] ?? 1,
    );
  }
}

class Promotion {
  final String id;
  final String name;
  final List<PromoRequirement> requiredItems;
  final double discountPercentage;
  final bool isActive;

  Promotion({
    required this.id,
    required this.name,
    required this.requiredItems,
    required this.discountPercentage,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'requiredItems': requiredItems.map((e) => e.toMap()).toList(),
      'discountPercentage': discountPercentage,
      'isActive': isActive,
    };
  }

  factory Promotion.fromMap(String id, Map<String, dynamic> map) {
    List<PromoRequirement> reqItems = [];
    if (map.containsKey('requiredItems')) {
      reqItems = (map['requiredItems'] as List).map((e) => PromoRequirement.fromMap(Map<String, dynamic>.from(e))).toList();
    } else if (map.containsKey('requiredProductIds')) {
      // Legacy conversion
      final legacyIds = List<String>.from(map['requiredProductIds'] ?? []);
      final countMap = <String, int>{};
      for(var prodId in legacyIds) {
        countMap[prodId] = (countMap[prodId] ?? 0) + 1;
      }
      countMap.forEach((prodId, qty) {
        reqItems.add(PromoRequirement(productId: prodId, variantName: null, quantity: qty));
      });
    }

    return Promotion(
      id: id,
      name: map['name'] ?? '',
      requiredItems: reqItems,
      discountPercentage: (map['discountPercentage'] ?? 0).toDouble(),
      isActive: map['isActive'] ?? true,
    );
  }
}
