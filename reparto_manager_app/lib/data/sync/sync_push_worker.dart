// lib/data/sync/sync_push_worker.dart
// Motor de Sincronización Offline-First - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../database/app_database.dart';
import '../models/sync_queue_model.dart';
import 'cloud_gateway.dart';

/// Obrero encargado de vaciar la cola local `sync_queue` hacia Firestore en lotes atómicos.
class SyncPushWorker {
  final AppDatabase _appDatabase;
  final ICloudGateway _cloudGateway;
  static const int batchSize = 50;

  SyncPushWorker({
    AppDatabase? appDatabase,
    ICloudGateway? cloudGateway,
  })  : _appDatabase = appDatabase ?? AppDatabase(),
        _cloudGateway = cloudGateway ?? FirestoreCloudGateway();

  /// Sube todos los eventos pendientes en lotes de hasta 50 y retorna el total procesado.
  Future<int> pushPendingQueue(String tenantId) async {
    final db = await _appDatabase.database;
    int totalPushed = 0;

    while (true) {
      final rows = await db.query(
        'sync_queue',
        where: 'tenantId = ? AND status = ?',
        whereArgs: [tenantId, 'pending'],
        orderBy: 'createdAtUtc ASC',
        limit: batchSize,
      );

      if (rows.isEmpty) break;

      final items = rows.map((r) => SyncQueueModel.fromMap(r)).toList();
      await _processBatch(db, tenantId, items);
      totalPushed += items.length;

      if (items.length < batchSize) break;
    }

    if (totalPushed > 0) {
      await _cloudGateway.updateHeartbeat(tenantId);
    }

    return totalPushed;
  }

  /// Procesa un lote atómico en Firestore y purga los IDs correspondientes de SQLite.
  Future<void> _processBatch(
    Database db,
    String tenantId,
    List<SyncQueueModel> items,
  ) async {
    await _cloudGateway.pushBatch(tenantId, items);

    final ids = items.map((i) => i.id).toList();
    final placeholders = List.filled(ids.length, '?').join(',');

    await db.delete(
      'sync_queue',
      where: 'tenantId = ? AND id IN ($placeholders)',
      whereArgs: [tenantId, ...ids],
    );
  }

  /// Retorna la cantidad de elementos pendientes en la cola local.
  Future<int> getPendingCount(String tenantId) async {
    final db = await _appDatabase.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM sync_queue WHERE tenantId = ? AND status = ?',
      [tenantId, 'pending'],
    );
    if (result.isEmpty) return 0;
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }
}
