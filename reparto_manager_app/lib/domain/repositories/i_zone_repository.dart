// lib/domain/repositories/i_zone_repository.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/result.dart';
import '../entities/zone_entity.dart';

/// Contrato abstracto para la administración de zonas de reparto y sus localidades.
abstract class IZoneRepository {
  /// Obtiene todas las zonas configuradas para el tenant.
  Future<Result<List<ZoneEntity>, DomainFailure>> getZones(String tenantId);

  /// Guarda o actualiza una zona de reparto.
  Future<Result<void, DomainFailure>> saveZone(ZoneEntity zone);

  /// Elimina una zona de reparto.
  Future<Result<void, DomainFailure>> deleteZone(
    String tenantId,
    String zoneId,
  );
}
