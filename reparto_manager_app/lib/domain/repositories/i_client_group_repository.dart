// lib/domain/repositories/i_client_group_repository.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/result.dart';
import '../entities/client_group_entity.dart';

/// Contrato abstracto para la administración de agrupaciones y cadenas de clientes.
abstract class IClientGroupRepository {
  /// Obtiene todas las agrupaciones de clientes del tenant.
  Future<Result<List<ClientGroupEntity>, DomainFailure>> getClientGroups(
    String tenantId,
  );

  /// Guarda o actualiza una agrupación de clientes.
  Future<Result<void, DomainFailure>> saveClientGroup(ClientGroupEntity group);

  /// Elimina una agrupación de clientes.
  Future<Result<void, DomainFailure>> deleteClientGroup(
    String tenantId,
    String groupId,
  );
}
