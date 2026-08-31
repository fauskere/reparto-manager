// lib/data/models/sync_queue_model.dart
// Capa de Datos e Infraestructura SQLite - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'dart:convert';

/// Modelo de datos para la tabla SQLite `sync_queue`.
/// Gestiona la cola de operaciones offline para replicación en la nube.
class SyncQueueModel {
  final String id;
  final String tenantId;
  final String collectionName;
  final String documentId;
  final String operation;
  final String payloadJson;
  final String createdAtUtc;
  final String status;

  const SyncQueueModel({
    required this.id,
    required this.tenantId,
    required this.collectionName,
    required this.documentId,
    required this.operation,
    required this.payloadJson,
    required this.createdAtUtc,
    required this.status,
  });

  /// Accesor de DateTime UTC de creación del evento offline.
  DateTime get createdAt => DateTime.parse(createdAtUtc);

  /// Mapa de datos decodificado.
  Map<String, dynamic> get payload => jsonDecode(payloadJson) as Map<String, dynamic>;

  /// Crea un [SyncQueueModel] fuertemente tipado.
  factory SyncQueueModel.create({
    required String id,
    required String tenantId,
    required String collectionName,
    required String documentId,
    required String operation,
    required Map<String, dynamic> payload,
    required DateTime createdAt,
    String status = 'pending',
  }) {
    return SyncQueueModel(
      id: id,
      tenantId: tenantId,
      collectionName: collectionName,
      documentId: documentId,
      operation: operation,
      payloadJson: jsonEncode(payload),
      createdAtUtc: createdAt.toUtc().toIso8601String(),
      status: status,
    );
  }

  /// Crea un [SyncQueueModel] desde una fila de SQLite.
  factory SyncQueueModel.fromMap(Map<String, dynamic> map) {
    return SyncQueueModel(
      id: map['id'] as String,
      tenantId: map['tenantId'] as String,
      collectionName: map['collectionName'] as String,
      documentId: map['documentId'] as String,
      operation: map['operation'] as String,
      payloadJson: map['payloadJson'] as String,
      createdAtUtc: map['createdAtUtc'] as String,
      status: map['status'] as String,
    );
  }

  /// Exporta los datos a un mapa apto para inserción en SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'collectionName': collectionName,
      'documentId': documentId,
      'operation': operation,
      'payloadJson': payloadJson,
      'createdAtUtc': createdAtUtc,
      'status': status,
    };
  }
}
