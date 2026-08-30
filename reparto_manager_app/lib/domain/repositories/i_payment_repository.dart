// lib/domain/repositories/i_payment_repository.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/result.dart';
import '../entities/payment_entity.dart';

/// Contrato abstracto para el registro y consulta de cobranzas/pagos.
abstract class IPaymentRepository {
  /// Registra una nueva cobranza o entrega de dinero.
  Future<Result<void, DomainFailure>> savePayment(PaymentEntity payment);

  /// Anula un recibo de cobranza indicando el motivo de auditoría.
  Future<Result<void, DomainFailure>> cancelPayment(
    String tenantId,
    String paymentId,
    String reason,
  );

  /// Obtiene los pagos paginados de un cliente.
  Future<Result<List<PaymentEntity>, DomainFailure>> getPaymentsByClient(
    String tenantId,
    String clientId, {
    int limit = 20,
    int offset = 0,
  });

  /// Obtiene los pagos paginados en un rango de fechas.
  Future<Result<List<PaymentEntity>, DomainFailure>> getPaymentsByDateRange(
    String tenantId,
    DateTime startUtc,
    DateTime endUtc, {
    int limit = 50,
    int offset = 0,
  });

  /// Obtiene el siguiente número correlativo de recibo de cobro.
  Future<Result<int, DomainFailure>> getNextReceiptNumber(String tenantId);
}
