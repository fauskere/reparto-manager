// lib/domain/repositories/i_truck_repository.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/result.dart';
import '../entities/truck_load_entity.dart';

/// Contrato abstracto para la administración de stock móvil y carga de camionetas.
abstract class ITruckRepository {
  /// Obtiene la carga del día para una camioneta específica.
  Future<Result<TruckLoadEntity, DomainFailure>> getTodayTruckLoad(
    String tenantId,
    String truckId,
    DateTime dateUtc,
  );

  /// Guarda o actualiza el estado completo de la carga móvil.
  Future<Result<void, DomainFailure>> saveTruckLoad(TruckLoadEntity truckLoad);

  /// Aplica ajustes de existencias sumando o restando unidades por variantKey.
  Future<Result<void, DomainFailure>> applyStockDelta(
    String tenantId,
    String truckId,
    Map<String, int> deltas,
  );
}
