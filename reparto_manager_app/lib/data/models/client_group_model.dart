// lib/data/models/client_group_model.dart
// Capa de Datos e Infraestructura SQLite - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'dart:convert';
import '../../domain/entities/client_group_entity.dart';

/// Modelo de datos para la tabla SQLite `client_groups`.
/// Convierte bidireccionalmente entre [ClientGroupEntity] y mapas SQLite.
class ClientGroupModel {
  final String id;
  final String tenantId;
  final String name;
  final String clientIdsJson;

  const ClientGroupModel({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.clientIdsJson,
  });

  /// Crea un [ClientGroupModel] a partir de una [ClientGroupEntity].
  factory ClientGroupModel.fromEntity(ClientGroupEntity entity) {
    return ClientGroupModel(
      id: entity.id,
      tenantId: entity.tenantId,
      name: entity.name,
      clientIdsJson: jsonEncode(entity.clientIds),
    );
  }

  /// Convierte este modelo a una [ClientGroupEntity] de dominio puro.
  ClientGroupEntity toEntity() {
    final List<dynamic> decoded = jsonDecode(clientIdsJson) as List<dynamic>;
    final clientIds = decoded.map((e) => e.toString()).toList();

    return ClientGroupEntity(
      id: id,
      tenantId: tenantId,
      name: name,
      clientIds: clientIds,
    );
  }

  /// Crea un [ClientGroupModel] desde una fila de SQLite.
  factory ClientGroupModel.fromMap(Map<String, dynamic> map) {
    return ClientGroupModel(
      id: map['id'] as String,
      tenantId: map['tenantId'] as String,
      name: map['name'] as String,
      clientIdsJson: map['clientIdsJson'] as String,
    );
  }

  /// Exporta los datos a un mapa apto para inserción en SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'name': name,
      'clientIdsJson': clientIdsJson,
    };
  }
}
