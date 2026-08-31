// lib/data/repositories/sync_queue_helper.dart
// Capa de Datos e Infraestructura SQLite - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Utilidad para encolar de forma atómica operaciones offline en la tabla `sync_queue`.
class SyncQueueHelper {
  /// Encola una operación en la cola de sincronización.
  static Future<void> enqueueOperation({
    required DatabaseExecutor executor,
    required String tenantId,
    required String collectionName,
    required String documentId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final now = DateTime.now().toUtc();
    final eventId = '${collectionName}_${documentId}_${now.microsecondsSinceEpoch}';

    await executor.insert(
      'sync_queue',
      {
        'id': eventId,
        'tenantId': tenantId,
        'collectionName': collectionName,
        'documentId': documentId,
        'operation': operation,
        'payloadJson': jsonEncode(payload),
        'createdAtUtc': now.toIso8601String(),
        'status': 'pending',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
