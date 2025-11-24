import 'package:drift/drift.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/result.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/field_model.dart';
import '../../data/database/app_database.dart';
import '../../domain/repositories/field_repository.dart';

class FieldRepositoryImpl implements FieldRepository {
  final ApiClient _apiClient;
  final AppDatabase _database;

  FieldRepositoryImpl(this._apiClient, this._database);

  @override
  Future<Result<List<FieldModel>>> getFields({bool forceRefresh = false}) async {
    try {
      // Try to get from API first
      if (forceRefresh || await _isOnline()) {
        final result = await _apiClient.get<List<FieldModel>>(
          ApiConstants.fields,
          fromJson: (data) {
            if (data is List) {
              return data.map((json) => FieldModel.fromJson(json)).toList();
            }
            return [];
          },
        );

        result.when(
          success: (fields) async {
            // Cache in local database
            await _cacheFields(fields);
            return fields;
          },
          failure: (_) {
            // Fall through to cache
          },
        );
      }

      // Get from cache
      final cachedFields = await _database.getAllFields();
      if (cachedFields.isNotEmpty) {
        return Result.success(
          cachedFields.map((f) => _fieldFromTable(f)).toList(),
        );
      }

      return Result.failure(
        const Failure.network(message: 'No fields found and offline'),
      );
    } catch (e) {
      // Try cache as fallback
      final cachedFields = await _database.getAllFields();
      if (cachedFields.isNotEmpty) {
        return Result.success(
          cachedFields.map((f) => _fieldFromTable(f)).toList(),
        );
      }
      return Result.failure(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<FieldModel>> getFieldById(String id) async {
    try {
      // Try API first
      final result = await _apiClient.get<FieldModel>(
        '${ApiConstants.fieldById}/$id',
        fromJson: (data) => FieldModel.fromJson(data),
      );

      return result.when(
        success: (field) async {
          await _cacheField(field);
          return Result.success(field);
        },
        failure: (_) async {
          // Try cache
          final cached = await _database.getFieldById(id);
          if (cached != null) {
            return Result.success(_fieldFromTable(cached));
          }
          return Result.failure(
            const Failure.network(message: 'Field not found'),
          );
        },
      );
    } catch (e) {
      // Try cache
      final cached = await _database.getFieldById(id);
      if (cached != null) {
        return Result.success(_fieldFromTable(cached));
      }
      return Result.failure(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<FieldModel>> createField(FieldModel field) async {
    try {
      final result = await _apiClient.post<FieldModel>(
        ApiConstants.fields,
        data: field.toJson(),
        fromJson: (data) => FieldModel.fromJson(data),
      );

      return result.when(
        success: (createdField) async {
          await _cacheField(createdField);
          return Result.success(createdField);
        },
        failure: (failure) {
          // Save locally for sync later
          _cacheField(field);
          return Result.failure(failure);
        },
      );
    } catch (e) {
      return Result.failure(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<FieldModel>> updateField(FieldModel field) async {
    try {
      final result = await _apiClient.put<FieldModel>(
        '${ApiConstants.fieldById}/${field.id}',
        data: field.toJson(),
        fromJson: (data) => FieldModel.fromJson(data),
      );

      return result.when(
        success: (updatedField) async {
          await _cacheField(updatedField);
          return Result.success(updatedField);
        },
        failure: (failure) {
          // Update local cache
          _cacheField(field);
          return Result.failure(failure);
        },
      );
    } catch (e) {
      return Result.failure(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteField(String id) async {
    try {
      final result = await _apiClient.delete('${ApiConstants.fieldById}/$id');
      await _database.deleteField(id);
      return result;
    } catch (e) {
      // Delete from cache anyway
      await _database.deleteField(id);
      return Result.failure(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Result<List<FieldModel>>> searchFields(String query) async {
    try {
      final result = await _apiClient.get<List<FieldModel>>(
        ApiConstants.fields,
        queryParameters: {'search': query},
        fromJson: (data) {
          if (data is List) {
            return data.map((json) => FieldModel.fromJson(json)).toList();
          }
          return [];
        },
      );

      return result.when(
        success: (fields) {
          // Filter cached fields if API fails
          return Result.success(fields.where((f) {
            return f.crop.toLowerCase().contains(query.toLowerCase()) ||
                   f.id.toLowerCase().contains(query.toLowerCase());
          }).toList());
        },
        failure: (_) async {
          // Search in cache
          final cached = await _database.getAllFields();
          final filtered = cached.where((f) {
            return f.crop.toLowerCase().contains(query.toLowerCase()) ||
                   f.id.toLowerCase().contains(query.toLowerCase());
          }).map((f) => _fieldFromTable(f)).toList();
          return Result.success(filtered);
        },
      );
    } catch (e) {
      return Result.failure(Failure.unknown(message: e.toString()));
    }
  }

  // Helper methods
  Future<bool> _isOnline() async {
    // Simple check - in production, use connectivity_plus package
    return true; // Assume online for now
  }

  Future<void> _cacheFields(List<FieldModel> fields) async {
    for (final field in fields) {
      await _cacheField(field);
    }
  }

  Future<void> _cacheField(FieldModel field) async {
    // Convert coordinates map to JSON string
    String? coordinatesJson;
    if (field.coordinates != null) {
      coordinatesJson = field.coordinates!.entries
          .map((e) => '${e.key}:${e.value}')
          .join(',');
    }

    await _database.insertField(
      FieldsCompanion.insert(
        id: field.id,
        crop: field.crop,
        area: field.area,
        waterSource: field.waterSource,
        location: Value(field.location),
        coordinates: Value(coordinatesJson),
        plantingDate: Value(field.plantingDate),
        harvestDate: Value(field.harvestDate),
        status: Value(field.status),
        createdAt: field.createdAt,
        updatedAt: Value(field.updatedAt),
        cachedAt: DateTime.now(),
      ),
    );
  }

  FieldModel _fieldFromTable(Field field) {
    // Parse coordinates from JSON string
    Map<String, double>? coordinates;
    if (field.coordinates != null && field.coordinates!.isNotEmpty) {
      try {
        final parts = field.coordinates!.split(',');
        coordinates = {};
        for (final part in parts) {
          final keyValue = part.split(':');
          if (keyValue.length == 2) {
            final key = keyValue[0].trim();
            final value = double.tryParse(keyValue[1].trim());
            if (value != null) {
              coordinates[key] = value;
            }
          }
        }
      } catch (e) {
        coordinates = null;
      }
    }

    return FieldModel(
      id: field.id,
      crop: field.crop,
      area: field.area,
      waterSource: field.waterSource,
      location: field.location,
      coordinates: coordinates,
      plantingDate: field.plantingDate,
      harvestDate: field.harvestDate,
      status: field.status,
      createdAt: field.createdAt,
      updatedAt: field.updatedAt,
    );
  }
}

