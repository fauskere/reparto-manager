// lib/domain/repositories/i_promotion_repository.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/result.dart';
import '../entities/promotion_entity.dart';

/// Contrato abstracto para la administración de promociones comerciales.
abstract class IPromotionRepository {
  /// Obtiene todas las promociones activas para el tenant.
  Future<Result<List<PromotionEntity>, DomainFailure>> getActivePromotions(
    String tenantId,
  );

  /// Guarda o actualiza una promoción.
  Future<Result<void, DomainFailure>> savePromotion(PromotionEntity promotion);

  /// Elimina una promoción.
  Future<Result<void, DomainFailure>> deletePromotion(
    String tenantId,
    String promotionId,
  );
}
