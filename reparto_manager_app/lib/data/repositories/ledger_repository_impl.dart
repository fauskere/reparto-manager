// lib/data/repositories/ledger_repository_impl.dart
// Capa de Datos e Infraestructura SQLite - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../domain/core/domain_failures.dart';
import '../../domain/core/money.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/ledger_entry_entity.dart';
import '../../domain/repositories/i_ledger_repository.dart';
import '../database/app_database.dart';
import '../models/ledger_entry_model.dart';
import 'sync_queue_helper.dart';

/// Implementación local de [ILedgerRepository] basada en SQLite.
class LedgerRepositoryImpl implements ILedgerRepository {
  final AppDatabase _appDatabase;

  LedgerRepositoryImpl([AppDatabase? appDatabase])
      : _appDatabase = appDatabase ?? AppDatabase();

  @override
  Future<Result<void, DomainFailure>> recordEntry(LedgerEntryEntity entry) async {
    return recordEntries([entry]);
  }

  @override
  Future<Result<void, DomainFailure>> recordEntries(
    List<LedgerEntryEntity> entries,
  ) async {
    if (entries.isEmpty) return Result.ok(null);

    try {
      final db = await _appDatabase.database;
      await db.transaction((txn) async {
        for (final entry in entries) {
          final model = LedgerEntryModel.fromEntity(entry);
          final map = model.toMap();

          await txn.insert('ledger_entries', map, conflictAlgorithm: ConflictAlgorithm.replace);
          await SyncQueueHelper.enqueueOperation(
            executor: txn,
            tenantId: entry.tenantId,
            collectionName: 'ledger_entries',
            documentId: entry.id,
            operation: 'create',
            payload: map,
          );
        }
      });
      return Result.ok(null);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al registrar asientos contables', e));
    }
  }

  @override
  Future<Result<List<LedgerEntryEntity>, DomainFailure>> getEntriesByClient(
    String tenantId,
    String clientId, {
    DateTime? sinceUtc,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final db = await _appDatabase.database;
      final String whereClause;
      final List<dynamic> whereArgs;

      if (sinceUtc != null) {
        whereClause = 'tenantId = ? AND clientId = ? AND dateUtc > ?';
        whereArgs = [tenantId, clientId, sinceUtc.toUtc().toIso8601String()];
      } else {
        whereClause = 'tenantId = ? AND clientId = ?';
        whereArgs = [tenantId, clientId];
      }

      final rows = await db.query(
        'ledger_entries',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'dateUtc ASC',
        limit: limit,
        offset: offset,
      );

      final list = rows.map((r) => LedgerEntryModel.fromMap(r).toEntity()).toList();
      return Result.ok(list);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al consultar asientos de cliente', e));
    }
  }

  @override
  Future<Result<Money, DomainFailure>> getTotalOutstandingDebt(String tenantId) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.rawQuery(
        'SELECT COALESCE(SUM(balanceImpactCents), 0) AS totalDebt FROM ledger_entries WHERE tenantId = ?',
        [tenantId],
      );

      final totalCents = (rows.first['totalDebt'] as num).toInt();
      return Result.ok(Money.fromCents(totalCents));
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al calcular deuda circulante global', e));
    }
  }

  @override
  Future<Result<LedgerSnapshot?, DomainFailure>> getLatestSnapshot(
    String tenantId,
    String clientId,
  ) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        'ledger_snapshots',
        where: 'tenantId = ? AND clientId = ?',
        whereArgs: [tenantId, clientId],
        orderBy: 'dateUtc DESC',
        limit: 1,
      );

      if (rows.isEmpty) {
        return Result.ok(null);
      }

      return Result.ok(LedgerSnapshotModel.fromMap(rows.first).toEntity());
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al obtener último snapshot contable', e));
    }
  }

  @override
  Future<Result<void, DomainFailure>> saveSnapshot(LedgerSnapshot snapshot) async {
    try {
      final db = await _appDatabase.database;
      final model = LedgerSnapshotModel.fromEntity(snapshot);
      final map = model.toMap();

      await db.transaction((txn) async {
        await txn.insert('ledger_snapshots', map, conflictAlgorithm: ConflictAlgorithm.replace);
        await SyncQueueHelper.enqueueOperation(
          executor: txn,
          tenantId: snapshot.tenantId,
          collectionName: 'ledger_snapshots',
          documentId: snapshot.lastEntryId,
          operation: 'create',
          payload: map,
        );
      });
      return Result.ok(null);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al guardar snapshot contable', e));
    }
  }
}
