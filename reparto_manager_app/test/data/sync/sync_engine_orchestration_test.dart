// test/data/sync/sync_engine_orchestration_test.dart
// Pruebas Unitarias - Orquestación, Mutex y Reset de Sockets
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:reparto_manager_app/data/database/app_database.dart';
import 'package:reparto_manager_app/data/models/sync_queue_model.dart';
import 'package:reparto_manager_app/data/sync/cloud_gateway.dart';
import 'package:reparto_manager_app/data/sync/sync_engine.dart';
import 'package:reparto_manager_app/data/sync/sync_lock.dart';
import 'package:reparto_manager_app/data/sync/sync_status.dart';

class MockEngineGateway implements ICloudGateway {
  bool networkResetCalled = false;
  bool shouldThrow = false;

  @override
  Future<void> pushBatch(String tenantId, List<SyncQueueModel> items) async {
    if (shouldThrow) throw Exception('Simulated network timeout');
  }

  @override
  Future<List<Map<String, dynamic>>> pullCollection(
    String tenantId,
    String collectionName, {
    DateTime? sinceUtc,
  }) async {
    if (shouldThrow) throw Exception('Simulated network timeout');
    return [];
  }

  @override
  Future<void> updateHeartbeat(String tenantId) async {}

  @override
  Future<void> resetNetwork() async {
    networkResetCalled = true;
  }

  @override
  Stream<DateTime?> listenHeartbeat(String tenantId) => const Stream.empty();
}

class FakeConnectivity implements Connectivity {
  final _controller = StreamController<List<ConnectivityResult>>.broadcast();

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _controller.stream;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [ConnectivityResult.wifi];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SyncEngine - Orquestación y Resiliencia', () {
    late AppDatabase appDb;
    late Database db;
    late MockEngineGateway mockGateway;
    late FakeConnectivity fakeConnectivity;
    late SyncLock syncLock;
    late SyncEngine engine;

    setUp(() async {
      appDb = AppDatabase();
      db = await appDb.initDatabase(inMemory: true);
      mockGateway = MockEngineGateway();
      fakeConnectivity = FakeConnectivity();
      syncLock = SyncLock();

      engine = SyncEngine(
        appDatabase: appDb,
        cloudGateway: mockGateway,
        syncLock: syncLock,
        connectivity: fakeConnectivity,
      );
    });

    tearDown(() async {
      SyncEngine.resetInstanceForTesting();
      await db.close();
      await appDb.close();
    });

    test('1. Sincronización exitosa actualiza syncStatusNotifier', () async {
      engine.initialize('tenant_demo');

      final result = await engine.syncNow();
      expect(result.isSuccess, isTrue);
      expect(syncStatusNotifier.value.state, equals(SyncState.idle));
      expect(syncStatusNotifier.value.lastResult?.isSuccess, isTrue);
    });

    test('2. forceSocketReset activa resetNetwork en cloudGateway', () async {
      engine.initialize('tenant_demo');
      expect(mockGateway.networkResetCalled, isFalse);

      await engine.syncNow(forceSocketReset: true);
      expect(mockGateway.networkResetCalled, isTrue);
    });

    test('3. Candado Mutex previene ejecuciones concurrentes simultáneas', () async {
      engine.initialize('tenant_demo');

      // Simulamos bloqueo del candado
      final future1 = syncLock.runProtected(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return SyncResult.success();
      });

      final parallelResult = await engine.syncNow();
      expect(parallelResult.isSuccess, isFalse);
      expect(parallelResult.errorMessage, contains('Sincronización en curso'));

      await future1;
    });

    test('4. Captura fallas de red sin arrojar excepciones no controladas', () async {
      mockGateway.shouldThrow = true;
      engine.initialize('tenant_demo');

      final result = await engine.syncNow();
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Simulated network timeout'));
      expect(syncStatusNotifier.value.state, equals(SyncState.error));
    });
  });
}
