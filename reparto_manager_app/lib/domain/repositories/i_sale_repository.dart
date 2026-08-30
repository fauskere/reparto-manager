// lib/domain/repositories/i_sale_repository.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/result.dart';
import '../entities/cash_summary_entity.dart';
import '../entities/sale_entity.dart';

/// Contrato abstracto para la persistencia, consulta y arqueos de ventas.
abstract class ISaleRepository {
  /// Obtiene una venta por su ID.
  Future<Result<SaleEntity, DomainFailure>> getSaleById(
    String tenantId,
    String saleId,
  );

  /// Obtiene ventas paginadas en un rango de fechas.
  Future<Result<List<SaleEntity>, DomainFailure>> getSalesByDateRange(
    String tenantId,
    DateTime startUtc,
    DateTime endUtc, {
    int limit = 50,
    int offset = 0,
  });

  /// Obtiene ventas paginadas de un cliente específico.
  Future<Result<List<SaleEntity>, DomainFailure>> getSalesByClient(
    String tenantId,
    String clientId, {
    int limit = 20,
    int offset = 0,
  });

  /// Arqueo de caja diario consolidado: físico en mano vs transferencias bancarias.
  Future<Result<CashSummaryEntity, DomainFailure>> getCashSummary(
    String tenantId,
    DateTime startUtc,
    DateTime endUtc,
  );

  /// Ranking de productos más vendidos en el período.
  Future<Result<List<Map<String, dynamic>>, DomainFailure>> getTopProducts(
    String tenantId,
    DateTime startUtc,
    DateTime endUtc, {
    int limit = 10,
  });

  /// Ranking de clientes con mayor volumen de compra en el período.
  Future<Result<List<Map<String, dynamic>>, DomainFailure>> getTopClients(
    String tenantId,
    DateTime startUtc,
    DateTime endUtc, {
    int limit = 10,
  });

  /// Registra una nueva venta en el sistema.
  Future<Result<void, DomainFailure>> saveSale(SaleEntity sale);

  /// Anula una venta previamente registrada indicando el motivo de auditoría.
  Future<Result<void, DomainFailure>> cancelSale(
    String tenantId,
    String saleId,
    String reason,
  );

  /// Obtiene el siguiente número correlativo de ticket de venta.
  Future<Result<int, DomainFailure>> getNextTicketNumber(String tenantId);
}
