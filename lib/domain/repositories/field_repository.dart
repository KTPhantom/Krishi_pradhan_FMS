import '../../core/utils/result.dart';
import '../../data/models/field_model.dart';

abstract class FieldRepository {
  Future<Result<List<FieldModel>>> getFields({bool forceRefresh = false});
  
  Future<Result<FieldModel>> getFieldById(String id);
  
  Future<Result<FieldModel>> createField(FieldModel field);
  
  Future<Result<FieldModel>> updateField(FieldModel field);
  
  Future<Result<void>> deleteField(String id);
  
  Future<Result<List<FieldModel>>> searchFields(String query);
}

