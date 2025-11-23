import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../data/models/product_model.dart';
import 'auth_provider.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final authService = ref.watch(authServiceProvider);
  return ApiClient(authService);
});

final productRepositoryProvider = Provider<ProductRepositoryImpl>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProductRepositoryImpl(apiClient);
});

final productsProvider = FutureProvider.family<List<ProductModel>, String?>((ref, category) async {
  final repository = ref.watch(productRepositoryProvider);
  final result = await repository.getProducts(category: category);
  
  return result.when(
    success: (products) => products,
    failure: (_) => [],
  );
});

final productByIdProvider = FutureProvider.family<ProductModel?, int>((ref, id) async {
  final repository = ref.watch(productRepositoryProvider);
  final result = await repository.getProductById(id);
  
  return result.when(
    success: (product) => product,
    failure: (_) => null,
  );
});

final productSearchProvider = FutureProvider.family<List<ProductModel>, String>((ref, query) async {
  final repository = ref.watch(productRepositoryProvider);
  final result = await repository.searchProducts(query);
  
  return result.when(
    success: (products) => products,
    failure: (_) => [],
  );
});

