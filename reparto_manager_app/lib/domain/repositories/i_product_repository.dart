// lib/domain/repositories/i_product_repository.dart
// Capa de Dominio Puro - Reparto-Manager V2

import '../core/domain_failures.dart';
import '../core/result.dart';
import '../entities/product_entity.dart';

/// Contrato abstracto para el catálogo de productos y variantes.
abstract class IProductRepository {
  /// Obtiene los productos activos del tenant, opcionalmente filtrados por categoría.
  Future<Result<List<ProductEntity>, DomainFailure>> getActiveProducts(
    String tenantId, {
    String? category,
  });

  /// Obtiene un producto por su ID.
  Future<Result<ProductEntity, DomainFailure>> getProductById(
    String tenantId,
    String productId,
  );

  /// Busca un producto por su código de barras.
  Future<Result<ProductEntity, DomainFailure>> getProductByBarcode(
    String tenantId,
    String barcode,
  );

  /// Busca productos por coincidencia de nombre o variante.
  Future<Result<List<ProductEntity>, DomainFailure>> searchProducts(
    String tenantId,
    String query, {
    int limit = 20,
  });

  /// Obtiene la lista de categorías existentes en el catálogo del tenant.
  Future<Result<List<String>, DomainFailure>> getCategories(String tenantId);

  /// Guarda o actualiza un producto con sus variantes.
  Future<Result<void, DomainFailure>> saveProduct(ProductEntity product);

  /// Elimina o desactiva lógicamente un producto.
  Future<Result<void, DomainFailure>> deleteProduct(
    String tenantId,
    String productId,
  );

  /// Obtiene el historial de cambios de precio para auditoría.
  Future<Result<List<Map<String, dynamic>>, DomainFailure>> getPriceHistory(
    String tenantId,
    String productId,
  );
}
