import '../../core/utils/result.dart';
import '../../data/models/task_model.dart';

abstract class TaskRepository {
  Future<Result<List<TaskModel>>> getTasks({
    String? crop,
    DateTime? date,
    bool forceRefresh = false,
  });
  
  Future<Result<TaskModel>> getTaskById(String id);
  
  Future<Result<TaskModel>> createTask(TaskModel task);
  
  Future<Result<TaskModel>> updateTask(TaskModel task);
  
  Future<Result<void>> deleteTask(String id);
  
  Future<Result<void>> markTaskComplete(String id, bool isCompleted);
  
  Future<Result<List<TaskModel>>> getTasksByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
}

