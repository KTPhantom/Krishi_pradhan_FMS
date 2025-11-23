import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../errors/failures.dart';
import '../utils/result.dart';
import '../../data/services/auth_service.dart';

class ApiClient {
  late final Dio _dio;
  final AuthService _authService;
  
  ApiClient(this._authService) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        ApiConstants.contentType: ApiConstants.applicationJson,
      },
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token
        final token = await _authService.getToken();
        if (token != null) {
          options.headers[ApiConstants.authorization] = 
              '${ApiConstants.bearer} $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Try to refresh token
          final refreshed = await _authService.refreshToken();
          if (refreshed) {
            // Retry the request
            final token = await _authService.getToken();
            if (token != null) {
              error.requestOptions.headers[ApiConstants.authorization] = 
                  '${ApiConstants.bearer} $token';
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            }
          }
        }
        return handler.next(error);
      },
    ));
  }
  
  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      
      if (fromJson != null) {
        return Result.success(fromJson(response.data));
      }
      return Result.success(response.data as T);
    } on DioException catch (e) {
      return Result.failure(_handleError(e));
    } catch (e) {
      return Result.failure(
        Failure.unknown(message: e.toString()),
      );
    }
  }
  
  Future<Result<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      
      if (fromJson != null) {
        return Result.success(fromJson(response.data));
      }
      return Result.success(response.data as T);
    } on DioException catch (e) {
      return Result.failure(_handleError(e));
    } catch (e) {
      return Result.failure(
        Failure.unknown(message: e.toString()),
      );
    }
  }
  
  Future<Result<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      
      if (fromJson != null) {
        return Result.success(fromJson(response.data));
      }
      return Result.success(response.data as T);
    } on DioException catch (e) {
      return Result.failure(_handleError(e));
    } catch (e) {
      return Result.failure(
        Failure.unknown(message: e.toString()),
      );
    }
  }
  
  Future<Result<void>> delete(String path) async {
    try {
      await _dio.delete(path);
      return const Result.success(null);
    } on DioException catch (e) {
      return Result.failure(_handleError(e));
    } catch (e) {
      return Result.failure(
        Failure.unknown(message: e.toString()),
      );
    }
  }
  
  Failure _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Failure.network(
          message: 'Connection timeout. Please check your internet connection.',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 
                       error.message ?? 
                       'Server error occurred';
        
        if (statusCode == 401) {
          return Failure.unauthorized(message: message);
        }
        
        return Failure.server(
          message: message,
          statusCode: statusCode,
        );
      case DioExceptionType.cancel:
        return Failure.network(message: 'Request was cancelled');
      case DioExceptionType.connectionError:
        return Failure.network(
          message: 'No internet connection. Please check your network settings.',
        );
      default:
        return Failure.network(
          message: error.message ?? 'Network error occurred',
        );
    }
  }
}

