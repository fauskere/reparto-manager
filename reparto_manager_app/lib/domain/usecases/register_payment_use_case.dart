// lib/domain/usecases/register_payment_use_case.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/money.dart';
import '../core/result.dart';
import '../entities/client_entity.dart';
import '../entities/ledger_entry_entity.dart';
import '../entities/payment_entity.dart';
import '../repositories/i_client_repository.dart';
import '../repositories/i_ledger_repository.dart';
import '../repositories/i_payment_repository.dart';

/// Registra una cobranza (simple o mixta) con recibo correlativo, crédito contable y visita.
class RegisterPaymentUseCase {
  final IPaymentRepository _paymentRepository;
  final ILedgerRepository _ledgerRepository;
  final IClientRepository _clientRepository;

  const RegisterPaymentUseCase(
    this._paymentRepository,
    this._ledgerRepository,
    this._clientRepository,
  );

  Future<Result<PaymentEntity, DomainFailure>> execute({
    required PaymentEntity payment,
  }) async {
    final validation = _validatePayment(payment);
    if (validation.isFailure) return Result.fail(validation.failureOrNull!);

    final receiptResult = await _paymentRepository.getNextReceiptNumber(payment.tenantId);
    if (receiptResult.isFailure) return Result.fail(receiptResult.failureOrNull!);

    final confirmedPayment = payment.copyWith(receiptNumber: receiptResult.valueOrNull!);

    final saveResult = await _paymentRepository.savePayment(confirmedPayment);
    if (saveResult.isFailure) return Result.fail(saveResult.failureOrNull!);

    final ledgerEntry = LedgerEntryEntity(
      id: 'led_pay_${confirmedPayment.id}',
      tenantId: confirmedPayment.tenantId,
      clientId: confirmedPayment.clientId,
      date: confirmedPayment.date,
      type: LedgerEntryType.paymentCredit,
      referenceId: confirmedPayment.id,
      amount: confirmedPayment.amount,
      description: 'Recibo #${confirmedPayment.receiptNumber}',
    );

    final ledgerResult = await _ledgerRepository.recordEntry(ledgerEntry);
    if (ledgerResult.isFailure) return Result.fail(ledgerResult.failureOrNull!);

    await _clientRepository.updateVisitStatus(
      confirmedPayment.tenantId,
      confirmedPayment.clientId,
      VisitStatus.visited,
    );

    return Result.ok(confirmedPayment);
  }

  Result<void, DomainFailure> _validatePayment(PaymentEntity payment) {
    if (payment.tenantId.trim().isEmpty || payment.clientId.trim().isEmpty) {
      return Result.fail(const EntityValidationFailure('tenantId y clientId son obligatorios'));
    }
    if (payment.amount <= Money.zero) {
      return Result.fail(const EntityValidationFailure('El monto a cobrar debe ser mayor a 0'));
    }
    if (payment.cashPaid + payment.transferPaid != payment.amount) {
      return Result.fail(const EntityValidationFailure('Descuadre en desglose de efectivo y transferencia'));
    }
    return Result.ok(null);
  }
}
