// lib/domain/usecases/pay_group_invoice_use_case.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/money.dart';
import '../core/result.dart';
import '../entities/ledger_entry_entity.dart';
import '../repositories/i_client_group_repository.dart';
import '../repositories/i_ledger_repository.dart';

/// Registra el pago consolidado de una factura de grupo y asienta el crédito contable.
class PayGroupInvoiceUseCase {
  final IClientGroupRepository _clientGroupRepository;
  final ILedgerRepository _ledgerRepository;

  const PayGroupInvoiceUseCase(
    this._clientGroupRepository,
    this._ledgerRepository,
  );

  Future<Result<void, DomainFailure>> execute({
    required String tenantId,
    required String groupId,
    required String invoiceId,
    required String mainClientId,
    required Money amount,
  }) async {
    if (tenantId.trim().isEmpty || groupId.trim().isEmpty || invoiceId.trim().isEmpty) {
      return Result.fail(const EntityValidationFailure('tenantId, groupId e invoiceId son obligatorios'));
    }
    if (mainClientId.trim().isEmpty) {
      return Result.fail(const EntityValidationFailure('mainClientId es obligatorio para asentar el crédito'));
    }
    if (amount <= Money.zero) {
      return Result.fail(const EntityValidationFailure('El monto pagado debe ser mayor a 0'));
    }

    final payResult = await _clientGroupRepository.payGroupInvoice(
      tenantId,
      groupId,
      invoiceId,
    );
    if (payResult.isFailure) return Result.fail(payResult.failureOrNull!);

    final ledgerEntry = LedgerEntryEntity(
      id: 'led_grp_pay_${invoiceId}_${DateTime.now().millisecondsSinceEpoch}',
      tenantId: tenantId,
      clientId: mainClientId,
      date: DateTime.now().toUtc(),
      type: LedgerEntryType.paymentCredit,
      referenceId: invoiceId,
      amount: amount,
      description: 'Pago consolidado de Factura Grupal #$invoiceId',
    );

    return _ledgerRepository.recordEntry(ledgerEntry);
  }
}
