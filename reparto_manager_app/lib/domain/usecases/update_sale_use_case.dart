// lib/domain/usecases/update_sale_use_case.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/money.dart';
import '../core/result.dart';
import '../entities/ledger_entry_entity.dart';
import '../entities/sale_entity.dart';
import '../repositories/i_ledger_repository.dart';
import '../repositories/i_sale_repository.dart';
import '../repositories/i_truck_repository.dart';

/// Modifica una venta previa recalculando diferencias de inventario y ajustes en el libro mayor.
class UpdateSaleUseCase {
  final ISaleRepository _saleRepository;
  final ITruckRepository _truckRepository;
  final ILedgerRepository _ledgerRepository;

  const UpdateSaleUseCase(
    this._saleRepository,
    this._truckRepository,
    this._ledgerRepository,
  );

  Future<Result<SaleEntity, DomainFailure>> execute({
    required SaleEntity oldSale,
    required SaleEntity updatedSale,
    required String truckId,
  }) async {
    if (oldSale.tenantId != updatedSale.tenantId || oldSale.id != updatedSale.id) {
      return Result.fail(const EntityValidationFailure('Inconsistencia en identificadores de venta'));
    }

    final stockDeltas = _calculateStockDeltas(oldSale, updatedSale);
    if (stockDeltas.isNotEmpty) {
      final stockRes = await _truckRepository.applyStockDelta(
        updatedSale.tenantId,
        truckId,
        stockDeltas,
      );
      if (stockRes.isFailure) return Result.fail(stockRes.failureOrNull!);
    }

    final ledgerRes = await _recordAdjustmentLedger(oldSale, updatedSale);
    if (ledgerRes.isFailure) return Result.fail(ledgerRes.failureOrNull!);

    final saveRes = await _saleRepository.saveSale(updatedSale);
    if (saveRes.isFailure) return Result.fail(saveRes.failureOrNull!);

    return Result.ok(updatedSale);
  }

  Map<String, int> _calculateStockDeltas(SaleEntity oldSale, SaleEntity newSale) {
    final deltas = <String, int>{};
    for (final item in oldSale.items) {
      final key = '${item.productId}|${item.variantName}';
      deltas[key] = (deltas[key] ?? 0) + item.quantity;
    }
    for (final item in newSale.items) {
      final key = '${item.productId}|${item.variantName}';
      deltas[key] = (deltas[key] ?? 0) - item.quantity;
    }
    for (final ex in oldSale.exchanges) {
      final key = '${ex.productId}|${ex.variantName}';
      deltas[key] = (deltas[key] ?? 0) - ex.quantity;
    }
    for (final ex in newSale.exchanges) {
      final key = '${ex.productId}|${ex.variantName}';
      deltas[key] = (deltas[key] ?? 0) + ex.quantity;
    }
    deltas.removeWhere((_, qty) => qty == 0);
    return deltas;
  }

  Future<Result<void, DomainFailure>> _recordAdjustmentLedger(
    SaleEntity oldSale,
    SaleEntity newSale,
  ) {
    final debtDiff = newSale.debtGenerated - oldSale.debtGenerated;
    if (debtDiff == Money.zero) return Future.value(Result.ok(null));

    final isDebtIncrease = debtDiff > Money.zero;
    final entry = LedgerEntryEntity(
      id: 'led_adj_${newSale.id}_${DateTime.now().millisecondsSinceEpoch}',
      tenantId: newSale.tenantId,
      clientId: newSale.clientId,
      date: DateTime.now().toUtc(),
      type: isDebtIncrease ? LedgerEntryType.adjustmentDebt : LedgerEntryType.adjustmentCredit,
      referenceId: newSale.id,
      amount: debtDiff.abs(),
      description: 'Ajuste por modificación de Venta #${newSale.ticketNumber}',
    );

    return _ledgerRepository.recordEntry(entry);
  }
}
