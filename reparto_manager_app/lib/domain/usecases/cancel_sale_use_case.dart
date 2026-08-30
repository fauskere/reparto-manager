// lib/domain/usecases/cancel_sale_use_case.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/money.dart';
import '../core/result.dart';
import '../entities/ledger_entry_entity.dart';
import '../repositories/i_ledger_repository.dart';
import '../repositories/i_sale_repository.dart';
import '../repositories/i_truck_repository.dart';

/// Anula una venta registrada, restituye el stock a la camioneta y emite contra-asiento contable.
class CancelSaleUseCase {
  final ISaleRepository _saleRepository;
  final ITruckRepository _truckRepository;
  final ILedgerRepository _ledgerRepository;

  const CancelSaleUseCase(
    this._saleRepository,
    this._truckRepository,
    this._ledgerRepository,
  );

  Future<Result<void, DomainFailure>> execute({
    required String tenantId,
    required String saleId,
    required String reason,
    required String truckId,
  }) async {
    if (reason.trim().isEmpty) {
      return Result.fail(const EntityValidationFailure('El motivo de anulación es obligatorio'));
    }

    final saleResult = await _saleRepository.getSaleById(tenantId, saleId);
    if (saleResult.isFailure) return Result.fail(saleResult.failureOrNull!);

    final sale = saleResult.valueOrNull!;

    final cancelResult = await _saleRepository.cancelSale(tenantId, saleId, reason);
    if (cancelResult.isFailure) return Result.fail(cancelResult.failureOrNull!);

    final restoreDeltas = <String, int>{};
    for (final item in sale.items) {
      final key = '${item.productId}|${item.variantName}';
      restoreDeltas[key] = (restoreDeltas[key] ?? 0) + item.quantity;
    }
    for (final ex in sale.exchanges) {
      final key = '${ex.productId}|${ex.variantName}';
      restoreDeltas[key] = (restoreDeltas[key] ?? 0) - ex.quantity;
    }

    if (restoreDeltas.isNotEmpty) {
      final stockRes = await _truckRepository.applyStockDelta(tenantId, truckId, restoreDeltas);
      if (stockRes.isFailure) return Result.fail(stockRes.failureOrNull!);
    }

    if (sale.debtGenerated > Money.zero) {
      final contraEntry = LedgerEntryEntity(
        id: 'led_cancel_${sale.id}_${DateTime.now().millisecondsSinceEpoch}',
        tenantId: tenantId,
        clientId: sale.clientId,
        date: DateTime.now().toUtc(),
        type: LedgerEntryType.adjustmentCredit,
        referenceId: sale.id,
        amount: sale.debtGenerated,
        description: 'Anulación Venta #${sale.ticketNumber}: $reason',
      );
      final ledgerRes = await _ledgerRepository.recordEntry(contraEntry);
      if (ledgerRes.isFailure) return Result.fail(ledgerRes.failureOrNull!);
    }

    return Result.ok(null);
  }
}
