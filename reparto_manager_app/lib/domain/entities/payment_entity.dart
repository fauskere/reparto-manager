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
  final PaymentMethod method;
  final String? transferReceiptNumber;
  final String? notes;

  const PaymentEntity({
    required this.id,
    required this.tenantId,
    required this.clientId,
    required this.receiptNumber,
    required this.date,
    required this.amount,
    required this.method,
    this.transferReceiptNumber,
    this.notes,
  });

  /// Valida y construye un pago garantizando que el monto sea estrictamente positivo.
  static Result<PaymentEntity, DomainFailure> create({
    required String id,
    required String tenantId,
    required String clientId,
    required int receiptNumber,
    required DateTime date,
    required Money amount,
    required PaymentMethod method,
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

    if (!amount.isPositive) {
      return Result.fail(
        NegativeAmountNotAllowedFailure(
          'El importe de un pago o cobranza debe ser estrictamente mayor a cero',
          amount,
        ),
      );
    }

    if (method != PaymentMethod.cash && method != PaymentMethod.transfer) {
      return Result.fail(
        const EntityValidationFailure(
          'El método de cobranza individual debe ser efectivo o transferencia',
        ),
      );
    }

    return Result.ok(
      PaymentEntity(
        id: id.trim(),
        tenantId: tenantId.trim(),
        clientId: clientId.trim(),
        receiptNumber: receiptNumber,
        date: date.toUtc(),
        amount: amount,
        method: method,
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
    PaymentMethod? method,
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
      method: method ?? this.method,
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
        method,
        transferReceiptNumber,
        notes,
      );

  @override
  String toString() =>
      'PaymentEntity(recibo #$receiptNumber, cliente: $clientId, monto: $amount)';
}
