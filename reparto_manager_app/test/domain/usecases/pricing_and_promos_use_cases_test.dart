// test/domain/usecases/pricing_and_promos_use_cases_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reparto_manager_app/domain/core/domain_failures.dart';
import 'package:reparto_manager_app/domain/core/money.dart';
import 'package:reparto_manager_app/domain/core/result.dart';
import 'package:reparto_manager_app/domain/entities/client_entity.dart';
import 'package:reparto_manager_app/domain/entities/product_entity.dart';
import 'package:reparto_manager_app/domain/entities/promotion_entity.dart';
import 'package:reparto_manager_app/domain/repositories/i_client_repository.dart';
import 'package:reparto_manager_app/domain/usecases/apply_promotion_use_case.dart';
import 'package:reparto_manager_app/domain/usecases/duplicate_client_prices_use_case.dart';
import 'package:reparto_manager_app/domain/usecases/resolve_product_price_use_case.dart';

class FakeClientRepoForPricing implements IClientRepository {
  final Map<String, ClientEntity> clients = {};

  @override
  Future<Result<ClientEntity, DomainFailure>> getClientById(String t, String c) async {
    final client = clients['$t|$c'];
    return client != null ? Result.ok(client) : Result.fail(const EntityValidationFailure('No existe'));
  }

  @override
  Future<Result<void, DomainFailure>> updateClientCustomPrices(
    String t,
    String c,
    Map<String, Money> customPrices,
  ) async {
    final client = clients['$t|$c'];
    if (client != null) {
      clients['$t|$c'] = client.copyWith(customPrices: customPrices);
    }
    return Result.ok(null);
  }

  @override
  Future<Result<void, DomainFailure>> deleteClient(String t, String c) => throw UnimplementedError();
  @override
  Future<Result<List<ClientEntity>, DomainFailure>> getClients(String t, {String? zoneId, int limit = 50, int offset = 0}) => throw UnimplementedError();
  @override
  Future<Result<void, DomainFailure>> resetVisitStatusForZone(String t, String z) => throw UnimplementedError();
  @override
  Future<Result<void, DomainFailure>> saveClient(ClientEntity c) => throw UnimplementedError();
  @override
  Future<Result<List<ClientEntity>, DomainFailure>> searchClients(String t, String q, {int limit = 20}) => throw UnimplementedError();
  @override
  Future<Result<void, DomainFailure>> updateVisitStatus(String t, String c, VisitStatus s) => throw UnimplementedError();
}

void main() {
  group('Casos de Uso: Precios y Promociones', () {
    const tenantId = 'tenant_1';

    const variant = ProductVariant(
      variantName: '500g',
      productId: 'prod_cafe',
      costPrice: Money(60000), // $600,00
      basePrice: Money(100000), // $1.000,00
      specialPrice: Money(85000), // $850,00
      resellerPrice: Money(75000), // $750,00
    );

    test('ResolveProductPriceUseCase respeta jerarquía de precios', () {
      const useCase = ResolveProductPriceUseCase();

      final normalClient = ClientEntity(
        id: 'c1',
        tenantId: tenantId,
        name: 'Kiosco Sol',
        type: ClientType.normal,
      );
      final price1 = useCase.execute(client: normalClient, variant: variant);
      expect(price1.valueOrNull, equals(Money(100000)));

      final specialClient = ClientEntity(
        id: 'c2',
        tenantId: tenantId,
        name: 'Bar Central',
        type: ClientType.especial,
      );
      final price2 = useCase.execute(client: specialClient, variant: variant);
      expect(price2.valueOrNull, equals(Money(85000)));

      final resellerClient = ClientEntity(
        id: 'c3',
        tenantId: tenantId,
        name: 'Distribuidora Norte',
        type: ClientType.revendedor,
      );
      final price3 = useCase.execute(client: resellerClient, variant: variant);
      expect(price3.valueOrNull, equals(Money(75000)));

      final customPriceClient = ClientEntity(
        id: 'c4',
        tenantId: tenantId,
        name: 'Amigo Don Mario',
        type: ClientType.normal,
        customPrices: {'prod_cafe|500g': Money(60000)},
      );
      final price4 = useCase.execute(client: customPriceClient, variant: variant);
      expect(price4.valueOrNull, equals(Money(60000)));
    });

    test('DuplicateClientPricesUseCase clona la matriz de precios a clientes destino', () async {
      final repo = FakeClientRepoForPricing();
      final source = ClientEntity(
        id: 'src_1',
        tenantId: tenantId,
        name: 'Origen',
        customPrices: {'prod_cafe|500g': Money(65000)},
      );
      final target1 = ClientEntity(id: 'dst_1', tenantId: tenantId, name: 'Destino 1');
      final target2 = ClientEntity(id: 'dst_2', tenantId: tenantId, name: 'Destino 2');

      repo.clients['$tenantId|${source.id}'] = source;
      repo.clients['$tenantId|${target1.id}'] = target1;
      repo.clients['$tenantId|${target2.id}'] = target2;

      final useCase = DuplicateClientPricesUseCase(repo);
      final result = await useCase.execute(
        tenantId: tenantId,
        sourceClientId: 'src_1',
        targetClientIds: ['dst_1', 'dst_2'],
      );

      expect(result.isSuccess, isTrue);
      expect(repo.clients['$tenantId|dst_1']!.customPrices['prod_cafe|500g'], equals(Money(65000)));
      expect(repo.clients['$tenantId|dst_2']!.customPrices['prod_cafe|500g'], equals(Money(65000)));
    });

    test('ApplyPromotionUseCase evalúa elegibilidad y aplica porcentaje exacto', () {
      const useCase = ApplyPromotionUseCase();
      final promo = PromotionEntity(
        id: 'promo_combo',
        tenantId: tenantId,
        name: 'Combo Café + Galletitas',
        requiredItems: {'prod_cafe|500g': 2, 'prod_galleta|Pack': 1},
        discountPercentage: 20.0,
      );

      // Carrito no elegible
      final nonEligible = useCase.execute(
        promotion: promo,
        cartItems: {'prod_cafe|500g': 1},
        eligibleSubtotal: Money.fromUnits(1000),
      );
      expect(nonEligible.valueOrNull, equals(Money.zero));

      // Carrito elegible: $10.000 al 20% = $2.000 de descuento
      final eligible = useCase.execute(
        promotion: promo,
        cartItems: {'prod_cafe|500g': 2, 'prod_galleta|Pack': 1},
        eligibleSubtotal: Money.fromUnits(10000),
      );
      expect(eligible.valueOrNull, equals(Money.fromUnits(2000)));
    });
  });
}
