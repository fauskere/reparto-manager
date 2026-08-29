class ProductVariant {
  final String name;
  final double? price;
  final double? resellerPrice; // Precio mayorista de la variante
  final double? specialPrice; // Precio global para clientes especiales
  final int? lowStockThreshold; // Umbral de alerta de stock bajo

  ProductVariant({
    required this.name,
    this.price,
    this.resellerPrice,
    this.specialPrice,
    this.lowStockThreshold,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'resellerPrice': resellerPrice,
      'specialPrice': specialPrice,
      'lowStockThreshold': lowStockThreshold,
    };
  }

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      name: map['name'] ?? '',
      price: map['price']?.toDouble(),
      resellerPrice: map['resellerPrice']?.toDouble(),
      specialPrice: map['specialPrice']?.toDouble(),
      lowStockThreshold: map['lowStockThreshold']?.toInt(),
    );
  }
}

class Product {
  final String id;
  final String name;
  final double price;
  final double? resellerPrice; // Precio mayorista del producto principal
  final double? specialPrice; // Precio global para clientes especiales
  final String image;
  final String category;
  final List<ProductVariant> variants;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.resellerPrice,
    this.specialPrice,
    this.image = '',
    this.category = 'Sin Categoría',
    this.variants = const [],
  });
}

class CartItem {
  final Product product;
  final ProductVariant? selectedVariant;
  int quantity;
  double? overridePrice;
  double manualDiscount;

  CartItem({
    required this.product,
    this.selectedVariant,
    this.quantity = 1,
    this.overridePrice,
    this.manualDiscount = 0.0,
  });

  double get unitPrice => overridePrice ?? selectedVariant?.price ?? product.price;
  double get total => (unitPrice - manualDiscount) * quantity;
}
