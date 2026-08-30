// lib/domain/usecases/create_group_invoice_use_case.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/money.dart';
import '../core/result.dart';
import '../repositories/i_client_group_repository.dart';

/// Genera un corte o comprobante consolidado de facturación bajo demanda para una cadena o grupo de clientes.
class CreateGroupInvoiceUseCase {
  final IClientGroupRepository _clientGroupRepository;

  const CreateGroupInvoiceUseCase(this._clientGroupRepository);

  Future<Result<void, DomainFailure>> execute({
    required String tenantId,
    required String groupId,
    required Money totalAmount,
    required List<String> saleIds,
  }) async {
    if (tenantId.trim().isEmpty || groupId.trim().isEmpty) {
      return Result.fail(const EntityValidationFailure('tenantId y groupId son obligatorios'));
    }
    if (totalAmount <= Money.zero) {
      return Result.fail(const EntityValidationFailure('El monto total de la factura grupal debe ser mayor a 0'));
    }
    if (saleIds.isEmpty) {
      return Result.fail(const EntityValidationFailure('Debe incluir al menos una venta en la factura grupal'));
    }

    return _clientGroupRepository.createGroupInvoice(
      tenantId,
      groupId,
      totalAmount,
      saleIds,
    );
  }
}
