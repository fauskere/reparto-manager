// lib/domain/entities/promotion_entity.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/result.dart';

/// Entidad inmutable que representa una promoción o combo comercial.
class PromotionEntity {
  final String id;
  final String tenantId;
  final String name;

  /// Variantes y cantidades requeridas para activar la promoción.
  /// Clave: variantKey ("productId|variantName") -> cantidad mínima.
  final Map<String, int> requiredItems;

  /// Porcentaje de descuento aplicable (ej: 10.0 para 10%).
  final double discountPercentage;
  final bool isActive;

  PromotionEntity({
    required this.id,
    required this.tenantId,
    required this.name,
    Map<String, int>? requiredItems,
    required this.discountPercentage,
    this.isActive = true,
  }) : requiredItems = Map.unmodifiable(requiredItems ?? const <String, int>{});

  /// Crea una promoción validando identificadores y porcentaje.
  static Result<PromotionEntity, DomainFailure> create({
    required String id,
    required String tenantId,
    required String name,
    Map<String, int>? requiredItems,
    required double discountPercentage,
    bool isActive = true,
  }) {
    if (id.trim().isEmpty || tenantId.trim().isEmpty || name.trim().isEmpty) {
      return Result.fail(
        const EntityValidationFailure(
          'El id, tenantId y nombre de la promoción son obligatorios',
        ),
      );
    }

    if (discountPercentage < 0 || discountPercentage > 100) {
      return Result.fail(
        const EntityValidationFailure(
          'El porcentaje de descuento debe estar comprendido entre 0 y 100',
        ),
      );
    }

    return Result.ok(
      PromotionEntity(
        id: id.trim(),
        tenantId: tenantId.trim(),
        name: name.trim(),
        requiredItems: requiredItems,
        discountPercentage: discountPercentage,
        isActive: isActive,
      ),
    );
  }

  /// Verifica si un carrito de compras califica para aplicar esta promoción.
  bool isEligible(Map<String, int> cartItems) {
    if (!isActive || requiredItems.isEmpty) return false;
    for (final entry in requiredItems.entries) {
      final inCart = cartItems[entry.key] ?? 0;
      if (inCart < entry.value) {
        return false;
      }
    }
    return true;
  }

  PromotionEntity copyWith({
    String? id,
    String? tenantId,
    String? name,
    Map<String, int>? requiredItems,
    double? discountPercentage,
    bool? isActive,
  }) {
    return PromotionEntity(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      requiredItems: requiredItems ?? this.requiredItems,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromotionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tenantId == other.tenantId &&
          name == other.name &&
          discountPercentage == other.discountPercentage &&
          isActive == other.isActive &&
          _mapEquals(requiredItems, other.requiredItems);

  @override
  int get hashCode => Object.hash(
        runtimeType,
        id,
        tenantId,
        name,
        discountPercentage,
        isActive,
        Object.hashAll(requiredItems.entries),
      );

  static bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || b[key] != a[key]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'PromotionEntity(id: $id, name: $name, discount: $discountPercentage%)';
}
