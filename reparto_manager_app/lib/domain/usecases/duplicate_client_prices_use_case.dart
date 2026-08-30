// lib/domain/usecases/duplicate_client_prices_use_case.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/result.dart';
import '../repositories/i_client_repository.dart';

/// Duplica la lista de precios personalizados de un cliente origen hacia una lista de clientes destino.
class DuplicateClientPricesUseCase {
  final IClientRepository _clientRepository;

  const DuplicateClientPricesUseCase(this._clientRepository);

  Future<Result<void, DomainFailure>> execute({
    required String tenantId,
    required String sourceClientId,
    required List<String> targetClientIds,
  }) async {
    if (tenantId.trim().isEmpty) {
      return Result.fail(const EntityValidationFailure('tenantId no puede estar vacío'));
    }
    if (targetClientIds.isEmpty) {
      return Result.ok(null);
    }

    final sourceResult = await _clientRepository.getClientById(tenantId, sourceClientId);
    if (sourceResult.isFailure) {
      return Result.fail(sourceResult.failureOrNull!);
    }

    final sourcePrices = sourceResult.valueOrNull!.customPrices;

    for (final targetId in targetClientIds) {
      final updateResult = await _clientRepository.updateClientCustomPrices(
        tenantId,
        targetId,
        sourcePrices,
      );
      if (updateResult.isFailure) {
        return Result.fail(updateResult.failureOrNull!);
      }
    }

    return Result.ok(null);
  }
}
