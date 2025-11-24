import 'package:drift/drift.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/result.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/product_model.dart';
import '../../data/database/app_database.dart';
import '../../domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ApiClient _apiClient;
  final AppDatabase _database;
  
  ProductRepositoryImpl(this._apiClient, this._database);
  
  @override
  Future<Result<List<ProductModel>>> getProducts({
    String? category,
    bool forceRefresh = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category != 'All') {
        queryParams['category'] = category;
      }
      
      // Try API first
      if (forceRefresh || await _isOnline()) {
        final apiResult = await _apiClient.get<List<ProductModel>>(
          ApiConstants.products,
          queryParameters: queryParams.isEmpty ? null : queryParams,
          fromJson: (data) {
            if (data is List) {
              return data.map((json) => ProductModel.fromJson(json)).toList();
            }
            return [];
          },
        );

        return await apiResult.when(
          success: (products) async {
            await _cacheProducts(products);
            final filtered = _filterByCategory(products, category);
            return Result.success(filtered);
          },
          failure: (failure) async {
            final cached = await _getProductsFromCache(category);
            if (cached != null) {
              return Result.success(cached);
            }
            return Result.failure(failure);
          },
        );
      }

      final cached = await _getProductsFromCache(category);
      if (cached != null) {
        return Result.success(cached);
      }

      return const Result.failure(
        Failure.network(message: 'No products found and offline'),
      );
    } catch (e) {
      final cached = await _getProductsFromCache(category);
      if (cached != null) {
        return Result.success(cached);
      }
      return Result.failure(Failure.unknown(message: e.toString()));
    }
  }
  
  @override
  Future<Result<ProductModel>> getProductById(int id) async {
    try {
      // Try API first
      final result = await _apiClient.get<ProductModel>(
        '${ApiConstants.productById}/$id',
        fromJson: (data) => ProductModel.fromJson(data),
      );

      return result.when(
        success: (product) async {
          await _cacheProduct(product);
          return Result.success(product);
        },
        failure: (_) async {
          // Try cache
          final cached = await _database.getProductById(id);
          if (cached != null) {
            return Result.success(_productFromTable(cached));
          }
          return Result.failure(
            const Failure.network(message: 'Product not found'),
          );
        },
      );
    } catch (e) {
      // Try cache
      final cached = await _database.getProductById(id);
      if (cached != null) {
        return Result.success(_productFromTable(cached));
      }
      return Result.failure(Failure.unknown(message: e.toString()));
    }
  }
  
  @override
  Future<Result<List<ProductModel>>> searchProducts(String query) async {
    try {
      final result = await _apiClient.get<List<ProductModel>>(
        ApiConstants.products,
        queryParameters: {'search': query},
        fromJson: (data) {
          if (data is List) {
            return data.map((json) => ProductModel.fromJson(json)).toList();
          }
          return [];
        },
      );

      return result.when(
        success: (products) => Result.success(products),
        failure: (_) async {
          // Search in cache
          final cached = await _database.getAllProducts();
          final filtered = cached.where((p) {
            return p.name.toLowerCase().contains(query.toLowerCase()) ||
                   p.category.toLowerCase().contains(query.toLowerCase());
          }).map((p) => _productFromTable(p)).toList();
          return Result.success(filtered);
        },
      );
    } catch (e) {
      return Result.failure(Failure.unknown(message: e.toString()));
    }
  }

  // Helper methods
  Future<bool> _isOnline() async {
    return true; // Assume online for now
  }

  Future<void> _cacheProducts(List<ProductModel> products) async {
    for (final product in products) {
      await _cacheProduct(product);
    }
  }

  Future<void> _cacheProduct(ProductModel product) async {
    await _database.insertProduct(
      ProductsCompanion.insert(
        id: Value(product.id),
        name: product.name,
        category: product.category,
        price: product.price,
        unit: product.unit,
        rating: product.rating,
        imageUrl: Value(product.imageUrl),
        description: Value(product.description),
        stock: Value(product.stock),
        brand: Value(product.brand),
        createdAt: Value(product.createdAt),
        cachedAt: DateTime.now(),
      ),
    );
  }

  ProductModel _productFromTable(Product product) {
    return ProductModel(
      id: product.id,
      name: product.name,
      category: product.category,
      price: product.price,
      unit: product.unit,
      rating: product.rating,
      imageUrl: product.imageUrl,
      description: product.description,
      stock: product.stock,
      brand: product.brand,
      createdAt: product.createdAt,
    );
  }

  List<ProductModel> _filterByCategory(List<ProductModel> products, String? category) {
    if (category == null || category == 'All') return products;
    return products.where((p) => p.category == category).toList();
  }

  Future<List<ProductModel>?> _getProductsFromCache(String? category) async {
    final cachedProducts = await _database.getAllProducts();
    if (cachedProducts.isEmpty) return null;
    var filtered = cachedProducts.map((p) => _productFromTable(p)).toList();
    if (category != null && category != 'All') {
      filtered = filtered.where((p) => p.category == category).toList();
    }
    return filtered;
  }
}

