// lib/domain/entities/payment_entity.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/money.dart';
import '../core/result.dart';
import 'sale_entity.dart';

/// Entidad inmutable que representa un pago o cobranza efectuada por un cliente.
class PaymentEntity {
  final String id;
  final String tenantId;
  final String clientId;
  final int receiptNumber;
  final DateTime date;
  final Money amount;
  final Money cashPaid;
  final Money transferPaid;
  final PaymentMethod method;
  final Money? previousBalance;
  final Money? remainingBalance;
  final String? transferReceiptNumber;
  final String? notes;

  const PaymentEntity({
    required this.id,
    required this.tenantId,
    required this.clientId,
    required this.receiptNumber,
    required this.date,
    required this.amount,
    required this.cashPaid,
    required this.transferPaid,
    required this.method,
    this.previousBalance,
    this.remainingBalance,
    this.transferReceiptNumber,
    this.notes,
  });

  /// Valida y construye un pago soportando pagos simples o mixtos con invariante contable.
  static Result<PaymentEntity, DomainFailure> create({
    required String id,
    required String tenantId,
    required String clientId,
    required int receiptNumber,
    required DateTime date,
    required Money cashPaid,
    required Money transferPaid,
    Money? previousBalance,
    Money? remainingBalance,
    String? transferReceiptNumber,
    String? notes,
  }) {
    if (id.trim().isEmpty || tenantId.trim().isEmpty || clientId.trim().isEmpty) {
      return Result.fail(
        const EntityValidationFailure(
          'Los identificadores de pago, tenant y cliente son obligatorios',
        ),
      );
    }

    final totalAmount = cashPaid + transferPaid;
    if (!totalAmount.isPositive) {
      return Result.fail(
        NegativeAmountNotAllowedFailure(
          'El importe total de la cobranza debe ser estrictamente mayor a cero',
          totalAmount,
        ),
      );
    }

    final PaymentMethod method;
    if (cashPaid.isPositive && transferPaid.isPositive) {
      method = PaymentMethod.mixed;
    } else if (cashPaid.isPositive) {
      method = PaymentMethod.cash;
    } else {
      method = PaymentMethod.transfer;
    }

    return Result.ok(
      PaymentEntity(
        id: id.trim(),
        tenantId: tenantId.trim(),
        clientId: clientId.trim(),
        receiptNumber: receiptNumber,
        date: date.toUtc(),
        amount: totalAmount,
        cashPaid: cashPaid,
        transferPaid: transferPaid,
        method: method,
        previousBalance: previousBalance,
        remainingBalance: remainingBalance,
        transferReceiptNumber: transferReceiptNumber?.trim(),
        notes: notes?.trim(),
      ),
    );
  }

  PaymentEntity copyWith({
    String? id,
    String? tenantId,
    String? clientId,
    int? receiptNumber,
    DateTime? date,
    Money? amount,
    Money? cashPaid,
    Money? transferPaid,
    PaymentMethod? method,
    Money? previousBalance,
    Money? remainingBalance,
    String? transferReceiptNumber,
    String? notes,
  }) {
    return PaymentEntity(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      clientId: clientId ?? this.clientId,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      cashPaid: cashPaid ?? this.cashPaid,
      transferPaid: transferPaid ?? this.transferPaid,
      method: method ?? this.method,
      previousBalance: previousBalance ?? this.previousBalance,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      transferReceiptNumber: transferReceiptNumber ?? this.transferReceiptNumber,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tenantId == other.tenantId &&
          clientId == other.clientId &&
          receiptNumber == other.receiptNumber &&
          date == other.date &&
          amount == other.amount &&
          cashPaid == other.cashPaid &&
          transferPaid == other.transferPaid &&
          method == other.method &&
          transferReceiptNumber == other.transferReceiptNumber &&
          notes == other.notes;

  @override
  int get hashCode => Object.hash(
        runtimeType,
        id,
        tenantId,
        clientId,
        receiptNumber,
        date,
        amount,
        cashPaid,
        transferPaid,
        method,
        transferReceiptNumber,
        notes,
      );

  @override
  String toString() =>
      'PaymentEntity(#$receiptNumber, cliente: $clientId, monto: $amount)';
}
