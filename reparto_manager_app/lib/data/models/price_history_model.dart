// lib/data/models/price_history_model.dart
// Capa de Datos e Infraestructura SQLite - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import '../../domain/core/money.dart';

/// Modelo de datos para la tabla SQLite `price_history`.
/// Audita variaciones históricas de precios por producto y variante.
class PriceHistoryModel {
  final String id;
  final String tenantId;
  final String productId;
  final String productName;
  final String variantName;
  final int oldPriceCents;
  final int newPriceCents;
  final String changedAtUtc;

  const PriceHistoryModel({
    required this.id,
    required this.tenantId,
    required this.productId,
    required this.productName,
    required this.variantName,
    required this.oldPriceCents,
    required this.newPriceCents,
    required this.changedAtUtc,
  });

  /// Accesor de Money para el precio anterior.
  Money get oldPrice => Money.fromCents(oldPriceCents);

  /// Accesor de Money para el nuevo precio.
  Money get newPrice => Money.fromCents(newPriceCents);

  /// Accesor de DateTime UTC.
  DateTime get changedAt => DateTime.parse(changedAtUtc);

  /// Crea un [PriceHistoryModel] a partir de datos tipados.
  factory PriceHistoryModel.create({
    required String id,
    required String tenantId,
    required String productId,
    required String productName,
    required String variantName,
    required Money oldPrice,
    required Money newPrice,
    required DateTime changedAt,
  }) {
    return PriceHistoryModel(
      id: id,
      tenantId: tenantId,
      productId: productId,
      productName: productName,
      variantName: variantName,
      oldPriceCents: oldPrice.cents,
      newPriceCents: newPrice.cents,
      changedAtUtc: changedAt.toUtc().toIso8601String(),
    );
  }

  /// Crea un [PriceHistoryModel] desde una fila de SQLite.
  factory PriceHistoryModel.fromMap(Map<String, dynamic> map) {
    return PriceHistoryModel(
      id: map['id'] as String,
      tenantId: map['tenantId'] as String,
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      variantName: map['variantName'] as String,
      oldPriceCents: (map['oldPriceCents'] as num).toInt(),
      newPriceCents: (map['newPriceCents'] as num).toInt(),
      changedAtUtc: map['changedAtUtc'] as String,
    );
  }

  /// Exporta los datos a un mapa apto para inserción en SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'productId': productId,
      'productName': productName,
      'variantName': variantName,
      'oldPriceCents': oldPriceCents,
      'newPriceCents': newPriceCents,
      'changedAtUtc': changedAtUtc,
    };
  }
}
