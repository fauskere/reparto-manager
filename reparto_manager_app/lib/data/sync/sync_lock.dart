// lib/data/sync/sync_lock.dart
// Motor de Sincronización Offline-First - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'dart:async';

/// Candado Mutex y gestor de resiliencia con backoff exponencial para sincronización.
class SyncLock {
  bool _isSyncing = false;

  /// Retorna true si hay una sincronización en curso.
  bool get isSyncing => _isSyncing;

  /// Ejecuta [action] bajo exclusión mutua. Retorna null si ya está ocupado.
  Future<T?> runProtected<T>(Future<T> Function() action) async {
    if (_isSyncing) return null;
    _isSyncing = true;
    try {
      return await action();
    } finally {
      _isSyncing = false;
    }
  }

  /// Ejecuta [action] con reintentos basados en backoff exponencial (5s, 15s, 30s).
  Future<T> executeWithRetry<T>({
    required Future<T> Function() action,
    int maxRetries = 3,
    List<Duration> delays = const [
      Duration(seconds: 5),
      Duration(seconds: 15),
      Duration(seconds: 30),
    ],
  }) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await action();
      } catch (e) {
        if (attempts >= maxRetries) rethrow;
        final waitDuration = attempts - 1 < delays.length
            ? delays[attempts - 1]
            : delays.last;
        await Future.delayed(waitDuration);
      }
    }
  }

  /// Libera forzosamente el candado (útil en tests o ante reseteos críticos).
  void forceRelease() {
    _isSyncing = false;
  }
}
