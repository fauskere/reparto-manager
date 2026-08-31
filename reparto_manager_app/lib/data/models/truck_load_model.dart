// lib/data/models/truck_load_model.dart
// Capa de Datos e Infraestructura SQLite - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'dart:convert';
import '../../domain/entities/truck_load_entity.dart';

/// Modelo de datos para la tabla SQLite `truck_loads`.
/// Almacena el inventario de camioneta y registro de mermas por variante.
class TruckLoadModel {
  final String truckId;
  final String tenantId;
  final String dateUtc;
  final String inventoryJson;
  final String? damagedItemsJson;

  const TruckLoadModel({
    required this.truckId,
    required this.tenantId,
    required this.dateUtc,
    required this.inventoryJson,
    this.damagedItemsJson,
  });

  /// Crea un [TruckLoadModel] a partir de una [TruckLoadEntity].
  factory TruckLoadModel.fromEntity(TruckLoadEntity entity) {
    return TruckLoadModel(
      truckId: entity.truckId,
      tenantId: entity.tenantId,
      dateUtc: entity.date.toUtc().toIso8601String(),
      inventoryJson: jsonEncode(entity.inventory),
      damagedItemsJson: entity.damagedItems.isNotEmpty ? jsonEncode(entity.damagedItems) : null,
    );
  }

  /// Convierte este modelo a una [TruckLoadEntity] de dominio puro.
  TruckLoadEntity toEntity() {
    final Map<String, int> inventory = {};
    if (inventoryJson.trim().isNotEmpty) {
      final decoded = jsonDecode(inventoryJson) as Map<String, dynamic>;
      decoded.forEach((key, value) {
        inventory[key] = (value as num).toInt();
      });
    }

    final Map<String, int> damagedItems = {};
    if (damagedItemsJson != null && damagedItemsJson!.trim().isNotEmpty) {
      final decoded = jsonDecode(damagedItemsJson!) as Map<String, dynamic>;
      decoded.forEach((key, value) {
        damagedItems[key] = (value as num).toInt();
      });
    }

    return TruckLoadEntity(
      truckId: truckId,
      tenantId: tenantId,
      date: DateTime.parse(dateUtc).toUtc(),
      inventory: inventory,
      damagedItems: damagedItems,
    );
  }

  /// Crea un [TruckLoadModel] desde una fila de SQLite.
  factory TruckLoadModel.fromMap(Map<String, dynamic> map) {
    return TruckLoadModel(
      truckId: map['truckId'] as String,
      tenantId: map['tenantId'] as String,
      dateUtc: map['dateUtc'] as String,
      inventoryJson: map['inventoryJson'] as String,
      damagedItemsJson: map['damagedItemsJson'] as String?,
    );
  }

  /// Exporta los datos a un mapa apto para inserción en SQLite.
  Map<String, dynamic> toMap() {
    return {
      'truckId': truckId,
      'tenantId': tenantId,
      'dateUtc': dateUtc,
      'inventoryJson': inventoryJson,
      'damagedItemsJson': damagedItemsJson,
    };
  }
}
