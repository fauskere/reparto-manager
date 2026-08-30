// lib/domain/usecases/unload_truck_stock_use_case.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/result.dart';
import '../repositories/i_truck_repository.dart';

/// Registra la descarga de sobrantes de mercadería desde la camioneta hacia el depósito.
class UnloadTruckStockUseCase {
  final ITruckRepository _truckRepository;

  const UnloadTruckStockUseCase(this._truckRepository);

  Future<Result<void, DomainFailure>> execute({
    required String tenantId,
    required String truckId,
    required Map<String, int> unloadDeltas,
  }) async {
    if (tenantId.trim().isEmpty || truckId.trim().isEmpty) {
      return Result.fail(const EntityValidationFailure('tenantId y truckId son obligatorios'));
    }

    final negativeDeltas = <String, int>{};
    for (final entry in unloadDeltas.entries) {
      if (entry.value <= 0) {
        return Result.fail(
          EntityValidationFailure('La cantidad a descargar para ${entry.key} debe ser mayor a 0'),
        );
      }
      negativeDeltas[entry.key] = -entry.value;
    }

    return _truckRepository.applyStockDelta(tenantId, truckId, negativeDeltas);
  }
}
