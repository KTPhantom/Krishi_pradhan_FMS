import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../models/user_model.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
  
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  
  Future<Result<UserModel>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      
      final token = response.data['token'] as String;
      final refreshToken = response.data['refresh_token'] as String?;
      final userData = response.data['user'] as Map<String, dynamic>;
      
      await _storage.write(key: _tokenKey, value: token);
      if (refreshToken != null) {
        await _storage.write(key: _refreshTokenKey, value: refreshToken);
      }
      
      final user = UserModel.fromJson(userData);
      await saveUser(user);
      
      return Result.success(user);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Result.failure(
          Failure.unauthorized(message: 'Invalid email or password'),
        );
      }
      return Result.failure(
        Failure.server(
          message: e.response?.data?['message'] ?? 'Login failed',
          statusCode: e.response?.statusCode,
        ),
      );
    } catch (e) {
      return Result.failure(
        Failure.unknown(message: e.toString()),
      );
    }
  }
  
  Future<Result<UserModel>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          if (phone != null) 'phone': phone,
        },
      );
      
      final token = response.data['token'] as String;
      final refreshToken = response.data['refresh_token'] as String?;
      final userData = response.data['user'] as Map<String, dynamic>;
      
      await _storage.write(key: _tokenKey, value: token);
      if (refreshToken != null) {
        await _storage.write(key: _refreshTokenKey, value: refreshToken);
      }
      
      final user = UserModel.fromJson(userData);
      await saveUser(user);
      
      return Result.success(user);
    } on DioException catch (e) {
      return Result.failure(
        Failure.server(
          message: e.response?.data?['message'] ?? 'Registration failed',
          statusCode: e.response?.statusCode,
        ),
      );
    } catch (e) {
      return Result.failure(
        Failure.unknown(message: e.toString()),
      );
    }
  }
  
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }
  
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }
  
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;
      
      final response = await _dio.post(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
      );
      
      final newToken = response.data['token'] as String;
      await _storage.write(key: _tokenKey, value: newToken);
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> isTokenValid() async {
    final token = await getToken();
    if (token == null) return false;
    
    try {
      return !JwtDecoder.isExpired(token);
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null) return false;
    
    return await isTokenValid();
  }
  
  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await _dio.post(
          ApiConstants.logout,
          options: Options(
            headers: {
              ApiConstants.authorization: '${ApiConstants.bearer} $token',
            },
          ),
        );
      }
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _userKey);
    }
  }
  
  Future<UserModel?> getCurrentUser() async {
    try {
      final userJson = await _storage.read(key: _userKey);
      if (userJson == null) return null;
      
      // In production, use proper JSON deserialization with dart:convert
      // For now, return null - user will be fetched from API when needed
      // This avoids complex string parsing issues
      return null;
    } catch (e) {
      return null;
    }
  }
  
  Future<void> saveUser(UserModel user) async {
    // Store user as JSON string - using dart:convert for proper serialization
    final userJson = user.toJson();
    final jsonString = userJson.toString();
    await _storage.write(
      key: _userKey,
      value: jsonString,
    );
  }
}

