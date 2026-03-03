import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';

/// Centralized API service for all backend calls.
/// Uses Dio and wraps Fields, Crops, CropTypes, Tasks, Users endpoints.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // ─── FIELDS ──────────────────────────────────────────────────

  Future<List<dynamic>> getFields() async {
    final res = await _dio.get('/fields');
    return res.data as List<dynamic>;
  }

  Future<void> createField(Map<String, dynamic> data) async {
    await _dio.post('/fields', data: data);
  }

  Future<void> updateField(String id, Map<String, dynamic> data) async {
    await _dio.put('/fields/$id', data: data);
  }

  Future<void> deleteField(String id) async {
    await _dio.delete('/fields/$id');
  }

  // ─── CROP TYPES ──────────────────────────────────────────────

  Future<List<dynamic>> getCropTypes() async {
    final res = await _dio.get('/crop-types');
    return res.data as List<dynamic>;
  }

  // ─── CROPS ───────────────────────────────────────────────────

  Future<List<dynamic>> getAllCrops() async {
    final res = await _dio.get('/crops');
    return res.data as List<dynamic>;
  }

  Future<List<dynamic>> getCropsForField(String fieldId) async {
    final res = await _dio.get('/fields/$fieldId/crops');
    return res.data as List<dynamic>;
  }

  Future<void> createCrop(Map<String, dynamic> data) async {
    await _dio.post('/crops', data: data);
  }

  Future<void> updateCrop(String id, Map<String, dynamic> data) async {
    await _dio.put('/crops/$id', data: data);
  }

  Future<void> deleteCrop(String id) async {
    await _dio.delete('/crops/$id');
  }

  // ─── TASKS ───────────────────────────────────────────────────

  Future<List<dynamic>> getTasks() async {
    final res = await _dio.get('/tasks');
    return res.data as List<dynamic>;
  }

  Future<void> createTask(Map<String, dynamic> data) async {
    await _dio.post('/tasks', data: data);
  }

  Future<void> updateTask(String id, Map<String, dynamic> data) async {
    await _dio.put('/tasks/$id', data: data);
  }

  Future<void> updateTaskStatus(String id, String status) async {
    await _dio.put('/tasks/$id/status', data: {'status': status});
  }

  Future<void> deleteTask(String id) async {
    await _dio.delete('/tasks/$id');
  }

  Future<List<dynamic>> getTaskMaterials(String taskId) async {
    final res = await _dio.get('/tasks/$taskId/materials');
    return res.data as List<dynamic>;
  }

  // ─── BEDS ────────────────────────────────────────────────────

  Future<List<dynamic>> getBeds(String cropId) async {
    final res = await _dio.get('/crops/$cropId/beds');
    return res.data as List<dynamic>;
  }

  Future<void> createBed(Map<String, dynamic> data) async {
    await _dio.post('/beds', data: data);
  }

  Future<void> updateBed(String id, Map<String, dynamic> data) async {
    await _dio.put('/beds/$id', data: data);
  }

  Future<void> deleteBed(String id) async {
    await _dio.delete('/beds/$id');
  }

  // ─── USERS ───────────────────────────────────────────────────

  Future<List<dynamic>> getUsers() async {
    final res = await _dio.get('/users');
    return res.data as List<dynamic>;
  }
}
