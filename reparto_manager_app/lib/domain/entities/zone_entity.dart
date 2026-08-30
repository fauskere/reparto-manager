// lib/domain/entities/zone_entity.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/result.dart';

/// Entidad inmutable que representa una zona o jornada de reparto.
class ZoneEntity {
  final String id;
  final String tenantId;
  final String name;
  final List<String> cities;

  ZoneEntity({
    required this.id,
    required this.tenantId,
    required this.name,
    List<String>? cities,
  }) : cities = List.unmodifiable(cities ?? const <String>[]);

  /// Crea una zona validando los identificadores básicos.
  static Result<ZoneEntity, DomainFailure> create({
    required String id,
    required String tenantId,
    required String name,
    List<String>? cities,
  }) {
    if (id.trim().isEmpty || tenantId.trim().isEmpty || name.trim().isEmpty) {
      return Result.fail(
        const EntityValidationFailure(
          'El id, tenantId y nombre de la zona son obligatorios',
        ),
      );
    }

    return Result.ok(
      ZoneEntity(
        id: id.trim(),
        tenantId: tenantId.trim(),
        name: name.trim(),
        cities: cities?.map((c) => c.trim()).toList(),
      ),
    );
  }

  ZoneEntity copyWith({
    String? id,
    String? tenantId,
    String? name,
    List<String>? cities,
  }) {
    return ZoneEntity(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      cities: cities ?? this.cities,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ZoneEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tenantId == other.tenantId &&
          name == other.name &&
          _listEquals(cities, other.cities);

  @override
  int get hashCode => Object.hash(
        runtimeType,
        id,
        tenantId,
        name,
        Object.hashAll(cities),
      );

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() => 'ZoneEntity(id: $id, name: $name, cities: ${cities.length})';
}
