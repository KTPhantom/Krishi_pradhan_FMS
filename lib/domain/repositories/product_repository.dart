import '../../core/utils/result.dart';
import '../../data/models/product_model.dart';

abstract class ProductRepository {
  Future<Result<List<ProductModel>>> getProducts({
    String? category,
    bool forceRefresh = false,
  });
  
  Future<Result<ProductModel>> getProductById(int id);
  
  Future<Result<List<ProductModel>>> searchProducts(String query);
}

