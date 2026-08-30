// lib/domain/repositories/i_client_group_repository.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/money.dart';
import '../core/result.dart';
import '../entities/client_group_entity.dart';

/// Contrato abstracto para la administración de agrupaciones y cadenas de clientes.
abstract class IClientGroupRepository {
  /// Obtiene todas las agrupaciones de clientes del tenant.
  Future<Result<List<ClientGroupEntity>, DomainFailure>> getClientGroups(
    String tenantId,
  );

  /// Guarda o actualiza una agrupación de clientes.
  Future<Result<void, DomainFailure>> saveClientGroup(ClientGroupEntity group);

  /// Elimina una agrupación de clientes.
  Future<Result<void, DomainFailure>> deleteClientGroup(
    String tenantId,
    String groupId,
  );

  /// Obtiene las facturas o cortes de cuenta emitidos para el grupo.
  Future<Result<List<Map<String, dynamic>>, DomainFailure>> getGroupInvoices(
    String tenantId,
    String groupId,
  );

  /// Genera un corte o comprobante consolidado de facturación para el grupo.
  Future<Result<void, DomainFailure>> createGroupInvoice(
    String tenantId,
    String groupId,
    Money totalAmount,
    List<String> saleIds,
  );

  /// Registra el pago total de un corte de facturación de grupo.
  Future<Result<void, DomainFailure>> payGroupInvoice(
    String tenantId,
    String groupId,
    String invoiceId,
  );
}
