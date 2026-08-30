// lib/domain/entities/client_group_entity.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/result.dart';

/// Entidad inmutable que representa una agrupación o cadena de clientes/sucursales.
class ClientGroupEntity {
  final String id;
  final String tenantId;
  final String name;
  final List<String> clientIds;

  ClientGroupEntity({
    required this.id,
    required this.tenantId,
    required this.name,
    List<String>? clientIds,
  }) : clientIds = List.unmodifiable(clientIds ?? const <String>[]);

  /// Crea un grupo validando los campos obligatorios.
  static Result<ClientGroupEntity, DomainFailure> create({
    required String id,
    required String tenantId,
    required String name,
    List<String>? clientIds,
  }) {
    if (id.trim().isEmpty || tenantId.trim().isEmpty || name.trim().isEmpty) {
      return Result.fail(
        const EntityValidationFailure(
          'El id, tenantId y nombre del grupo son obligatorios',
        ),
      );
    }

    return Result.ok(
      ClientGroupEntity(
        id: id.trim(),
        tenantId: tenantId.trim(),
        name: name.trim(),
        clientIds: clientIds?.map((c) => c.trim()).toList(),
      ),
    );
  }

  ClientGroupEntity copyWith({
    String? id,
    String? tenantId,
    String? name,
    List<String>? clientIds,
  }) {
    return ClientGroupEntity(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      clientIds: clientIds ?? this.clientIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientGroupEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tenantId == other.tenantId &&
          name == other.name &&
          _listEquals(clientIds, other.clientIds);

  @override
  int get hashCode => Object.hash(
        runtimeType,
        id,
        tenantId,
        name,
        Object.hashAll(clientIds),
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
  String toString() => 'ClientGroupEntity(id: $id, name: $name, clients: ${clientIds.length})';
}
