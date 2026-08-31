// lib/data/models/product_model.dart
// Capa de Datos e Infraestructura SQLite - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'dart:convert';
import '../../domain/core/money.dart';
import '../../domain/entities/product_entity.dart';

/// Modelo de datos para la tabla SQLite `products`.
/// Mapea de forma bidireccional [ProductEntity] y sus variantes.
class ProductModel {
  final String id;
  final String tenantId;
  final String name;
  final String category;
  final String? barcode;
  final String? imageUrl;
  final String variantsJson;
  final int isActive;

  const ProductModel({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.category,
    this.barcode,
    this.imageUrl,
    required this.variantsJson,
    required this.isActive,
  });

  /// Crea un [ProductModel] a partir de una [ProductEntity].
  factory ProductModel.fromEntity(ProductEntity entity) {
    final variantsList = entity.variants.map((v) {
      return {
        'variantName': v.variantName,
        'productId': v.productId,
        'basePriceCents': v.basePrice.cents,
        'costPriceCents': v.costPrice.cents,
        'specialPriceCents': v.specialPrice?.cents,
        'resellerPriceCents': v.resellerPrice?.cents,
        'stockWarehouse': v.stockWarehouse,
        'minStockAlert': v.minStockAlert,
      };
    }).toList();

    return ProductModel(
      id: entity.id,
      tenantId: entity.tenantId,
      name: entity.name,
      category: entity.category,
      barcode: entity.barcode,
      imageUrl: entity.imageUrl,
      variantsJson: jsonEncode(variantsList),
      isActive: entity.isActive ? 1 : 0,
    );
  }

  /// Convierte este modelo a una [ProductEntity] de dominio puro.
  ProductEntity toEntity() {
    final List<dynamic> decoded = jsonDecode(variantsJson) as List<dynamic>;
    final variants = decoded.map((raw) {
      final map = raw as Map<String, dynamic>;
      return ProductVariant(
        variantName: map['variantName'] as String,
        productId: map['productId'] as String? ?? id,
        basePrice: Money.fromCents((map['basePriceCents'] as num).toInt()),
        costPrice: Money.fromCents((map['costPriceCents'] as num).toInt()),
        specialPrice: map['specialPriceCents'] != null
            ? Money.fromCents((map['specialPriceCents'] as num).toInt())
            : null,
        resellerPrice: map['resellerPriceCents'] != null
            ? Money.fromCents((map['resellerPriceCents'] as num).toInt())
            : null,
        stockWarehouse: (map['stockWarehouse'] as num?)?.toInt() ?? 0,
        minStockAlert: (map['minStockAlert'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    return ProductEntity(
      id: id,
      tenantId: tenantId,
      name: name,
      category: category,
      barcode: barcode,
      imageUrl: imageUrl,
      variants: variants,
      isActive: isActive == 1,
    );
  }

  /// Crea un [ProductModel] desde una fila de SQLite.
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String,
      tenantId: map['tenantId'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      barcode: map['barcode'] as String?,
      imageUrl: map['imageUrl'] as String?,
      variantsJson: map['variantsJson'] as String,
      isActive: (map['isActive'] as num).toInt(),
    );
  }

  /// Exporta los datos a un mapa apto para inserción en SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'name': name,
      'category': category,
      'barcode': barcode,
      'imageUrl': imageUrl,
      'variantsJson': variantsJson,
      'isActive': isActive,
    };
  }
}
