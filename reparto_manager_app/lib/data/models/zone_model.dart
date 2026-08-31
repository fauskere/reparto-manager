// lib/data/models/zone_model.dart
// Capa de Datos e Infraestructura SQLite - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'dart:convert';
import '../../domain/entities/zone_entity.dart';

/// Modelo de datos para la tabla SQLite `zones`.
/// Convierte bidireccionalmente entre [ZoneEntity] y mapas SQLite.
class ZoneModel {
  final String id;
  final String tenantId;
  final String name;
  final String citiesJson;

  const ZoneModel({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.citiesJson,
  });

  /// Crea un [ZoneModel] a partir de una [ZoneEntity].
  factory ZoneModel.fromEntity(ZoneEntity entity) {
    return ZoneModel(
      id: entity.id,
      tenantId: entity.tenantId,
      name: entity.name,
      citiesJson: jsonEncode(entity.cities),
    );
  }

  /// Convierte este modelo a una [ZoneEntity] de dominio puro.
  ZoneEntity toEntity() {
    final List<dynamic> decoded = jsonDecode(citiesJson) as List<dynamic>;
    final cities = decoded.map((e) => e.toString()).toList();

    return ZoneEntity(
      id: id,
      tenantId: tenantId,
      name: name,
      cities: cities,
    );
  }

  /// Crea un [ZoneModel] desde una fila de SQLite.
  factory ZoneModel.fromMap(Map<String, dynamic> map) {
    return ZoneModel(
      id: map['id'] as String,
      tenantId: map['tenantId'] as String,
      name: map['name'] as String,
      citiesJson: map['citiesJson'] as String,
    );
  }

  /// Exporta los datos a un mapa apto para inserción en SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'name': name,
      'citiesJson': citiesJson,
    };
  }
}
