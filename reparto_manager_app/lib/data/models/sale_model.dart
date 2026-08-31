// lib/data/models/sale_model.dart
// Capa de Datos e Infraestructura SQLite - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'dart:convert';
import '../../domain/core/money.dart';
import '../../domain/entities/sale_entity.dart';

/// Modelo de datos para la tabla SQLite `sales`.
/// Convierte bidireccionalmente entre [SaleEntity] y mapas SQLite.
class SaleModel {
  final String id;
  final String tenantId;
  final int ticketNumber;
  final String dateUtc;
  final String clientId;
  final String clientName;
  final String itemsJson;
  final String? exchangesJson;
  final String? appliedPromosJson;
  final int subtotalCents;
  final int totalDiscountCents;
  final int totalCents;
  final String paymentMethod;
  final int cashPaidCents;
  final int transferPaidCents;
  final int debtGeneratedCents;
  final int previousBalanceCents;
  final int remainingBalanceCents;
  final int isCancelled;

  const SaleModel({
    required this.id,
    required this.tenantId,
    required this.ticketNumber,
    required this.dateUtc,
    required this.clientId,
    required this.clientName,
    required this.itemsJson,
    this.exchangesJson,
    this.appliedPromosJson,
    required this.subtotalCents,
    required this.totalDiscountCents,
    required this.totalCents,
    required this.paymentMethod,
    required this.cashPaidCents,
    required this.transferPaidCents,
    required this.debtGeneratedCents,
    required this.previousBalanceCents,
    required this.remainingBalanceCents,
    required this.isCancelled,
  });

  /// Crea un [SaleModel] a partir de una [SaleEntity].
  factory SaleModel.fromEntity(SaleEntity entity) {
    final itemsList = entity.items.map((i) => {
      'productId': i.productId,
      'productName': i.productName,
      'variantName': i.variantName,
      'quantity': i.quantity,
      'unitPriceCents': i.unitPrice.cents,
      'unitCostCents': i.unitCost.cents,
      'discountCents': i.discount.cents,
    }).toList();

    final exchangesList = entity.exchanges.map((e) => {
      'productId': e.productId,
      'productName': e.productName,
      'variantName': e.variantName,
      'quantity': e.quantity,
    }).toList();

    return SaleModel(
      id: entity.id,
      tenantId: entity.tenantId,
      ticketNumber: entity.ticketNumber,
      dateUtc: entity.date.toUtc().toIso8601String(),
      clientId: entity.clientId,
      clientName: entity.clientName,
      itemsJson: jsonEncode(itemsList),
      exchangesJson: exchangesList.isNotEmpty ? jsonEncode(exchangesList) : null,
      appliedPromosJson: entity.appliedPromos.isNotEmpty ? jsonEncode(entity.appliedPromos) : null,
      subtotalCents: entity.subtotal.cents,
      totalDiscountCents: entity.totalDiscount.cents,
      totalCents: entity.total.cents,
      paymentMethod: entity.paymentMethod.name,
      cashPaidCents: entity.cashPaid.cents,
      transferPaidCents: entity.transferPaid.cents,
      debtGeneratedCents: entity.debtGenerated.cents,
      previousBalanceCents: entity.previousBalance?.cents ?? 0,
      remainingBalanceCents: entity.remainingBalance?.cents ?? 0,
      isCancelled: entity.isCancelled ? 1 : 0,
    );
  }

  /// Convierte este modelo a una [SaleEntity] de dominio puro.
  SaleEntity toEntity() {
    final itemsDecoded = jsonDecode(itemsJson) as List<dynamic>;
    final items = itemsDecoded.map((raw) {
      final map = raw as Map<String, dynamic>;
      return SaleItemEntity(
        productId: map['productId'] as String,
        productName: map['productName'] as String,
        variantName: map['variantName'] as String,
        quantity: (map['quantity'] as num).toInt(),
        unitPrice: Money.fromCents((map['unitPriceCents'] as num).toInt()),
        unitCost: Money.fromCents((map['unitCostCents'] as num).toInt()),
        discount: Money.fromCents((map['discountCents'] as num).toInt()),
      );
    }).toList();

    List<ExchangeItemEntity> exchanges = const [];
    if (exchangesJson != null && exchangesJson!.trim().isNotEmpty) {
      final exchangesDecoded = jsonDecode(exchangesJson!) as List<dynamic>;
      exchanges = exchangesDecoded.map((raw) {
        final map = raw as Map<String, dynamic>;
        return ExchangeItemEntity(
          productId: map['productId'] as String,
          productName: map['productName'] as String,
          variantName: map['variantName'] as String,
          quantity: (map['quantity'] as num).toInt(),
        );
      }).toList();
    }

    List<String> appliedPromos = const [];
    if (appliedPromosJson != null && appliedPromosJson!.trim().isNotEmpty) {
      final promosDecoded = jsonDecode(appliedPromosJson!) as List<dynamic>;
      appliedPromos = promosDecoded.map((e) => e.toString()).toList();
    }

    return SaleEntity(
      id: id,
      tenantId: tenantId,
      ticketNumber: ticketNumber,
      date: DateTime.parse(dateUtc).toUtc(),
      clientId: clientId,
      clientName: clientName,
      items: items,
      exchanges: exchanges,
      appliedPromos: appliedPromos,
      subtotal: Money.fromCents(subtotalCents),
      totalDiscount: Money.fromCents(totalDiscountCents),
      total: Money.fromCents(totalCents),
      paymentMethod: _parsePaymentMethod(paymentMethod),
      cashPaid: Money.fromCents(cashPaidCents),
      transferPaid: Money.fromCents(transferPaidCents),
      debtGenerated: Money.fromCents(debtGeneratedCents),
      previousBalance: previousBalanceCents != 0 ? Money.fromCents(previousBalanceCents) : null,
      remainingBalance: remainingBalanceCents != 0 ? Money.fromCents(remainingBalanceCents) : null,
      isCancelled: isCancelled == 1,
    );
  }

  /// Crea un [SaleModel] desde una fila de SQLite.
  factory SaleModel.fromMap(Map<String, dynamic> map) {
    return SaleModel(
      id: map['id'] as String,
      tenantId: map['tenantId'] as String,
      ticketNumber: (map['ticketNumber'] as num).toInt(),
      dateUtc: map['dateUtc'] as String,
      clientId: map['clientId'] as String,
      clientName: map['clientName'] as String,
      itemsJson: map['itemsJson'] as String,
      exchangesJson: map['exchangesJson'] as String?,
      appliedPromosJson: map['appliedPromosJson'] as String?,
      subtotalCents: (map['subtotalCents'] as num).toInt(),
      totalDiscountCents: (map['totalDiscountCents'] as num).toInt(),
      totalCents: (map['totalCents'] as num).toInt(),
      paymentMethod: map['paymentMethod'] as String,
      cashPaidCents: (map['cashPaidCents'] as num).toInt(),
      transferPaidCents: (map['transferPaidCents'] as num).toInt(),
      debtGeneratedCents: (map['debtGeneratedCents'] as num).toInt(),
      previousBalanceCents: (map['previousBalanceCents'] as num).toInt(),
      remainingBalanceCents: (map['remainingBalanceCents'] as num).toInt(),
      isCancelled: (map['isCancelled'] as num).toInt(),
    );
  }

  /// Exporta los datos a un mapa apto para inserción en SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'ticketNumber': ticketNumber,
      'dateUtc': dateUtc,
      'clientId': clientId,
      'clientName': clientName,
      'itemsJson': itemsJson,
      'exchangesJson': exchangesJson,
      'appliedPromosJson': appliedPromosJson,
      'subtotalCents': subtotalCents,
      'totalDiscountCents': totalDiscountCents,
      'totalCents': totalCents,
      'paymentMethod': paymentMethod,
      'cashPaidCents': cashPaidCents,
      'transferPaidCents': transferPaidCents,
      'debtGeneratedCents': debtGeneratedCents,
      'previousBalanceCents': previousBalanceCents,
      'remainingBalanceCents': remainingBalanceCents,
      'isCancelled': isCancelled,
    };
  }

  static PaymentMethod _parsePaymentMethod(String val) {
    return PaymentMethod.values.firstWhere(
      (e) => e.name == val,
      orElse: () => PaymentMethod.cash,
    );
  }
}
