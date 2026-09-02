// lib/data/sync/sync_status.dart
// Motor de Sincronización Offline-First - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'package:flutter/foundation.dart';

/// Estados posibles del ciclo de sincronización en segundo plano o bajo demanda.
enum SyncState {
  idle,
  syncing,
  offline,
  error,
}

/// Resultado atómico de una pasada de sincronización push/pull.
class SyncResult {
  final bool isSuccess;
  final int pushedCount;
  final int pulledCount;
  final String message;
  final String? errorMessage;

  const SyncResult({
    required this.isSuccess,
    this.pushedCount = 0,
    this.pulledCount = 0,
    required this.message,
    this.errorMessage,
  });

  factory SyncResult.success({int pushed = 0, int pulled = 0, String? message}) {
    final defaultMsg = pushed == 0 && pulled == 0
        ? 'Todo sincronizado y al día.'
        : 'Sincronizado: $pushed subidos, $pulled descargados.';
    return SyncResult(
      isSuccess: true,
      pushedCount: pushed,
      pulledCount: pulled,
      message: message ?? defaultMsg,
    );
  }

  factory SyncResult.failure(String errorMessage) {
    return SyncResult(
      isSuccess: false,
      pushedCount: 0,
      pulledCount: 0,
      message: 'Fallo de sincronización',
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() => 'SyncResult(success: $isSuccess, push: $pushedCount, pull: $pulledCount, msg: $message)';
}

/// Estado inmutable consumible por la interfaz de usuario.
class SyncStatus {
  final SyncState state;
  final int pendingCount;
  final DateTime? lastSyncUtc;
  final SyncResult? lastResult;

  const SyncStatus({
    required this.state,
    this.pendingCount = 0,
    this.lastSyncUtc,
    this.lastResult,
  });

  factory SyncStatus.initial() => const SyncStatus(
        state: SyncState.idle,
        pendingCount: 0,
      );

  SyncStatus copyWith({
    SyncState? state,
    int? pendingCount,
    DateTime? lastSyncUtc,
    SyncResult? lastResult,
  }) {
    return SyncStatus(
      state: state ?? this.state,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncUtc: lastSyncUtc ?? this.lastSyncUtc,
      lastResult: lastResult ?? this.lastResult,
    );
  }

  @override
  String toString() => 'SyncStatus(state: $state, pending: $pendingCount, lastSync: $lastSyncUtc)';
}

/// Notificador global reactivo para la UI.
final syncStatusNotifier = ValueNotifier<SyncStatus>(SyncStatus.initial());
