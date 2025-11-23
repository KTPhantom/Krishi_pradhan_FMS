import '../../core/network/api_client.dart';
import '../../core/utils/result.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/product_model.dart';
import '../../domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ApiClient _apiClient;
  
  ProductRepositoryImpl(this._apiClient);
  
  @override
  Future<Result<List<ProductModel>>> getProducts({
    String? category,
    bool forceRefresh = false,
  }) async {
    final queryParams = <String, dynamic>{};
    if (category != null && category != 'All') {
      queryParams['category'] = category;
    }
    
    return await _apiClient.get<List<ProductModel>>(
      ApiConstants.products,
      queryParameters: queryParams.isEmpty ? null : queryParams,
      fromJson: (data) {
        if (data is List) {
          return data.map((json) => ProductModel.fromJson(json)).toList();
        }
        return [];
      },
    );
  }
  
  @override
  Future<Result<ProductModel>> getProductById(int id) async {
    return await _apiClient.get<ProductModel>(
      '${ApiConstants.productById}/$id',
      fromJson: (data) => ProductModel.fromJson(data),
    );
  }
  
  @override
  Future<Result<List<ProductModel>>> searchProducts(String query) async {
    return await _apiClient.get<List<ProductModel>>(
      ApiConstants.products,
      queryParameters: {'search': query},
      fromJson: (data) {
        if (data is List) {
          return data.map((json) => ProductModel.fromJson(json)).toList();
        }
        return [];
      },
    );
  }
}

