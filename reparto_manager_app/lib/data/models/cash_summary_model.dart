// lib/data/models/cash_summary_model.dart
// Capa de Datos e Infraestructura SQLite - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'dart:convert';
import '../../domain/core/money.dart';
import '../../domain/entities/cash_summary_entity.dart';

/// Modelo de datos para la tabla SQLite `cash_summaries`.
/// Mapea arqueos diarios de caja separando efectivo físico vs transferencias.
class CashSummaryModel {
  final String id;
  final String tenantId;
  final String dateUtc;
  final String closedAtUtc;
  final int salesCashCents;
  final int salesTransferCents;
  final int paymentsCashCents;
  final int paymentsTransferCents;
  final int totalCashCents;
  final int totalTransferCents;
  final int totalRevenueCents;
  final int debtGeneratedCents;
  final String clientBreakdownJson;

  const CashSummaryModel({
    required this.id,
    required this.tenantId,
    required this.dateUtc,
    required this.closedAtUtc,
    required this.salesCashCents,
    required this.salesTransferCents,
    required this.paymentsCashCents,
    required this.paymentsTransferCents,
    required this.totalCashCents,
    required this.totalTransferCents,
    required this.totalRevenueCents,
    required this.debtGeneratedCents,
    required this.clientBreakdownJson,
  });

  /// Crea un [CashSummaryModel] a partir de una [CashSummaryEntity] y metadatos de auditoría.
  factory CashSummaryModel.fromEntity(
    CashSummaryEntity entity, {
    required String id,
    required String tenantId,
    required DateTime date,
    required DateTime closedAt,
  }) {
    final breakdownList = entity.clientBreakdown.map((item) => {
      'clientId': item.clientId,
      'clientName': item.clientName,
      'cashCents': item.cash.cents,
      'transferCents': item.transfer.cents,
    }).toList();

    return CashSummaryModel(
      id: id,
      tenantId: tenantId,
      dateUtc: date.toUtc().toIso8601String(),
      closedAtUtc: closedAt.toUtc().toIso8601String(),
      salesCashCents: entity.salesCash.cents,
      salesTransferCents: entity.salesTransfer.cents,
      paymentsCashCents: entity.paymentsCash.cents,
      paymentsTransferCents: entity.paymentsTransfer.cents,
      totalCashCents: entity.totalCash.cents,
      totalTransferCents: entity.totalTransfer.cents,
      totalRevenueCents: entity.totalRevenue.cents,
      debtGeneratedCents: entity.debtGenerated.cents,
      clientBreakdownJson: jsonEncode(breakdownList),
    );
  }

  /// Convierte este modelo a una [CashSummaryEntity] de dominio puro.
  CashSummaryEntity toEntity() {
    final List<dynamic> decoded = jsonDecode(clientBreakdownJson) as List<dynamic>;
    final breakdown = decoded.map((raw) {
      final map = raw as Map<String, dynamic>;
      return CashSummaryItem(
        clientId: map['clientId'] as String,
        clientName: map['clientName'] as String,
        cash: Money.fromCents((map['cashCents'] as num).toInt()),
        transfer: Money.fromCents((map['transferCents'] as num).toInt()),
      );
    }).toList();

    return CashSummaryEntity(
      salesCash: Money.fromCents(salesCashCents),
      salesTransfer: Money.fromCents(salesTransferCents),
      paymentsCash: Money.fromCents(paymentsCashCents),
      paymentsTransfer: Money.fromCents(paymentsTransferCents),
      debtGenerated: Money.fromCents(debtGeneratedCents),
      clientBreakdown: breakdown,
    );
  }

  /// Crea un [CashSummaryModel] desde una fila de SQLite.
  factory CashSummaryModel.fromMap(Map<String, dynamic> map) {
    return CashSummaryModel(
      id: map['id'] as String,
      tenantId: map['tenantId'] as String,
      dateUtc: map['dateUtc'] as String,
      closedAtUtc: map['closedAtUtc'] as String,
      salesCashCents: (map['salesCashCents'] as num).toInt(),
      salesTransferCents: (map['salesTransferCents'] as num).toInt(),
      paymentsCashCents: (map['paymentsCashCents'] as num).toInt(),
      paymentsTransferCents: (map['paymentsTransferCents'] as num).toInt(),
      totalCashCents: (map['totalCashCents'] as num).toInt(),
      totalTransferCents: (map['totalTransferCents'] as num).toInt(),
      totalRevenueCents: (map['totalRevenueCents'] as num).toInt(),
      debtGeneratedCents: (map['debtGeneratedCents'] as num).toInt(),
      clientBreakdownJson: map['clientBreakdownJson'] as String,
    );
  }

  /// Exporta los datos a un mapa apto para inserción en SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'dateUtc': dateUtc,
      'closedAtUtc': closedAtUtc,
      'salesCashCents': salesCashCents,
      'salesTransferCents': salesTransferCents,
      'paymentsCashCents': paymentsCashCents,
      'paymentsTransferCents': paymentsTransferCents,
      'totalCashCents': totalCashCents,
      'totalTransferCents': totalTransferCents,
      'totalRevenueCents': totalRevenueCents,
      'debtGeneratedCents': debtGeneratedCents,
      'clientBreakdownJson': clientBreakdownJson,
    };
  }
}
