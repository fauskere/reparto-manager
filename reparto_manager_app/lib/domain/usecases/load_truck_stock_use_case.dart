// lib/domain/usecases/load_truck_stock_use_case.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/result.dart';
import '../repositories/i_truck_repository.dart';

/// Registra la carga matutina de mercadería en la camioneta sumando existencias.
class LoadTruckStockUseCase {
  final ITruckRepository _truckRepository;

  const LoadTruckStockUseCase(this._truckRepository);

  Future<Result<void, DomainFailure>> execute({
    required String tenantId,
    required String truckId,
    required Map<String, int> loadDeltas,
  }) async {
    if (tenantId.trim().isEmpty || truckId.trim().isEmpty) {
      return Result.fail(const EntityValidationFailure('tenantId y truckId son obligatorios'));
    }

    for (final entry in loadDeltas.entries) {
      if (entry.value <= 0) {
        return Result.fail(
          EntityValidationFailure('La cantidad a cargar para ${entry.key} debe ser mayor a 0'),
        );
      }
    }

    return _truckRepository.applyStockDelta(tenantId, truckId, loadDeltas);
  }
}
