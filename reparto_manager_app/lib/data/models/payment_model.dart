// lib/data/models/payment_model.dart
// Capa de Datos e Infraestructura SQLite - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import '../../domain/core/money.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/sale_entity.dart';

/// Modelo de datos para la tabla SQLite `payments`.
/// Convierte bidireccionalmente entre [PaymentEntity] y mapas SQLite.
class PaymentModel {
  final String id;
  final String tenantId;
  final int receiptNumber;
  final String dateUtc;
  final String clientId;
  final int amountCents;
  final int cashPaidCents;
  final int transferPaidCents;
  final int previousBalanceCents;
  final int remainingBalanceCents;
  final String? notes;
  final int isCancelled;

  const PaymentModel({
    required this.id,
    required this.tenantId,
    required this.receiptNumber,
    required this.dateUtc,
    required this.clientId,
    required this.amountCents,
    required this.cashPaidCents,
    required this.transferPaidCents,
    required this.previousBalanceCents,
    required this.remainingBalanceCents,
    this.notes,
    required this.isCancelled,
  });

  /// Crea un [PaymentModel] a partir de una [PaymentEntity].
  factory PaymentModel.fromEntity(PaymentEntity entity, {bool isCancelled = false}) {
    return PaymentModel(
      id: entity.id,
      tenantId: entity.tenantId,
      receiptNumber: entity.receiptNumber,
      dateUtc: entity.date.toUtc().toIso8601String(),
      clientId: entity.clientId,
      amountCents: entity.amount.cents,
      cashPaidCents: entity.cashPaid.cents,
      transferPaidCents: entity.transferPaid.cents,
      previousBalanceCents: entity.previousBalance?.cents ?? 0,
      remainingBalanceCents: entity.remainingBalance?.cents ?? 0,
      notes: entity.notes,
      isCancelled: isCancelled ? 1 : 0,
    );
  }

  /// Convierte este modelo a una [PaymentEntity] de dominio puro.
  PaymentEntity toEntity() {
    final cash = Money.fromCents(cashPaidCents);
    final transfer = Money.fromCents(transferPaidCents);
    final totalAmount = Money.fromCents(amountCents);

    final PaymentMethod method;
    if (cashPaidCents > 0 && transferPaidCents > 0) {
      method = PaymentMethod.mixed;
    } else if (cashPaidCents > 0) {
      method = PaymentMethod.cash;
    } else {
      method = PaymentMethod.transfer;
    }

    return PaymentEntity(
      id: id,
      tenantId: tenantId,
      clientId: clientId,
      receiptNumber: receiptNumber,
      date: DateTime.parse(dateUtc).toUtc(),
      amount: totalAmount,
      cashPaid: cash,
      transferPaid: transfer,
      method: method,
      previousBalance: previousBalanceCents != 0 ? Money.fromCents(previousBalanceCents) : null,
      remainingBalance: remainingBalanceCents != 0 ? Money.fromCents(remainingBalanceCents) : null,
      notes: notes,
    );
  }

  /// Crea un [PaymentModel] desde una fila de SQLite.
  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] as String,
      tenantId: map['tenantId'] as String,
      receiptNumber: (map['receiptNumber'] as num).toInt(),
      dateUtc: map['dateUtc'] as String,
      clientId: map['clientId'] as String,
      amountCents: (map['amountCents'] as num).toInt(),
      cashPaidCents: (map['cashPaidCents'] as num).toInt(),
      transferPaidCents: (map['transferPaidCents'] as num).toInt(),
      previousBalanceCents: (map['previousBalanceCents'] as num).toInt(),
      remainingBalanceCents: (map['remainingBalanceCents'] as num).toInt(),
      notes: map['notes'] as String?,
      isCancelled: (map['isCancelled'] as num).toInt(),
    );
  }

  /// Exporta los datos a un mapa apto para inserción en SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'receiptNumber': receiptNumber,
      'dateUtc': dateUtc,
      'clientId': clientId,
      'amountCents': amountCents,
      'cashPaidCents': cashPaidCents,
      'transferPaidCents': transferPaidCents,
      'previousBalanceCents': previousBalanceCents,
      'remainingBalanceCents': remainingBalanceCents,
      'notes': notes,
      'isCancelled': isCancelled,
    };
  }
}
