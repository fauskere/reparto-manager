// lib/domain/usecases/cancel_payment_use_case.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/money.dart';
import '../core/result.dart';
import '../entities/ledger_entry_entity.dart';
import '../repositories/i_ledger_repository.dart';
import '../repositories/i_payment_repository.dart';

/// Anula un cobro erróneo y emite un contra-asiento de débito en el libro mayor.
class CancelPaymentUseCase {
  final IPaymentRepository _paymentRepository;
  final ILedgerRepository _ledgerRepository;

  const CancelPaymentUseCase(
    this._paymentRepository,
    this._ledgerRepository,
  );

  Future<Result<void, DomainFailure>> execute({
    required String tenantId,
    required String paymentId,
    required String clientId,
    required Money paymentAmount,
    required String reason,
  }) async {
    if (tenantId.trim().isEmpty || paymentId.trim().isEmpty || clientId.trim().isEmpty) {
      return Result.fail(const EntityValidationFailure('tenantId, paymentId y clientId son obligatorios'));
    }
    if (reason.trim().isEmpty) {
      return Result.fail(const EntityValidationFailure('El motivo de anulación es obligatorio'));
    }
    if (paymentAmount <= Money.zero) {
      return Result.fail(const EntityValidationFailure('El monto a anular debe ser mayor a 0'));
    }

    final cancelResult = await _paymentRepository.cancelPayment(tenantId, paymentId, reason);
    if (cancelResult.isFailure) return Result.fail(cancelResult.failureOrNull!);

    final contraEntry = LedgerEntryEntity(
      id: 'led_cancel_pay_${paymentId}_${DateTime.now().millisecondsSinceEpoch}',
      tenantId: tenantId,
      clientId: clientId,
      date: DateTime.now().toUtc(),
      type: LedgerEntryType.adjustmentDebt,
      referenceId: paymentId,
      amount: paymentAmount,
      description: 'Anulación de Cobro $paymentId: $reason',
    );

    return _ledgerRepository.recordEntry(contraEntry);
  }
}
