// lib/domain/usecases/apply_promotion_use_case.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/money.dart';
import '../core/result.dart';
import '../entities/promotion_entity.dart';

/// Evalúa la elegibilidad de una promoción comercial y calcula el monto exacto de descuento.
class ApplyPromotionUseCase {
  const ApplyPromotionUseCase();

  Result<Money, DomainFailure> execute({
    required PromotionEntity promotion,
    required Map<String, int> cartItems,
    required Money eligibleSubtotal,
  }) {
    if (!promotion.isActive) {
      return Result.ok(Money.zero);
    }

    if (!promotion.isEligible(cartItems)) {
      return Result.ok(Money.zero);
    }

    if (eligibleSubtotal <= Money.zero) {
      return Result.ok(Money.zero);
    }

    final discountCents = (eligibleSubtotal.cents * (promotion.discountPercentage / 100.0)).round();
    final discountMoney = Money(discountCents);

    // El descuento nunca puede ser superior al subtotal
    if (discountMoney > eligibleSubtotal) {
      return Result.ok(eligibleSubtotal);
    }

    return Result.ok(discountMoney);
  }
}
