// lib/data/repositories/zone_repository_impl.dart
// Capa de Datos e Infraestructura SQLite - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../domain/core/domain_failures.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/zone_entity.dart';
import '../../domain/repositories/i_zone_repository.dart';
import '../database/app_database.dart';
import '../models/zone_model.dart';
import 'sync_queue_helper.dart';

/// Implementación local de [IZoneRepository] basada en SQLite.
class ZoneRepositoryImpl implements IZoneRepository {
  final AppDatabase _appDatabase;

  ZoneRepositoryImpl([AppDatabase? appDatabase])
      : _appDatabase = appDatabase ?? AppDatabase();

  @override
  Future<Result<List<ZoneEntity>, DomainFailure>> getZones(String tenantId) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        'zones',
        where: 'tenantId = ?',
        whereArgs: [tenantId],
        orderBy: 'name ASC',
      );

      final list = rows.map((r) => ZoneModel.fromMap(r).toEntity()).toList();
      return Result.ok(list);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al listar zonas', e));
    }
  }

  @override
  Future<Result<void, DomainFailure>> saveZone(ZoneEntity zone) async {
    try {
      final db = await _appDatabase.database;
      final model = ZoneModel.fromEntity(zone);
      final map = model.toMap();

      await db.transaction((txn) async {
        await txn.insert('zones', map, conflictAlgorithm: ConflictAlgorithm.replace);
        await SyncQueueHelper.enqueueOperation(
          executor: txn,
          tenantId: zone.tenantId,
          collectionName: 'zones',
          documentId: zone.id,
          operation: 'create',
          payload: map,
        );
      });
      return Result.ok(null);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al guardar zona', e));
    }
  }

  @override
  Future<Result<void, DomainFailure>> deleteZone(
    String tenantId,
    String zoneId,
  ) async {
    try {
      final db = await _appDatabase.database;
      await db.transaction((txn) async {
        await txn.delete(
          'zones',
          where: 'tenantId = ? AND id = ?',
          whereArgs: [tenantId, zoneId],
        );
        await SyncQueueHelper.enqueueOperation(
          executor: txn,
          tenantId: tenantId,
          collectionName: 'zones',
          documentId: zoneId,
          operation: 'delete',
          payload: {'id': zoneId, 'tenantId': tenantId},
        );
      });
      return Result.ok(null);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al eliminar zona', e));
    }
  }
}
