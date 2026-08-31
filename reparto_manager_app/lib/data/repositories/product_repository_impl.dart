// lib/data/repositories/product_repository_impl.dart
// Capa de Datos e Infraestructura SQLite - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../domain/core/domain_failures.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/i_product_repository.dart';
import '../database/app_database.dart';
import '../models/product_model.dart';
import 'sync_queue_helper.dart';

/// Implementación local de [IProductRepository] basada en SQLite.
class ProductRepositoryImpl implements IProductRepository {
  final AppDatabase _appDatabase;

  ProductRepositoryImpl([AppDatabase? appDatabase])
      : _appDatabase = appDatabase ?? AppDatabase();

  @override
  Future<Result<List<ProductEntity>, DomainFailure>> getActiveProducts(
    String tenantId, {
    String? category,
  }) async {
    try {
      final db = await _appDatabase.database;
      final String whereClause;
      final List<dynamic> whereArgs;

      if (category != null && category.trim().isNotEmpty) {
        whereClause = 'tenantId = ? AND isActive = 1 AND category = ?';
        whereArgs = [tenantId, category.trim()];
      } else {
        whereClause = 'tenantId = ? AND isActive = 1';
        whereArgs = [tenantId];
      }

      final rows = await db.query(
        'products',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'name ASC',
      );

      final list = rows.map((r) => ProductModel.fromMap(r).toEntity()).toList();
      return Result.ok(list);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al listar productos activos', e));
    }
  }

  @override
  Future<Result<ProductEntity, DomainFailure>> getProductById(
    String tenantId,
    String productId,
  ) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        'products',
        where: 'tenantId = ? AND id = ?',
        whereArgs: [tenantId, productId],
        limit: 1,
      );
      if (rows.isEmpty) {
        return Result.fail(const DatabaseFailure('Producto no encontrado'));
      }
      return Result.ok(ProductModel.fromMap(rows.first).toEntity());
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al obtener producto por ID', e));
    }
  }

  @override
  Future<Result<ProductEntity, DomainFailure>> getProductByBarcode(
    String tenantId,
    String barcode,
  ) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        'products',
        where: 'tenantId = ? AND barcode = ?',
        whereArgs: [tenantId, barcode.trim()],
        limit: 1,
      );
      if (rows.isEmpty) {
        return Result.fail(const DatabaseFailure('Producto no encontrado por código'));
      }
      return Result.ok(ProductModel.fromMap(rows.first).toEntity());
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al buscar por código de barras', e));
    }
  }

  @override
  Future<Result<List<ProductEntity>, DomainFailure>> searchProducts(
    String tenantId,
    String query, {
    int limit = 20,
  }) async {
    try {
      final db = await _appDatabase.database;
      final cleanQuery = '%${query.trim()}%';
      final rows = await db.query(
        'products',
        where: 'tenantId = ? AND isActive = 1 AND name LIKE ?',
        whereArgs: [tenantId, cleanQuery],
        orderBy: 'name ASC',
        limit: limit,
      );

      final list = rows.map((r) => ProductModel.fromMap(r).toEntity()).toList();
      return Result.ok(list);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al buscar productos', e));
    }
  }

  @override
  Future<Result<List<String>, DomainFailure>> getCategories(String tenantId) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.rawQuery(
        'SELECT DISTINCT category FROM products WHERE tenantId = ? AND isActive = 1 ORDER BY category ASC',
        [tenantId],
      );

      final categories = rows
          .map((r) => (r['category'] as String?)?.trim() ?? '')
          .where((c) => c.isNotEmpty)
          .toList();
      return Result.ok(categories);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al obtener categorías', e));
    }
  }

  @override
  Future<Result<void, DomainFailure>> saveProduct(ProductEntity product) async {
    try {
      final db = await _appDatabase.database;
      final model = ProductModel.fromEntity(product);
      final map = model.toMap();

      await db.transaction((txn) async {
        final existingRows = await txn.query(
          'products',
          where: 'tenantId = ? AND id = ?',
          whereArgs: [product.tenantId, product.id],
          limit: 1,
        );

        if (existingRows.isNotEmpty) {
          final oldProduct = ProductModel.fromMap(existingRows.first).toEntity();
          await _auditPriceChanges(txn, oldProduct, product);
        }

        await txn.insert('products', map, conflictAlgorithm: ConflictAlgorithm.replace);
        await SyncQueueHelper.enqueueOperation(
          executor: txn,
          tenantId: product.tenantId,
          collectionName: 'products',
          documentId: product.id,
          operation: 'create',
          payload: map,
        );
      });
      return Result.ok(null);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al guardar producto', e));
    }
  }

  @override
  Future<Result<void, DomainFailure>> deleteProduct(
    String tenantId,
    String productId,
  ) async {
    try {
      final db = await _appDatabase.database;
      await db.transaction((txn) async {
        await txn.update(
          'products',
          {'isActive': 0},
          where: 'tenantId = ? AND id = ?',
          whereArgs: [tenantId, productId],
        );
        await SyncQueueHelper.enqueueOperation(
          executor: txn,
          tenantId: tenantId,
          collectionName: 'products',
          documentId: productId,
          operation: 'delete',
          payload: {'id': productId, 'isActive': 0},
        );
      });
      return Result.ok(null);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al desactivar producto', e));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>, DomainFailure>> getPriceHistory(
    String tenantId,
    String productId,
  ) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        'price_history',
        where: 'tenantId = ? AND productId = ?',
        whereArgs: [tenantId, productId],
        orderBy: 'changedAtUtc DESC',
      );
      return Result.ok(rows);
    } catch (e) {
      return Result.fail(DatabaseFailure('Error al consultar historial de precios', e));
    }
  }

  Future<void> _auditPriceChanges(
    DatabaseExecutor txn,
    ProductEntity oldProduct,
    ProductEntity newProduct,
  ) async {
    final nowStr = DateTime.now().toUtc().toIso8601String();
    for (final newVariant in newProduct.variants) {
      final match = oldProduct.variants.where((v) => v.variantName == newVariant.variantName);
      if (match.isNotEmpty) {
        final oldVariant = match.first;
        if (oldVariant.basePrice.cents != newVariant.basePrice.cents) {
          final historyId = 'ph_${newProduct.id}_${newVariant.variantName}_${DateTime.now().microsecondsSinceEpoch}';
          await txn.insert('price_history', {
            'id': historyId,
            'tenantId': newProduct.tenantId,
            'productId': newProduct.id,
            'productName': newProduct.name,
            'variantName': newVariant.variantName,
            'oldPriceCents': oldVariant.basePrice.cents,
            'newPriceCents': newVariant.basePrice.cents,
            'changedAtUtc': nowStr,
          });
        }
      }
    }
  }
}
