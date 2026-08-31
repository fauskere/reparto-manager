// lib/data/repositories/truck_repository_impl.dart
// Capa de Datos e Infraestructura SQLite - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../domain/core/domain_failures.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/truck_load_entity.dart';
import '../../domain/repositories/i_truck_repository.dart';
import '../database/app_database.dart';
import '../models/truck_load_model.dart';
import 'sync_queue_helper.dart';

/// Implementación local de [ITruckRepository] basada en SQLite.
class TruckRepositoryImpl implements ITruckRepository {
  final AppDatabase _appDatabase;

  TruckRepositoryImpl([AppDatabase? appDatabase])
      : _appDatabase = appDatabase ?? AppDatabase();

  @override
  Future<Result<TruckLoadEntity, DomainFailure>> getTodayTruckLoad(
    String tenantId,
    String truckId,
    DateTime dateUtc,
  ) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        'truck_loads',
        where: 'tenantId = ? AND truckId = ?',
        whereArgs: [tenantId, truckId],
        limit: 1,
      );

      if (rows.isEmpty) {
        return Result.ok(
          TruckLoadEntity(
            truckId: truckId,
            tenantId: tenantId,
            date: dateUtc.toUtc(),
            inventory: const {},
            damagedItems: const {},
          ),
        );
      }

      return Result.ok(TruckLoadModel.fromMap(rows.first).toEntity());
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al obtener carga del camión', e));
    }
  }

  @override
  Future<Result<void, DomainFailure>> saveTruckLoad(TruckLoadEntity truckLoad) async {
    try {
      final db = await _appDatabase.database;
      final model = TruckLoadModel.fromEntity(truckLoad);
      final map = model.toMap();

      await db.transaction((txn) async {
        await txn.insert('truck_loads', map, conflictAlgorithm: ConflictAlgorithm.replace);
        await SyncQueueHelper.enqueueOperation(
          executor: txn,
          tenantId: truckLoad.tenantId,
          collectionName: 'truck_loads',
          documentId: truckLoad.truckId,
          operation: 'create',
          payload: map,
        );
      });
      return Result.ok(null);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al guardar carga de camión', e));
    }
  }

  @override
  Future<Result<void, DomainFailure>> applyStockDelta(
    String tenantId,
    String truckId,
    Map<String, int> deltas,
  ) async {
    try {
      final db = await _appDatabase.database;
      await db.transaction((txn) async {
        final rows = await txn.query(
          'truck_loads',
          where: 'tenantId = ? AND truckId = ?',
          whereArgs: [tenantId, truckId],
          limit: 1,
        );

        final TruckLoadEntity current;
        if (rows.isEmpty) {
          current = TruckLoadEntity(
            truckId: truckId,
            tenantId: tenantId,
            date: DateTime.now().toUtc(),
            inventory: const {},
            damagedItems: const {},
          );
        } else {
          current = TruckLoadModel.fromMap(rows.first).toEntity();
        }

        final updatedInventory = Map<String, int>.from(current.inventory);
        deltas.forEach((variantKey, delta) {
          final existingQty = updatedInventory[variantKey] ?? 0;
          updatedInventory[variantKey] = existingQty + delta;
        });

        final updatedLoad = current.copyWith(inventory: updatedInventory);
        final map = TruckLoadModel.fromEntity(updatedLoad).toMap();

        await txn.insert('truck_loads', map, conflictAlgorithm: ConflictAlgorithm.replace);
        await SyncQueueHelper.enqueueOperation(
          executor: txn,
          tenantId: tenantId,
          collectionName: 'truck_loads',
          documentId: truckId,
          operation: 'update',
          payload: map,
        );
      });
      return Result.ok(null);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al aplicar deltas de stock', e));
    }
  }
}
