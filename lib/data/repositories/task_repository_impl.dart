import 'package:drift/drift.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/result.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/task_model.dart';
import '../../data/database/app_database.dart';
import '../../domain/repositories/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  final ApiClient _apiClient;
  final AppDatabase _database;

  TaskRepositoryImpl(this._apiClient, this._database);

  @override
  Future<Result<List<TaskModel>>> getTasks({
    String? crop,
    DateTime? date,
    bool forceRefresh = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (crop != null) queryParams['crop'] = crop;
      if (date != null) {
        queryParams['date'] = date.toIso8601String().split('T')[0];
      }

      // Try API first
      if (forceRefresh || await _isOnline()) {
        final result = await _apiClient.get<List<TaskModel>>(
          ApiConstants.tasks,
          queryParameters: queryParams.isEmpty ? null : queryParams,
          fromJson: (data) {
            if (data is List) {
              return data.map((json) => TaskModel.fromJson(json)).toList();
            }
            return [];
          },
        );

        result.when(
          success: (tasks) async {
            await _cacheTasks(tasks);
            return tasks;
          },
          failure: (_) {
            // Fall through to cache
          },
        );
      }

      // Get from cache
      if (crop != null && date != null) {
        final cachedTasks = await _database.getTasksByCropAndDate(crop, date);
        if (cachedTasks.isNotEmpty) {
          return Result.success(
            cachedTasks.map((t) => _taskFromTable(t)).toList(),
          );
        }
      }

      return Result.failure(
        const Failure.network(message: 'No tasks found and offline'),
      );
    } catch (e) {
      // Try cache
      if (crop != null && date != null) {
        final cachedTasks = await _database.getTasksByCropAndDate(crop, date);
        if (cachedTasks.isNotEmpty) {
          return Result.success(
            cachedTasks.map((t) => _taskFromTable(t)).toList(),
          );
        }
      }
      return Result.failure(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<TaskModel>> getTaskById(String id) async {
    try {
      final result = await _apiClient.get<TaskModel>(
        '${ApiConstants.taskById}/$id',
        fromJson: (data) => TaskModel.fromJson(data),
      );

      return result.when(
        success: (task) async {
          await _cacheTask(task);
          return Result.success(task);
        },
        failure: (_) {
          return Result.failure(
            const Failure.network(message: 'Task not found'),
          );
        },
      );
    } catch (e) {
      return Result.failure(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<TaskModel>> createTask(TaskModel task) async {
    try {
      final result = await _apiClient.post<TaskModel>(
        ApiConstants.tasks,
        data: task.toJson(),
        fromJson: (data) => TaskModel.fromJson(data),
      );

      return result.when(
        success: (createdTask) async {
          await _cacheTask(createdTask);
          return Result.success(createdTask);
        },
        failure: (failure) {
          // Save locally for sync later
          _cacheTask(task);
          return Result.failure(failure);
        },
      );
    } catch (e) {
      return Result.failure(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<TaskModel>> updateTask(TaskModel task) async {
    try {
      final result = await _apiClient.put<TaskModel>(
        '${ApiConstants.taskById}/${task.id}',
        data: task.toJson(),
        fromJson: (data) => TaskModel.fromJson(data),
      );

      return result.when(
        success: (updatedTask) async {
          await _cacheTask(updatedTask);
          return Result.success(updatedTask);
        },
        failure: (failure) {
          _cacheTask(task);
          return Result.failure(failure);
        },
      );
    } catch (e) {
      return Result.failure(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteTask(String id) async {
    try {
      final result = await _apiClient.delete('${ApiConstants.taskById}/$id');
      await _database.deleteTask(id);
      return result;
    } catch (e) {
      await _database.deleteTask(id);
      return Result.failure(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> markTaskComplete(String id, bool isCompleted) async {
    try {
      await _database.updateTaskCompletion(id, isCompleted);
      // Optionally sync to API
      return const Result.success(null);
    } catch (e) {
      return Result.failure(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<List<TaskModel>>> getTasksByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final result = await _apiClient.get<List<TaskModel>>(
        ApiConstants.tasks,
        queryParameters: {
          'start_date': startDate.toIso8601String().split('T')[0],
          'end_date': endDate.toIso8601String().split('T')[0],
        },
        fromJson: (data) {
          if (data is List) {
            return data.map((json) => TaskModel.fromJson(json)).toList();
          }
          return [];
        },
      );
      return result;
    } catch (e) {
      return Result.failure(Failure.unknown(message: e.toString()));
    }
  }

  // Helper methods
  Future<bool> _isOnline() async {
    return true; // Assume online for now
  }

  Future<void> _cacheTasks(List<TaskModel> tasks) async {
    for (final task in tasks) {
      await _cacheTask(task);
    }
  }

  Future<void> _cacheTask(TaskModel task) async {
    await _database.insertTask(
      TasksCompanion.insert(
        id: task.id,
        crop: task.crop,
        date: task.date,
        time: task.time,
        title: task.title,
        subtitle: Value(task.subtitle),
        isCompleted: Value(task.isCompleted),
        completedAt: Value(task.completedAt),
        createdAt: task.createdAt,
        updatedAt: Value(task.updatedAt),
        cachedAt: DateTime.now(),
      ),
    );
  }

  TaskModel _taskFromTable(Task task) {
    return TaskModel(
      id: task.id,
      crop: task.crop,
      date: task.date,
      time: task.time,
      title: task.title,
      subtitle: task.subtitle,
      isCompleted: task.isCompleted,
      completedAt: task.completedAt,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
    );
  }
}

