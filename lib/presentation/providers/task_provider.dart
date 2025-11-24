import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../data/models/task_model.dart';
import 'database_provider.dart';
import 'auth_provider.dart';
import 'product_provider.dart';

final taskRepositoryProvider = Provider<TaskRepositoryImpl>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final database = ref.watch(databaseProvider);
  return TaskRepositoryImpl(apiClient, database);
});

final tasksProvider = FutureProvider.family<List<TaskModel>, TaskQuery>((ref, query) async {
  final repository = ref.watch(taskRepositoryProvider);
  final result = await repository.getTasks(
    crop: query.crop,
    date: query.date,
  );
  
  return result.when(
    success: (tasks) => tasks,
    failure: (_) => [],
  );
});

class TaskQuery {
  final String? crop;
  final DateTime? date;

  TaskQuery({this.crop, this.date});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskQuery &&
          runtimeType == other.runtimeType &&
          crop == other.crop &&
          date?.toIso8601String() == other.date?.toIso8601String();

  @override
  int get hashCode => crop.hashCode ^ date.hashCode;
}

