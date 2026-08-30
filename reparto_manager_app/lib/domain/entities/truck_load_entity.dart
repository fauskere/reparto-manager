// lib/domain/entities/truck_load_entity.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/result.dart';

/// Entidad inmutable que representa el stock y carga móvil a bordo de una camioneta de reparto.
class TruckLoadEntity {
  final String truckId;
  final String tenantId;
  final DateTime date;

  /// Inventario disponible a bordo. Clave: variantKey ("productId|variantName") -> unidades.
  final Map<String, int> inventory;

  /// Mermas, roturas o cambios defectuosos a bordo.
  final Map<String, int> damagedItems;

  TruckLoadEntity({
    required this.truckId,
    required this.tenantId,
    required this.date,
    Map<String, int>? inventory,
    Map<String, int>? damagedItems,
  })  : inventory = Map.unmodifiable(inventory ?? const <String, int>{}),
        damagedItems = Map.unmodifiable(damagedItems ?? const <String, int>{});

  /// Crea una carga de camioneta validando los identificadores básicos.
  static Result<TruckLoadEntity, DomainFailure> create({
    required String truckId,
    required String tenantId,
    required DateTime date,
    Map<String, int>? inventory,
    Map<String, int>? damagedItems,
  }) {
    if (truckId.trim().isEmpty || tenantId.trim().isEmpty) {
      return Result.fail(
        const EntityValidationFailure(
          'Los identificadores de camioneta y tenant son obligatorios',
        ),
      );
    }

    return Result.ok(
      TruckLoadEntity(
        truckId: truckId.trim(),
        tenantId: tenantId.trim(),
        date: date.toUtc(),
        inventory: inventory,
        damagedItems: damagedItems,
      ),
    );
  }

  /// Retorna las existencias a bordo de una variante específica.
  int getStock(String variantKey) => inventory[variantKey] ?? 0;

  /// Retorna las unidades dañadas/rotas a bordo de una variante específica.
  int getDamaged(String variantKey) => damagedItems[variantKey] ?? 0;

  /// Directiva 4: Permite consultar si existen variantes con stock negativo.
  /// No bloquea la venta, permitiendo operar en la calle ante descuadres de carga matutina.
  bool get hasNegativeStock => inventory.values.any((qty) => qty < 0);

  /// Lista de variantes con saldo de stock negativo para alertas operativas.
  List<String> get negativeStockVariantKeys => inventory.entries
      .where((entry) => entry.value < 0)
      .map((entry) => entry.key)
      .toList();

  /// Descuenta unidades vendidas. Permite caer en saldo negativo según Directiva 4.
  TruckLoadEntity applySale({
    required String variantKey,
    required int quantity,
  }) {
    final updated = Map<String, int>.from(inventory);
    final current = updated[variantKey] ?? 0;
    updated[variantKey] = current - quantity;
    return copyWith(inventory: updated);
  }

  /// Registra unidades devueltas o rotas recibidas del cliente.
  TruckLoadEntity recordDamaged({
    required String variantKey,
    required int quantity,
  }) {
    final updatedDamaged = Map<String, int>.from(damagedItems);
    final current = updatedDamaged[variantKey] ?? 0;
    updatedDamaged[variantKey] = current + quantity;
    return copyWith(damagedItems: updatedDamaged);
  }

  /// Pasa mercadería dañada del inventario útil hacia el stock dañado.
  TruckLoadEntity registerDamagedStock({
    required String variantKey,
    required int quantity,
  }) {
    final updatedInv = Map<String, int>.from(inventory);
    final currentInv = updatedInv[variantKey] ?? 0;
    updatedInv[variantKey] = currentInv - quantity;

    final updatedDamaged = Map<String, int>.from(damagedItems);
    final currentDamaged = updatedDamaged[variantKey] ?? 0;
    updatedDamaged[variantKey] = currentDamaged + quantity;

    return copyWith(
      inventory: updatedInv,
      damagedItems: updatedDamaged,
    );
  }

  /// Ajusta el inventario de una variante sumando o restando [delta].
  TruckLoadEntity adjustStock({
    required String variantKey,
    required int delta,
  }) {
    final updated = Map<String, int>.from(inventory);
    final current = updated[variantKey] ?? 0;
    updated[variantKey] = current + delta;
    return copyWith(inventory: updated);
  }

  TruckLoadEntity copyWith({
    String? truckId,
    String? tenantId,
    DateTime? date,
    Map<String, int>? inventory,
    Map<String, int>? damagedItems,
  }) {
    return TruckLoadEntity(
      truckId: truckId ?? this.truckId,
      tenantId: tenantId ?? this.tenantId,
      date: date ?? this.date,
      inventory: inventory ?? this.inventory,
      damagedItems: damagedItems ?? this.damagedItems,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TruckLoadEntity &&
          runtimeType == other.runtimeType &&
          truckId == other.truckId &&
          tenantId == other.tenantId &&
          date == other.date &&
          _mapEquals(inventory, other.inventory) &&
          _mapEquals(damagedItems, other.damagedItems);

  @override
  int get hashCode => Object.hash(
        runtimeType,
        truckId,
        tenantId,
        date,
        Object.hashAll(inventory.entries),
        Object.hashAll(damagedItems.entries),
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
      'TruckLoadEntity(truck: $truckId, items: ${inventory.length}, hasNegative: $hasNegativeStock)';
}
