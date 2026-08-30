// lib/domain/usecases/generate_cash_summary_use_case.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/result.dart';
import '../entities/cash_summary_entity.dart';
import '../repositories/i_sale_repository.dart';

/// Genera el arqueo diario consolidado de caja distinguiendo efectivo en mano vs transferencias bancarias.
class GenerateCashSummaryUseCase {
  final ISaleRepository _saleRepository;

  const GenerateCashSummaryUseCase(this._saleRepository);

  Future<Result<CashSummaryEntity, DomainFailure>> execute({
    required String tenantId,
    required DateTime startUtc,
    required DateTime endUtc,
  }) async {
    if (tenantId.trim().isEmpty) {
      return Result.fail(const EntityValidationFailure('tenantId no puede estar vacío'));
    }
    if (startUtc.isAfter(endUtc)) {
      return Result.fail(const EntityValidationFailure('La fecha inicial no puede ser posterior a la final'));
    }

    return _saleRepository.getCashSummary(tenantId, startUtc, endUtc);
  }
}
