// lib/domain/usecases/record_manual_adjustment_use_case.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/money.dart';
import '../core/result.dart';
import '../entities/ledger_entry_entity.dart';
import '../repositories/i_ledger_repository.dart';

/// Registra ajustes contables debidamente auditados (saldos iniciales de libreta o notas de crédito/débito).
///
/// Cumple con la REGLA 9: Nunca se sobreescribe el saldo; se asienta la justificación contable.
class RecordManualAdjustmentUseCase {
  final ILedgerRepository _ledgerRepository;

  const RecordManualAdjustmentUseCase(this._ledgerRepository);

  Future<Result<LedgerEntryEntity, DomainFailure>> execute({
    required String tenantId,
    required String clientId,
    required Money amount,
    required bool isCredit,
    required String reason,
  }) async {
    if (tenantId.trim().isEmpty || clientId.trim().isEmpty) {
      return Result.fail(const EntityValidationFailure('tenantId y clientId son obligatorios'));
    }
    if (amount <= Money.zero) {
      return Result.fail(const EntityValidationFailure('El monto del ajuste debe ser mayor a 0'));
    }
    if (reason.trim().isEmpty) {
      return Result.fail(const EntityValidationFailure('El motivo o justificación del ajuste es obligatorio'));
    }

    final entry = LedgerEntryEntity(
      id: 'led_adj_${DateTime.now().millisecondsSinceEpoch}',
      tenantId: tenantId,
      clientId: clientId,
      date: DateTime.now().toUtc(),
      type: isCredit ? LedgerEntryType.adjustmentCredit : LedgerEntryType.adjustmentDebt,
      referenceId: 'MANUAL_ADJUSTMENT',
      amount: amount,
      description: reason.trim(),
    );

    final recordResult = await _ledgerRepository.recordEntry(entry);
    if (recordResult.isFailure) return Result.fail(recordResult.failureOrNull!);

    return Result.ok(entry);
  }
}
