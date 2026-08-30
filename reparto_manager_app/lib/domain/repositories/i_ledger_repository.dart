// lib/domain/repositories/i_ledger_repository.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/money.dart';
import '../core/result.dart';
import '../entities/ledger_entry_entity.dart';

/// Contrato abstracto para el libro mayor (Ledger) contable inmutable bajo Event Sourcing.
abstract class ILedgerRepository {
  /// Registra un asiento contable atómico en el libro mayor.
  Future<Result<void, DomainFailure>> recordEntry(LedgerEntryEntity entry);

  /// Registra múltiples asientos contables en una única transacción atómica.
  Future<Result<void, DomainFailure>> recordEntries(
    List<LedgerEntryEntity> entries,
  );

  /// Obtiene los asientos contables de un cliente paginados, opcionalmente desde una fecha.
  Future<Result<List<LedgerEntryEntity>, DomainFailure>> getEntriesByClient(
    String tenantId,
    String clientId, {
    DateTime? sinceUtc,
    int limit = 50,
    int offset = 0,
  });

  /// Retorna el saldo global consolidado de deuda circulante en la calle para el tenant.
  Future<Result<Money, DomainFailure>> getTotalOutstandingDebt(String tenantId);

  /// Obtiene el último snapshot contable consolidado para un cliente.
  Future<Result<LedgerSnapshot?, DomainFailure>> getLatestSnapshot(
    String tenantId,
    String clientId,
  );

  /// Guarda un nuevo snapshot contable para cortes y cierres periódicos.
  Future<Result<void, DomainFailure>> saveSnapshot(LedgerSnapshot snapshot);
}
