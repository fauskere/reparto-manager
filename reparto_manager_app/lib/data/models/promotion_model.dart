// lib/data/models/promotion_model.dart
// Capa de Datos e Infraestructura SQLite - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'dart:convert';
import '../../domain/entities/promotion_entity.dart';

/// Modelo de datos para la tabla SQLite `promotions`.
/// Mapea promociones comerciales y combos requeridos.
class PromotionModel {
  final String id;
  final String tenantId;
  final String name;
  final String requiredItemsJson;
  final double discountPercentage;
  final int isActive;

  const PromotionModel({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.requiredItemsJson,
    required this.discountPercentage,
    required this.isActive,
  });

  /// Crea un [PromotionModel] a partir de una [PromotionEntity].
  factory PromotionModel.fromEntity(PromotionEntity entity) {
    return PromotionModel(
      id: entity.id,
      tenantId: entity.tenantId,
      name: entity.name,
      requiredItemsJson: jsonEncode(entity.requiredItems),
      discountPercentage: entity.discountPercentage,
      isActive: entity.isActive ? 1 : 0,
    );
  }

  /// Convierte este modelo a una [PromotionEntity] de dominio puro.
  PromotionEntity toEntity() {
    final Map<String, int> requiredItems = {};
    if (requiredItemsJson.trim().isNotEmpty) {
      final decoded = jsonDecode(requiredItemsJson) as Map<String, dynamic>;
      decoded.forEach((key, value) {
        requiredItems[key] = (value as num).toInt();
      });
    }

    return PromotionEntity(
      id: id,
      tenantId: tenantId,
      name: name,
      requiredItems: requiredItems,
      discountPercentage: discountPercentage,
      isActive: isActive == 1,
    );
  }

  /// Crea un [PromotionModel] desde una fila de SQLite.
  factory PromotionModel.fromMap(Map<String, dynamic> map) {
    return PromotionModel(
      id: map['id'] as String,
      tenantId: map['tenantId'] as String,
      name: map['name'] as String,
      requiredItemsJson: map['requiredItemsJson'] as String,
      discountPercentage: (map['discountPercentage'] as num).toDouble(),
      isActive: (map['isActive'] as num).toInt(),
    );
  }

  /// Exporta los datos a un mapa apto para inserción en SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'name': name,
      'requiredItemsJson': requiredItemsJson,
      'discountPercentage': discountPercentage,
      'isActive': isActive,
    };
  }
}
