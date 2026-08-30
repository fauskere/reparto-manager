// lib/domain/usecases/resolve_product_price_use_case.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/money.dart';
import '../core/result.dart';
import '../entities/client_entity.dart';
import '../entities/product_entity.dart';

/// Resuelve el precio final aplicable de un producto/variante para un cliente específico.
///
/// Jerarquía de precios:
/// 1. Precio personalizado por variante en el cliente (`customPrices[variantKey]`).
/// 2. Precio especial de la variante si el cliente es de tipo `especial`.
/// 3. Precio revendedor de la variante si el cliente es de tipo `revendedor`.
/// 4. Precio base estándar de la variante.
class ResolveProductPriceUseCase {
  const ResolveProductPriceUseCase();

  Result<Money, DomainFailure> execute({
    required ClientEntity client,
    required ProductVariant variant,
  }) {
    // 1. Prioridad absoluta: Precio personalizado por variante
    final customPrice = client.customPrices[variant.variantKey];
    if (customPrice != null) {
      return Result.ok(customPrice);
    }

    // 2. Cliente especial
    if (client.type == ClientType.especial && variant.specialPrice != null) {
      return Result.ok(variant.specialPrice!);
    }

    // 3. Cliente revendedor
    if (client.type == ClientType.revendedor && variant.resellerPrice != null) {
      return Result.ok(variant.resellerPrice!);
    }

    // 4. Precio base por defecto
    return Result.ok(variant.basePrice);
  }
}
