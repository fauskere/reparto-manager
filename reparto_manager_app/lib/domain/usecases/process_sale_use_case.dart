// lib/domain/usecases/process_sale_use_case.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/money.dart';
import '../core/result.dart';
import '../entities/client_entity.dart';
import '../entities/ledger_entry_entity.dart';
import '../entities/sale_entity.dart';
import '../repositories/i_client_repository.dart';
import '../repositories/i_ledger_repository.dart';
import '../repositories/i_sale_repository.dart';
import '../repositories/i_truck_repository.dart';

/// Registra y procesa una venta completa con partida doble, deducción de stock y visita.
class ProcessSaleUseCase {
  final ISaleRepository _saleRepository;
  final ITruckRepository _truckRepository;
  final ILedgerRepository _ledgerRepository;
  final IClientRepository _clientRepository;

  const ProcessSaleUseCase(
    this._saleRepository,
    this._truckRepository,
    this._ledgerRepository,
    this._clientRepository,
  );

  Future<Result<SaleEntity, DomainFailure>> execute({
    required SaleEntity sale,
    required String truckId,
  }) async {
    final validationResult = _validateSale(sale, truckId);
    if (validationResult.isFailure) {
      return Result.fail(validationResult.failureOrNull!);
    }

    final ticketResult = await _saleRepository.getNextTicketNumber(sale.tenantId);
    if (ticketResult.isFailure) return Result.fail(ticketResult.failureOrNull!);

    final ticketNumber = ticketResult.valueOrNull!;
    final confirmedSale = sale.copyWith(ticketNumber: ticketNumber);

    final saveResult = await _saleRepository.saveSale(confirmedSale);
    if (saveResult.isFailure) return Result.fail(saveResult.failureOrNull!);

    final stockResult = await _applyStockMovement(confirmedSale, truckId);
    if (stockResult.isFailure) return Result.fail(stockResult.failureOrNull!);

    final ledgerResult = await _recordLedgerEntries(confirmedSale);
    if (ledgerResult.isFailure) return Result.fail(ledgerResult.failureOrNull!);

    await _clientRepository.updateVisitStatus(
      confirmedSale.tenantId,
      confirmedSale.clientId,
      VisitStatus.visited,
    );

    return Result.ok(confirmedSale);
  }

  Result<void, DomainFailure> _validateSale(SaleEntity sale, String truckId) {
    if (sale.tenantId.trim().isEmpty || truckId.trim().isEmpty) {
      return Result.fail(const EntityValidationFailure('tenantId y truckId son obligatorios'));
    }
    if (sale.clientId.trim().isEmpty) {
      return Result.fail(const EntityValidationFailure('clientId es obligatorio'));
    }
    if (sale.totalDiscount > sale.subtotal) {
      return Result.fail(const EntityValidationFailure('El descuento no puede superar el subtotal'));
    }
    if (sale.cashPaid + sale.transferPaid > sale.total) {
      return Result.fail(const EntityValidationFailure('El monto pagado no puede superar el total'));
    }
    if (sale.cashPaid + sale.transferPaid + sale.debtGenerated != sale.total) {
      return Result.fail(const EntityValidationFailure('Descuadre contable en total de venta'));
    }
    return Result.ok(null);
  }

  Future<Result<void, DomainFailure>> _applyStockMovement(SaleEntity sale, String truckId) {
    final deltas = <String, int>{};
    for (final item in sale.items) {
      final key = '${item.productId}|${item.variantName}';
      deltas[key] = (deltas[key] ?? 0) - item.quantity;
    }
    for (final exchange in sale.exchanges) {
      final key = '${exchange.productId}|${exchange.variantName}';
      deltas[key] = (deltas[key] ?? 0) + exchange.quantity;
    }
    return _truckRepository.applyStockDelta(sale.tenantId, truckId, deltas);
  }

  Future<Result<void, DomainFailure>> _recordLedgerEntries(SaleEntity sale) {
    final entries = <LedgerEntryEntity>[
      LedgerEntryEntity(
        id: 'led_sale_${sale.id}',
        tenantId: sale.tenantId,
        clientId: sale.clientId,
        date: sale.date,
        type: LedgerEntryType.saleDebt,
        referenceId: sale.id,
        amount: sale.total,
        description: 'Venta #${sale.ticketNumber}',
      ),
    ];

    final paidAmount = sale.cashPaid + sale.transferPaid;
    if (paidAmount > Money.zero) {
      entries.add(
        LedgerEntryEntity(
          id: 'led_pay_${sale.id}',
          tenantId: sale.tenantId,
          clientId: sale.clientId,
          date: sale.date,
          type: LedgerEntryType.paymentCredit,
          referenceId: sale.id,
          amount: paidAmount,
          description: 'Pago en acto de Venta #${sale.ticketNumber}',
        ),
      );
    }

    return _ledgerRepository.recordEntries(entries);
  }
}
