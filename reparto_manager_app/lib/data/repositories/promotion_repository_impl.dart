// lib/data/repositories/promotion_repository_impl.dart
// Capa de Datos e Infraestructura SQLite - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../domain/core/domain_failures.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/promotion_entity.dart';
import '../../domain/repositories/i_promotion_repository.dart';
import '../database/app_database.dart';
import '../models/promotion_model.dart';
import 'sync_queue_helper.dart';

/// Implementación local de [IPromotionRepository] basada en SQLite.
class PromotionRepositoryImpl implements IPromotionRepository {
  final AppDatabase _appDatabase;

  PromotionRepositoryImpl([AppDatabase? appDatabase])
      : _appDatabase = appDatabase ?? AppDatabase();

  @override
  Future<Result<List<PromotionEntity>, DomainFailure>> getActivePromotions(
    String tenantId,
  ) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        'promotions',
        where: 'tenantId = ? AND isActive = 1',
        whereArgs: [tenantId],
        orderBy: 'name ASC',
      );

      final list = rows.map((r) => PromotionModel.fromMap(r).toEntity()).toList();
      return Result.ok(list);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al listar promociones activas', e));
    }
  }

  @override
  Future<Result<void, DomainFailure>> savePromotion(PromotionEntity promotion) async {
    try {
      final db = await _appDatabase.database;
      final model = PromotionModel.fromEntity(promotion);
      final map = model.toMap();

      await db.transaction((txn) async {
        await txn.insert('promotions', map, conflictAlgorithm: ConflictAlgorithm.replace);
        await SyncQueueHelper.enqueueOperation(
          executor: txn,
          tenantId: promotion.tenantId,
          collectionName: 'promotions',
          documentId: promotion.id,
          operation: 'create',
          payload: map,
        );
      });
      return Result.ok(null);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al guardar promoción', e));
    }
  }

  @override
  Future<Result<void, DomainFailure>> deletePromotion(
    String tenantId,
    String promotionId,
  ) async {
    try {
      final db = await _appDatabase.database;
      await db.transaction((txn) async {
        await txn.update(
          'promotions',
          {'isActive': 0},
          where: 'tenantId = ? AND id = ?',
          whereArgs: [tenantId, promotionId],
        );
        await SyncQueueHelper.enqueueOperation(
          executor: txn,
          tenantId: tenantId,
          collectionName: 'promotions',
          documentId: promotionId,
          operation: 'delete',
          payload: {'id': promotionId, 'isActive': 0},
        );
      });
      return Result.ok(null);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al eliminar promoción', e));
    }
  }
}
