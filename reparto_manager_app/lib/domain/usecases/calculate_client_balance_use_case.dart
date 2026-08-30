// lib/domain/usecases/calculate_client_balance_use_case.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/money.dart';
import '../core/result.dart';
import '../repositories/i_ledger_repository.dart';

/// Calcula el saldo exacto de cuenta corriente de un cliente a partir del libro mayor contable.
///
/// Cumple con la REGLA 9 ESTRICTA: El saldo jamás se asigna manualmente, sino que se
/// deduce matemáticamente desde el último LedgerSnapshot periódico más los asientos posteriores.
class CalculateClientBalanceUseCase {
  final ILedgerRepository _ledgerRepository;

  const CalculateClientBalanceUseCase(this._ledgerRepository);

  Future<Result<Money, DomainFailure>> execute({
    required String tenantId,
    required String clientId,
  }) async {
    if (tenantId.trim().isEmpty || clientId.trim().isEmpty) {
      return Result.fail(const EntityValidationFailure('tenantId y clientId son obligatorios'));
    }

    final snapshotResult = await _ledgerRepository.getLatestSnapshot(tenantId, clientId);
    if (snapshotResult.isFailure) {
      return Result.fail(snapshotResult.failureOrNull!);
    }

    final snapshot = snapshotResult.valueOrNull;
    final initialBalance = snapshot?.balance ?? Money.zero;
    final sinceUtc = snapshot?.closingDate;

    final entriesResult = await _ledgerRepository.getEntriesByClient(
      tenantId,
      clientId,
      sinceUtc: sinceUtc,
      limit: 100000,
    );
    if (entriesResult.isFailure) {
      return Result.fail(entriesResult.failureOrNull!);
    }

    final entries = entriesResult.valueOrNull!;
    var currentBalance = initialBalance;

    for (final entry in entries) {
      currentBalance = currentBalance + entry.balanceImpact;
    }

    return Result.ok(currentBalance);
  }
}
