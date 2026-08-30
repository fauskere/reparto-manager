// lib/domain/usecases/register_damaged_stock_use_case.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/result.dart';
import '../repositories/i_truck_repository.dart';

/// Registra mermas o mercadería dañada a bordo de la camioneta.
///
/// Pasa la cantidad especificada del inventario útil hacia el registro de mercadería dañada.
class RegisterDamagedStockUseCase {
  final ITruckRepository _truckRepository;

  const RegisterDamagedStockUseCase(this._truckRepository);

  Future<Result<void, DomainFailure>> execute({
    required String tenantId,
    required String truckId,
    required DateTime dateUtc,
    required String variantKey,
    required int quantity,
  }) async {
    if (tenantId.trim().isEmpty || truckId.trim().isEmpty) {
      return Result.fail(const EntityValidationFailure('tenantId y truckId son obligatorios'));
    }
    if (quantity <= 0) {
      return Result.fail(const EntityValidationFailure('La cantidad dañada debe ser mayor a 0'));
    }

    final loadResult = await _truckRepository.getTodayTruckLoad(tenantId, truckId, dateUtc);
    if (loadResult.isFailure) {
      return Result.fail(loadResult.failureOrNull!);
    }

    final currentLoad = loadResult.valueOrNull!;
    final updatedLoad = currentLoad.registerDamagedStock(
      variantKey: variantKey,
      quantity: quantity,
    );

    return _truckRepository.saveTruckLoad(updatedLoad);
  }
}
