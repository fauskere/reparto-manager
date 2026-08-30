// lib/domain/usecases/generate_ledger_snapshot_use_case.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/money.dart';
import '../core/result.dart';
import '../entities/ledger_entry_entity.dart';
import '../repositories/i_ledger_repository.dart';

/// Consolida los asientos contables de un cliente en un snapshot periódico.
///
/// Permite consultas de saldos en tiempo constante O(1) sin recorrer años de historia (Regla 11).
class GenerateLedgerSnapshotUseCase {
  final ILedgerRepository _ledgerRepository;

  const GenerateLedgerSnapshotUseCase(this._ledgerRepository);

  Future<Result<LedgerSnapshot, DomainFailure>> execute({
    required String tenantId,
    required String clientId,
    required DateTime closingDateUtc,
  }) async {
    if (tenantId.trim().isEmpty || clientId.trim().isEmpty) {
      return Result.fail(const EntityValidationFailure('tenantId y clientId son obligatorios'));
    }

    final prevSnapshotRes = await _ledgerRepository.getLatestSnapshot(tenantId, clientId);
    if (prevSnapshotRes.isFailure) return Result.fail(prevSnapshotRes.failureOrNull!);

    final prevSnapshot = prevSnapshotRes.valueOrNull;
    final initialBalance = prevSnapshot?.balance ?? Money.zero;
    final sinceUtc = prevSnapshot?.closingDate;
    final prevCount = prevSnapshot?.entryCount ?? 0;

    final entriesRes = await _ledgerRepository.getEntriesByClient(
      tenantId,
      clientId,
      sinceUtc: sinceUtc,
      limit: 100000,
    );
    if (entriesRes.isFailure) return Result.fail(entriesRes.failureOrNull!);

    final entries = entriesRes.valueOrNull!;
    var consolidatedBalance = initialBalance;
    var lastId = prevSnapshot?.lastEntryId ?? '';
    var newEntriesCount = 0;

    for (final entry in entries) {
      if (!entry.date.isAfter(closingDateUtc)) {
        consolidatedBalance = consolidatedBalance + entry.balanceImpact;
        lastId = entry.id;
        newEntriesCount++;
      }
    }

    final newSnapshot = LedgerSnapshot(
      tenantId: tenantId,
      clientId: clientId,
      closingDate: closingDateUtc,
      balance: consolidatedBalance,
      lastEntryId: lastId,
      entryCount: prevCount + newEntriesCount,
    );

    final saveResult = await _ledgerRepository.saveSnapshot(newSnapshot);
    if (saveResult.isFailure) return Result.fail(saveResult.failureOrNull!);

    return Result.ok(newSnapshot);
  }
}
