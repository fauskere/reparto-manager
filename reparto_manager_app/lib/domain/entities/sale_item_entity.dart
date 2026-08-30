// lib/domain/entities/sale_item_entity.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/money.dart';

/// Renglón individual de venta correspondiente a una variante de producto.
class SaleItemEntity {
  final String productId;
  final String variantName;
  final String productName;
  final int quantity;
  final Money unitPrice;
  final Money unitCost;
  final Money discount;

  const SaleItemEntity({
    required this.productId,
    required this.variantName,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.unitCost,
    this.discount = Money.zero,
  });

  /// Clave unificada de la variante vendida ("productId|variantName").
  String get variantKey => '$productId|$variantName';

  /// Subtotal del renglón aplicando el descuento ((unitPrice * quantity) - discount).
  Money get subtotal => (unitPrice * quantity) - discount;

  /// Costo total de adquisición de las unidades vendidas.
  Money get totalCost => unitCost * quantity;

  /// Ganancia bruta neta generada por este renglón.
  Money get profit => subtotal - totalCost;

  SaleItemEntity copyWith({
    String? productId,
    String? variantName,
    String? productName,
    int? quantity,
    Money? unitPrice,
    Money? unitCost,
    Money? discount,
  }) {
    return SaleItemEntity(
      productId: productId ?? this.productId,
      variantName: variantName ?? this.variantName,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      unitCost: unitCost ?? this.unitCost,
      discount: discount ?? this.discount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleItemEntity &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          variantName == other.variantName &&
          productName == other.productName &&
          quantity == other.quantity &&
          unitPrice == other.unitPrice &&
          unitCost == other.unitCost &&
          discount == other.discount;

  @override
  int get hashCode => Object.hash(
        runtimeType,
        productId,
        variantName,
        productName,
        quantity,
        unitPrice,
        unitCost,
        discount,
      );

  @override
  String toString() => 'SaleItem($productName ($variantName) x$quantity = $subtotal)';
}

/// Renglón de cambio de mercadería defectuosa o devolución de envases.
class ExchangeItemEntity {
  final String productId;
  final String variantName;
  final String productName;
  final int quantity;

  const ExchangeItemEntity({
    required this.productId,
    required this.variantName,
    required this.productName,
    required this.quantity,
  });

  /// Clave unificada de la variante de cambio ("productId|variantName").
  String get variantKey => '$productId|$variantName';

  ExchangeItemEntity copyWith({
    String? productId,
    String? variantName,
    String? productName,
    int? quantity,
  }) {
    return ExchangeItemEntity(
      productId: productId ?? this.productId,
      variantName: variantName ?? this.variantName,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExchangeItemEntity &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          variantName == other.variantName &&
          productName == other.productName &&
          quantity == other.quantity;

  @override
  int get hashCode => Object.hash(
        runtimeType,
        productId,
        variantName,
        productName,
        quantity,
      );

  @override
  String toString() => 'ExchangeItem($productName ($variantName) x$quantity)';
}
