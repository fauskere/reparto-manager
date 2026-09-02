// test/data/sync/sync_pull_worker_test.dart
// Pruebas Unitarias - SyncPullWorker con Bootstrap, Deltas y Tombstones
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:reparto_manager_app/data/database/app_database.dart';
import 'package:reparto_manager_app/data/models/sync_queue_model.dart';
import 'package:reparto_manager_app/data/sync/cloud_gateway.dart';
import 'package:reparto_manager_app/data/sync/sync_pull_worker.dart';

class MockPullGateway implements ICloudGateway {
  final Map<String, List<Map<String, dynamic>>> remoteCollections = {};
  DateTime? lastQueriedSince;

  @override
  Future<void> pushBatch(String tenantId, List<SyncQueueModel> items) async {}

  @override
  Future<List<Map<String, dynamic>>> pullCollection(
    String tenantId,
    String collectionName, {
    DateTime? sinceUtc,
  }) async {
    lastQueriedSince = sinceUtc;
    return remoteCollections[collectionName] ?? [];
  }

  @override
  Future<void> updateHeartbeat(String tenantId) async {}

  @override
  Future<void> resetNetwork() async {}

  @override
  Stream<DateTime?> listenHeartbeat(String tenantId) => const Stream.empty();
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SyncPullWorker - Nube a SQLite', () {
    late AppDatabase appDb;
    late Database db;
    late MockPullGateway mockGateway;
    late SyncPullWorker pullWorker;

    setUp(() async {
      appDb = AppDatabase();
      db = await appDb.initDatabase(inMemory: true);
      mockGateway = MockPullGateway();
      pullWorker = SyncPullWorker(appDatabase: appDb, cloudGateway: mockGateway);
    });

    tearDown(() async {
      await db.close();
      await appDb.close();
    });

    test('1. Bootstrap Inicial: inserta registros remotos en SQLite', () async {
      mockGateway.remoteCollections['zones'] = [
        {'id': 'z_norte', 'name': 'Zona Norte', 'citiesJson': '["Santa Fe"]'},
      ];

      final pulledCount = await pullWorker.pullDeltaUpdates('tenant_test');
      expect(pulledCount, equals(1));

      final rows = await db.query('zones', where: 'tenantId = ?', whereArgs: ['tenant_test']);
      expect(rows.length, equals(1));
      expect(rows.first['name'], equals('Zona Norte'));

      final settings = await db.query('app_settings', where: 'key = ?', whereArgs: ['last_sync_zones']);
      expect(settings.isNotEmpty, isTrue);
    });

    test('2. Modo Delta Incremental: consulta con fecha previa', () async {
      await pullWorker.pullDeltaUpdates('tenant_test');
      expect(mockGateway.lastQueriedSince, isNull);

      await pullWorker.pullDeltaUpdates('tenant_test');
      expect(mockGateway.lastQueriedSince, isNotNull);
    });

    test('3. Tombstone Replication: elimina físicamente en SQLite', () async {
      await db.insert('zones', {
        'id': 'z_sur',
        'tenantId': 'tenant_test',
        'name': 'Zona Sur',
        'citiesJson': '[]',
      });

      mockGateway.remoteCollections['zones'] = [
        {'id': 'z_sur', 'isDeleted': true},
      ];

      final pulledCount = await pullWorker.pullDeltaUpdates('tenant_test');
      expect(pulledCount, equals(1));

      final rows = await db.query('zones', where: 'id = ?', whereArgs: ['z_sur']);
      expect(rows, isEmpty);
    });

    test('4. forceFullResync: limpia marcas de tiempo en app_settings', () async {
      await pullWorker.pullDeltaUpdates('tenant_test');
      var settings = await db.query('app_settings', where: 'key LIKE ?', whereArgs: ['last_sync_%']);
      expect(settings.isNotEmpty, isTrue);

      await pullWorker.forceFullResync('tenant_test');
      settings = await db.query('app_settings', where: 'key LIKE ?', whereArgs: ['last_sync_%']);
      expect(settings, isEmpty);
    });
  });
}
