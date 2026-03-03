import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/field_repository_impl.dart';
import '../models/field/field_model.dart';
import 'database_controller.dart';
import 'product_controller.dart';

final fieldRepositoryProvider = Provider<FieldRepositoryImpl>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final database = ref.watch(databaseProvider);
  return FieldRepositoryImpl(apiClient, database);
});

final fieldsProvider = FutureProvider<List<FieldModel>>((ref) async {
  final repository = ref.watch(fieldRepositoryProvider);
  final result = await repository.getFields();
  
  return result.when(
    success: (fields) => fields,
    failure: (_) => [],
  );
});

final fieldByIdProvider = FutureProvider.family<FieldModel?, String>((ref, id) async {
  final repository = ref.watch(fieldRepositoryProvider);
  final result = await repository.getFieldById(id);
  
  return result.when(
    success: (field) => field,
    failure: (_) => null,
  );
});

