// test/data/sync/sync_push_worker_test.dart
// Pruebas Unitarias - SyncPushWorker con Lotes, Tombstones y Purga
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:reparto_manager_app/data/database/app_database.dart';
import 'package:reparto_manager_app/data/models/sync_queue_model.dart';
import 'package:reparto_manager_app/data/repositories/sync_queue_helper.dart';
import 'package:reparto_manager_app/data/sync/cloud_gateway.dart';
import 'package:reparto_manager_app/data/sync/sync_push_worker.dart';

class FakeCloudGateway implements ICloudGateway {
  final List<SyncQueueModel> pushedItems = [];
  bool heartbeatUpdated = false;

  @override
  Future<void> pushBatch(String tenantId, List<SyncQueueModel> items) async {
    pushedItems.addAll(items);
  }

  @override
  Future<List<Map<String, dynamic>>> pullCollection(
    String tenantId,
    String collectionName, {
    DateTime? sinceUtc,
  }) async => [];

  @override
  Future<void> updateHeartbeat(String tenantId) async {
    heartbeatUpdated = true;
  }

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

  group('SyncPushWorker - SQLite a Nube', () {
    late AppDatabase appDb;
    late Database db;
    late FakeCloudGateway fakeGateway;
    late SyncPushWorker pushWorker;

    setUp(() async {
      appDb = AppDatabase();
      db = await appDb.initDatabase(inMemory: true);
      fakeGateway = FakeCloudGateway();
      pushWorker = SyncPushWorker(appDatabase: appDb, cloudGateway: fakeGateway);
    });

    tearDown(() async {
      await db.close();
      await appDb.close();
    });

    test('1. Sube operaciones pendientes y purga sync_queue de SQLite', () async {
      await SyncQueueHelper.enqueueOperation(
        executor: db,
        tenantId: 't1',
        collectionName: 'clients',
        documentId: 'cli_10',
        operation: 'create',
        payload: {'id': 'cli_10', 'name': 'Kiosco Central'},
      );

      final initialPending = await pushWorker.getPendingCount('t1');
      expect(initialPending, equals(1));

      final pushed = await pushWorker.pushPendingQueue('t1');
      expect(pushed, equals(1));
      expect(fakeGateway.pushedItems.length, equals(1));
      expect(fakeGateway.pushedItems.first.documentId, equals('cli_10'));
      expect(fakeGateway.heartbeatUpdated, isTrue);

      final finalPending = await pushWorker.getPendingCount('t1');
      expect(finalPending, equals(0));
    });

    test('2. Procesa operaciones DELETE con tombstones', () async {
      await SyncQueueHelper.enqueueOperation(
        executor: db,
        tenantId: 't1',
        collectionName: 'products',
        documentId: 'prod_99',
        operation: 'delete',
        payload: {'id': 'prod_99'},
      );

      await pushWorker.pushPendingQueue('t1');
      expect(fakeGateway.pushedItems.length, equals(1));
      expect(fakeGateway.pushedItems.first.operation, equals('delete'));
    });

    test('3. Procesa lotes grandes respetando batchSize', () async {
      for (int i = 0; i < 55; i++) {
        await SyncQueueHelper.enqueueOperation(
          executor: db,
          tenantId: 't1',
          collectionName: 'sales',
          documentId: 'sale_$i',
          operation: 'create',
          payload: {'id': 'sale_$i', 'total': 1000},
        );
      }

      final countBefore = await pushWorker.getPendingCount('t1');
      expect(countBefore, equals(55));

      final pushed = await pushWorker.pushPendingQueue('t1');
      expect(pushed, equals(55));
      expect(fakeGateway.pushedItems.length, equals(55));

      final countAfter = await pushWorker.getPendingCount('t1');
      expect(countAfter, equals(0));
    });
  });
}
