// lib/domain/entities/ledger_entry_entity.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/money.dart';
import '../core/result.dart';

/// Tipo de asiento contable inmutable bajo el patrón Event Sourcing.
enum LedgerEntryType {
  /// Deuda originada por venta o entrega de mercadería al cliente (+ saldo).
  saleDebt,

  /// Pago, cobranza o entrega de dinero efectuada por el cliente (- saldo).
  paymentCredit,

  /// Nota de crédito o bonificación a favor del cliente (- saldo).
  adjustmentCredit,

  /// Cargo adicional, interés o ajuste deudor imputado al cliente (+ saldo).
  adjustmentDebt,
}

/// Entidad inmutable que representa un asiento contable atómico en el libro mayor.
///
/// Cumple con los principios de Event Sourcing de Stripe y Martin Fowler:
/// cada movimiento queda registrado de forma inalterable y auditable.
class LedgerEntryEntity {
  /// Identificador único universal del asiento contable.
  final String id;

  /// Identificador del tenant/usuario para particionado estricto multi-tenancy.
  final String tenantId;

  /// Identificador del cliente al que pertenece el movimiento.
  final String clientId;

  /// Marca de tiempo exacta del movimiento en UTC.
  final DateTime date;

  /// Naturaleza contable del movimiento.
  final LedgerEntryType type;

  /// Identificador del comprobante, ticket de venta o recibo asociado.
  final String referenceId;

  /// Monto positivo inmutable de la transacción.
  final Money amount;

  /// Descripción o detalle auditado del asiento.
  final String description;

  const LedgerEntryEntity({
    required this.id,
    required this.tenantId,
    required this.clientId,
    required this.date,
    required this.type,
    required this.referenceId,
    required this.amount,
    required this.description,
  });

  /// Crea un asiento contable validando que el monto no sea negativo.
  static Result<LedgerEntryEntity, DomainFailure> create({
    required String id,
    required String tenantId,
    required String clientId,
    required DateTime date,
    required LedgerEntryType type,
    required String referenceId,
    required Money amount,
    required String description,
  }) {
    if (amount.isNegative) {
      return Result.fail(
        NegativeAmountNotAllowedFailure(
          'El monto de un asiento contable no puede ser negativo',
          amount,
        ),
      );
    }
    if (id.isEmpty || tenantId.isEmpty || clientId.isEmpty) {
      return Result.fail(
        const InvalidMoneyAmountFailure(
          'Los identificadores de asiento, tenant y cliente son obligatorios',
        ),
      );
    }

    return Result.ok(
      LedgerEntryEntity(
        id: id,
        tenantId: tenantId,
        clientId: clientId,
        date: date.toUtc(),
        type: type,
        referenceId: referenceId,
        amount: amount,
        description: description,
      ),
    );
  }

  /// Retorna el impacto neto firmado sobre el saldo de deuda del cliente.
  ///
  /// Saldo = Suma(Deudas) - Suma(Pagos)
  /// - Deudas (+): aumentan lo que el cliente le debe al reparto.
  /// - Créditos (-): disminuyen la deuda del cliente.
  Money get balanceImpact {
    switch (type) {
      case LedgerEntryType.saleDebt:
      case LedgerEntryType.adjustmentDebt:
        return amount;
      case LedgerEntryType.paymentCredit:
      case LedgerEntryType.adjustmentCredit:
        return -amount;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerEntryEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tenantId == other.tenantId &&
          clientId == other.clientId &&
          date == other.date &&
          type == other.type &&
          referenceId == other.referenceId &&
          amount == other.amount &&
          description == other.description;

  @override
  int get hashCode => Object.hash(
        runtimeType,
        id,
        tenantId,
        clientId,
        date,
        type,
        referenceId,
        amount,
        description,
      );

  @override
  String toString() =>
      'LedgerEntry($type, amount: $amount, ref: $referenceId, date: $date)';
}

/// Snapshot contable inmutable para cierres periódicos (Ledger Sharding).
///
/// Permite consolidar balances a una fecha fija para que las consultas de saldo
/// se resuelvan en O(1) + eventos delta recientes, sin procesar años de historia.
class LedgerSnapshot {
  /// Identificador del tenant para aislamiento de datos.
  final String tenantId;

  /// Identificador del cliente.
  final String clientId;

  /// Fecha y hora UTC del corte contable.
  final DateTime closingDate;

  /// Saldo matemático consolidado a la fecha de corte.
  final Money balance;

  /// Identificador del último asiento incluido en este snapshot.
  final String lastEntryId;

  /// Cantidad total de asientos consolidados en este snapshot.
  final int entryCount;

  const LedgerSnapshot({
    required this.tenantId,
    required this.clientId,
    required this.closingDate,
    required this.balance,
    required this.lastEntryId,
    required this.entryCount,
  });

  /// Calcula el saldo exacto combinando este snapshot con los asientos posteriores.
  Money computeBalanceWithEntries(Iterable<LedgerEntryEntity> subsequentEntries) {
    var currentBalance = balance;
    for (final entry in subsequentEntries) {
      currentBalance = currentBalance + entry.balanceImpact;
    }
    return currentBalance;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerSnapshot &&
          runtimeType == other.runtimeType &&
          tenantId == other.tenantId &&
          clientId == other.clientId &&
          closingDate == other.closingDate &&
          balance == other.balance &&
          lastEntryId == other.lastEntryId &&
          entryCount == other.entryCount;

  @override
  int get hashCode => Object.hash(
        runtimeType,
        tenantId,
        clientId,
        closingDate,
        balance,
        lastEntryId,
        entryCount,
      );

  @override
  String toString() =>
      'LedgerSnapshot(client: $clientId, balance: $balance, closing: $closingDate, count: $entryCount)';
}
