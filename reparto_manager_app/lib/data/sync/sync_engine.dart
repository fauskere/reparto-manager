// lib/data/sync/sync_engine.dart
// Motor de Sincronización Offline-First - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import '../database/app_database.dart';
import 'cloud_gateway.dart';
import 'sync_lock.dart';
import 'sync_pull_worker.dart';
import 'sync_push_worker.dart';
import 'sync_status.dart';

/// Orquestador central de sincronización bidireccional offline-first.
class SyncEngine {
  static SyncEngine? _instance;
  final AppDatabase _appDatabase;
  final ICloudGateway _cloudGateway;
  final SyncLock _syncLock;
  final Connectivity _connectivity;

  late final SyncPushWorker _pushWorker;
  late final SyncPullWorker _pullWorker;

  String? _currentTenantId;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<DateTime?>? _heartbeatSubscription;
  AppLifecycleListener? _lifecycleListener;

  SyncEngine._internal({
    AppDatabase? appDatabase,
    ICloudGateway? cloudGateway,
    SyncLock? syncLock,
    Connectivity? connectivity,
  })  : _appDatabase = appDatabase ?? AppDatabase(),
        _cloudGateway = cloudGateway ?? FirestoreCloudGateway(),
        _syncLock = syncLock ?? SyncLock(),
        _connectivity = connectivity ?? Connectivity() {
    _pushWorker = SyncPushWorker(appDatabase: _appDatabase, cloudGateway: _cloudGateway);
    _pullWorker = SyncPullWorker(appDatabase: _appDatabase, cloudGateway: _cloudGateway);
  }

  factory SyncEngine({
    AppDatabase? appDatabase,
    ICloudGateway? cloudGateway,
    SyncLock? syncLock,
    Connectivity? connectivity,
  }) {
    _instance ??= SyncEngine._internal(
      appDatabase: appDatabase,
      cloudGateway: cloudGateway,
      syncLock: syncLock,
      connectivity: connectivity,
    );
    return _instance!;
  }

  /// Inicializa listeners reactivos de red, ciclo de vida y latidos en la nube.
  void initialize(String tenantId, {bool triggerInitialSync = false}) {
    _currentTenantId = tenantId;
    _setupConnectivityListener();
    _setupLifecycleListener();
    _setupHeartbeatListener(tenantId);
    if (triggerInitialSync) {
      unawaited(syncNow());
    }
  }

  /// Ejecuta un ciclo de sincronización bajo demanda o por eventos del sistema.
  Future<SyncResult> syncNow({
    bool forceSocketReset = false,
    bool forceFullResync = false,
  }) async {
    final tenantId = _currentTenantId;
    if (tenantId == null || tenantId.isEmpty) {
      return SyncResult.failure('TenantId no configurado');
    }

    final result = await _syncLock.runProtected<SyncResult>(() async {
      return await _executeSyncCycle(tenantId, forceSocketReset, forceFullResync);
    });

    return result ?? SyncResult.failure('Sincronización en curso');
  }

  Future<SyncResult> _executeSyncCycle(
    String tenantId,
    bool forceSocketReset,
    bool forceFullResync,
  ) async {
    _updateStatus(SyncState.syncing);

    try {
      if (forceSocketReset) {
        await _cloudGateway.resetNetwork();
      }

      final pushed = await _pushWorker.pushPendingQueue(tenantId);
      final pulled = await _pullWorker.pullDeltaUpdates(tenantId, forceFull: forceFullResync);
      final pending = await _pushWorker.getPendingCount(tenantId);

      final result = SyncResult.success(pushed: pushed, pulled: pulled);
      _updateStatus(SyncState.idle, pending: pending, lastResult: result, syncTime: DateTime.now().toUtc());
      return result;
    } catch (e) {
      final failure = SyncResult.failure(e.toString());
      _updateStatus(SyncState.error, lastResult: failure);
      return failure;
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      final isConnected = results.any((r) => r != ConnectivityResult.none);
      if (isConnected) {
        unawaited(syncNow(forceSocketReset: true));
      } else {
        _updateStatus(SyncState.offline);
      }
    });
  }

  void _setupLifecycleListener() {
    _lifecycleListener?.dispose();
    _lifecycleListener = null;
    try {
      _lifecycleListener = AppLifecycleListener(
        onResume: () => unawaited(syncNow(forceSocketReset: true)),
      );
    } catch (_) {
      // En entornos de prueba de consola pura puede no estar inicializado WidgetsBinding
    }
  }

  void _setupHeartbeatListener(String tenantId) {
    _heartbeatSubscription?.cancel();
    _heartbeatSubscription = _cloudGateway.listenHeartbeat(tenantId).listen((pulse) {
      if (pulse != null) {
        unawaited(syncNow());
      }
    });
  }

  void _updateStatus(
    SyncState state, {
    int? pending,
    SyncResult? lastResult,
    DateTime? syncTime,
  }) {
    syncStatusNotifier.value = syncStatusNotifier.value.copyWith(
      state: state,
      pendingCount: pending,
      lastResult: lastResult,
      lastSyncUtc: syncTime,
    );
  }

  /// Libera recursos y suscripciones.
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _heartbeatSubscription?.cancel();
    _heartbeatSubscription = null;
    _lifecycleListener?.dispose();
    _lifecycleListener = null;
    _syncLock.forceRelease();
  }

  /// Limpia la instancia singleton para pruebas unitarias.
  @visibleForTesting
  static void resetInstanceForTesting() {
    _instance?.dispose();
    _instance = null;
  }
}
