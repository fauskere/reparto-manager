// lib/data/sync/sync_pull_worker.dart
// Motor de Sincronización Offline-First - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../database/app_database.dart';
import 'cloud_gateway.dart';

/// Obrero de bajada que sincroniza desde Firestore a SQLite con Source.server y tombstones.
class SyncPullWorker {
  final AppDatabase _appDatabase;
  final ICloudGateway _cloudGateway;

  static const List<String> pullCollections = [
    'zones',
    'promotions',
    'products',
    'clients',
    'truck_loads',
    'client_groups',
    'group_invoices',
    'sales',
    'payments',
    'ledger_snapshots',
    'ledger_entries',
  ];

  SyncPullWorker({
    AppDatabase? appDatabase,
    ICloudGateway? cloudGateway,
  })  : _appDatabase = appDatabase ?? AppDatabase(),
        _cloudGateway = cloudGateway ?? FirestoreCloudGateway();

  /// Ejecuta la bajada incremental o bootstrap de todas las colecciones y retorna el total descargado.
  Future<int> pullDeltaUpdates(String tenantId, {bool forceFull = false}) async {
    final db = await _appDatabase.database;
    int totalPulled = 0;

    for (final collection in pullCollections) {
      final lastSyncUtc = forceFull ? null : await _getLastSyncUtc(db, tenantId, collection);
      final remoteDocs = await _cloudGateway.pullCollection(
        tenantId,
        collection,
        sinceUtc: lastSyncUtc,
      );

      if (remoteDocs.isNotEmpty) {
        await _applyDocsToLocalDb(db, tenantId, collection, remoteDocs);
        totalPulled += remoteDocs.length;
      }

      await _setLastSyncUtc(db, tenantId, collection, DateTime.now().toUtc());
    }

    return totalPulled;
  }

  /// Aplica los documentos descargados procesando tombstones (DELETE) o upserts en SQLite.
  Future<void> _applyDocsToLocalDb(
    Database db,
    String tenantId,
    String table,
    List<Map<String, dynamic>> docs,
  ) async {
    await db.transaction((txn) async {
      for (final doc in docs) {
        final docId = doc['id']?.toString() ?? '';
        final isDeleted = doc['isDeleted'] == true;

        if (isDeleted) {
          await txn.delete(
            table,
            where: 'tenantId = ? AND id = ?',
            whereArgs: [tenantId, docId],
          );
        } else {
          final localMap = Map<String, dynamic>.from(doc);
          localMap.remove('updatedAtUtc');
          localMap.remove('isDeleted');
          localMap.remove('deletedAtUtc');
          localMap['tenantId'] = tenantId;

          await txn.insert(table, localMap, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }

  /// Consulta la marca temporal de la última sincronización para una colección.
  Future<DateTime?> _getLastSyncUtc(Database db, String tenantId, String collection) async {
    final key = 'last_sync_$collection';
    final rows = await db.query(
      'app_settings',
      where: 'tenantId = ? AND key = ?',
      whereArgs: [tenantId, key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final val = rows.first['value'] as String?;
    return val != null ? DateTime.tryParse(val) : null;
  }

  /// Almacena la marca temporal de la última sincronización en app_settings.
  Future<void> _setLastSyncUtc(
    Database db,
    String tenantId,
    String collection,
    DateTime syncUtc,
  ) async {
    final key = 'last_sync_$collection';
    await db.insert(
      'app_settings',
      {
        'tenantId': tenantId,
        'key': key,
        'value': syncUtc.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Limpia las marcas de sincronización para forzar un re-sync completo.
  Future<void> forceFullResync(String tenantId) async {
    final db = await _appDatabase.database;
    await db.delete(
      'app_settings',
      where: 'tenantId = ? AND key LIKE ?',
      whereArgs: [tenantId, 'last_sync_%'],
    );
  }
}
