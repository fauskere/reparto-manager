// lib/domain/repositories/i_client_repository.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/money.dart';
import '../core/result.dart';
import '../entities/client_entity.dart';

/// Contrato abstracto para la persistencia y consulta de clientes.
abstract class IClientRepository {
  /// Obtiene un cliente por su identificador único dentro del tenant.
  Future<Result<ClientEntity, DomainFailure>> getClientById(
    String tenantId,
    String clientId,
  );

  /// Obtiene el listado paginado de clientes, opcionalmente filtrado por zona de reparto.
  Future<Result<List<ClientEntity>, DomainFailure>> getClients(
    String tenantId, {
    String? zoneId,
    int limit = 50,
    int offset = 0,
  });

  /// Busca clientes por nombre o apodo/fantasía.
  Future<Result<List<ClientEntity>, DomainFailure>> searchClients(
    String tenantId,
    String query, {
    int limit = 20,
  });

  /// Inserta o actualiza un cliente en el repositorio.
  Future<Result<void, DomainFailure>> saveClient(ClientEntity client);

  /// Elimina o desactiva lógicamente un cliente.
  Future<Result<void, DomainFailure>> deleteClient(
    String tenantId,
    String clientId,
  );

  /// Actualiza el estado de visita en la hoja de ruta del día.
  Future<Result<void, DomainFailure>> updateVisitStatus(
    String tenantId,
    String clientId,
    VisitStatus status,
  );

  /// Reinicia el estado de visita a [VisitStatus.notVisited] para todos los clientes de una zona.
  Future<Result<void, DomainFailure>> resetVisitStatusForZone(
    String tenantId,
    String zoneId,
  );

  /// Actualiza la lista de precios personalizados asignados al cliente.
  Future<Result<void, DomainFailure>> updateClientCustomPrices(
    String tenantId,
    String clientId,
    Map<String, Money> customPrices,
  );
}
