// lib/domain/usecases/reset_zone_route_use_case.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/result.dart';
import '../repositories/i_client_repository.dart';

/// Reinicia el estado de visita de todos los clientes de una zona al comenzar la jornada (notVisited).
class ResetZoneRouteUseCase {
  final IClientRepository _clientRepository;

  const ResetZoneRouteUseCase(this._clientRepository);

  Future<Result<void, DomainFailure>> execute({
    required String tenantId,
    required String zoneId,
  }) async {
    if (tenantId.trim().isEmpty || zoneId.trim().isEmpty) {
      return Result.fail(const EntityValidationFailure('tenantId y zoneId son obligatorios'));
    }

    return _clientRepository.resetVisitStatusForZone(tenantId, zoneId);
  }
}
