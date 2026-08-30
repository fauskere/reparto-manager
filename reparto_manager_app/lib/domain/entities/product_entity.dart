// lib/domain/entities/product_entity.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/money.dart';
import '../core/result.dart';

/// Variante específica de un producto (ej: tamaño, calibre, presentación).
class ProductVariant {
  final String productId;
  final String variantName;
  final Money basePrice;
  final Money costPrice;
  final Money? specialPrice;
  final Money? resellerPrice;
  final int stockWarehouse;
  final int minStockAlert;

  const ProductVariant({
    required this.productId,
    required this.variantName,
    required this.basePrice,
    required this.costPrice,
    this.specialPrice,
    this.resellerPrice,
    this.stockWarehouse = 0,
    this.minStockAlert = 0,
  });

  /// Identificador compuesto unificado para stock y listas de precios ("productId|variantName").
  String get variantKey => '$productId|$variantName';

  /// Margen bruto unitario sobre el precio base.
  Money get unitMargin => basePrice - costPrice;

  ProductVariant copyWith({
    String? productId,
    String? variantName,
    Money? basePrice,
    Money? costPrice,
    Money? specialPrice,
    Money? resellerPrice,
    int? stockWarehouse,
    int? minStockAlert,
  }) {
    return ProductVariant(
      productId: productId ?? this.productId,
      variantName: variantName ?? this.variantName,
      basePrice: basePrice ?? this.basePrice,
      costPrice: costPrice ?? this.costPrice,
      specialPrice: specialPrice ?? this.specialPrice,
      resellerPrice: resellerPrice ?? this.resellerPrice,
      stockWarehouse: stockWarehouse ?? this.stockWarehouse,
      minStockAlert: minStockAlert ?? this.minStockAlert,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductVariant &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          variantName == other.variantName &&
          basePrice == other.basePrice &&
          costPrice == other.costPrice &&
          specialPrice == other.specialPrice &&
          resellerPrice == other.resellerPrice &&
          stockWarehouse == other.stockWarehouse &&
          minStockAlert == other.minStockAlert;

  @override
  int get hashCode => Object.hash(
        runtimeType,
        productId,
        variantName,
        basePrice,
        costPrice,
        specialPrice,
        resellerPrice,
        stockWarehouse,
        minStockAlert,
      );

  @override
  String toString() => 'ProductVariant($variantKey, price: $basePrice)';
}

/// Entidad inmutable que representa un producto del catálogo.
class ProductEntity {
  final String id;
  final String tenantId;
  final String name;
  final String category;
  final String? barcode;
  final String? imageUrl;
  final List<ProductVariant> variants;
  final bool isActive;

  ProductEntity({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.category,
    this.barcode,
    this.imageUrl,
    List<ProductVariant>? variants,
    this.isActive = true,
  }) : variants = List.unmodifiable(variants ?? const <ProductVariant>[]);

  /// Crea un producto validando los campos obligatorios.
  static Result<ProductEntity, DomainFailure> create({
    required String id,
    required String tenantId,
    required String name,
    required String category,
    String? barcode,
    String? imageUrl,
    List<ProductVariant>? variants,
    bool isActive = true,
  }) {
    if (id.trim().isEmpty || tenantId.trim().isEmpty || name.trim().isEmpty) {
      return Result.fail(
        const EntityValidationFailure(
          'El id, tenantId y nombre del producto son obligatorios y no pueden estar vacíos',
        ),
      );
    }

    return Result.ok(
      ProductEntity(
        id: id.trim(),
        tenantId: tenantId.trim(),
        name: name.trim(),
        category: category.trim(),
        barcode: barcode?.trim(),
        imageUrl: imageUrl?.trim(),
        variants: variants,
        isActive: isActive,
      ),
    );
  }

  /// Busca una variante específica por su nombre de presentación.
  ProductVariant? findVariant(String variantName) {
    for (final v in variants) {
      if (v.variantName.toLowerCase() == variantName.toLowerCase()) {
        return v;
      }
    }
    return null;
  }

  ProductEntity copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? category,
    String? barcode,
    String? imageUrl,
    List<ProductVariant>? variants,
    bool? isActive,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      variants: variants ?? this.variants,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tenantId == other.tenantId &&
          name == other.name &&
          category == other.category &&
          barcode == other.barcode &&
          imageUrl == other.imageUrl &&
          _listEquals(variants, other.variants) &&
          isActive == other.isActive;

  @override
  int get hashCode => Object.hash(
        runtimeType,
        id,
        tenantId,
        name,
        category,
        barcode,
        imageUrl,
        Object.hashAll(variants),
        isActive,
      );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() => 'ProductEntity(id: $id, name: $name, variants: ${variants.length})';
}
