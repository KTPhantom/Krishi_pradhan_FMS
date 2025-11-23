# Quick Implementation Guide - Critical Improvements

This guide provides code examples for implementing the most critical improvements.

## 1. State Management with Riverpod

### Setup
```yaml
# pubspec.yaml
dependencies:
  flutter_riverpod: ^2.5.1
```

### Example: User State Provider
```dart
// lib/providers/user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class User {
  final String id;
  final String name;
  final String email;
  
  User({required this.id, required this.name, required this.email});
}

final userProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<User?> {
  UserNotifier() : super(null);
  
  void setUser(User user) {
    state = user;
  }
  
  void clearUser() {
    state = null;
  }
}
```

### Usage in Widget
```dart
// lib/ui/pages/home_page.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    
    return Scaffold(
      body: user == null 
        ? Text('Not logged in')
        : Text('Welcome ${user.name}'),
    );
  }
}
```

---

## 2. API Client with Dio

### Setup
```yaml
# pubspec.yaml
dependencies:
  dio: ^5.4.0
  retrofit: ^4.0.3
  json_annotation: ^4.8.1
```

### API Service
```dart
// lib/services/api_service.dart
import 'package:dio/dio.dart';

class ApiService {
  late final Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.farmverse.com/v1',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add auth token
        final token = _getAuthToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // Handle errors globally
        if (error.response?.statusCode == 401) {
          // Handle unauthorized
        }
        return handler.next(error);
      },
    ));
  }
  
  String? _getAuthToken() {
    // Get from secure storage
    return null;
  }
  
  Future<Response> get(String path) async {
    try {
      return await _dio.get(path);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Response> post(String path, dynamic data) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please check your internet.');
      case DioExceptionType.badResponse:
        return Exception('Server error: ${error.response?.statusCode}');
      default:
        return Exception('Network error. Please try again.');
    }
  }
}
```

---

## 3. Data Models with JSON Serialization

### Setup
```yaml
# pubspec.yaml
dependencies:
  json_annotation: ^4.8.1

dev_dependencies:
  json_serializable: ^6.7.1
  build_runner: ^2.4.7
```

### Example Model
```dart
// lib/models/product.dart
import 'package:json_annotation/json_annotation.dart';

part 'product.g.dart';

@JsonSerializable()
class Product {
  final int id;
  final String name;
  final String category;
  final double price;
  final String unit;
  final double rating;
  final String? imageUrl;
  
  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.unit,
    required this.rating,
    this.imageUrl,
  });
  
  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);
}
```

### Generate Code
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 4. Repository Pattern

```dart
// lib/repositories/product_repository.dart
import '../models/product.dart';
import '../services/api_service.dart';
import '../database/local_database.dart';

class ProductRepository {
  final ApiService _apiService;
  final LocalDatabase _localDatabase;
  
  ProductRepository(this._apiService, this._localDatabase);
  
  Future<List<Product>> getProducts({bool forceRefresh = false}) async {
    try {
      // Try to get from API
      final response = await _apiService.get('/products');
      final products = (response.data as List)
          .map((json) => Product.fromJson(json))
          .toList();
      
      // Cache locally
      await _localDatabase.saveProducts(products);
      
      return products;
    } catch (e) {
      // If offline, get from cache
      if (!forceRefresh) {
        return await _localDatabase.getProducts();
      }
      rethrow;
    }
  }
  
  Future<Product> getProductById(int id) async {
    try {
      final response = await _apiService.get('/products/$id');
      return Product.fromJson(response.data);
    } catch (e) {
      // Try cache
      return await _localDatabase.getProductById(id);
    }
  }
}
```

---

## 5. Authentication with Secure Storage

### Setup
```yaml
# pubspec.yaml
dependencies:
  flutter_secure_storage: ^9.0.0
```

### Auth Service
```dart
// lib/services/auth_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio = Dio();
  
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  
  Future<bool> login(String email, String password) async {
    try {
      final response = await _dio.post(
        'https://api.farmverse.com/v1/auth/login',
        data: {'email': email, 'password': password},
      );
      
      final token = response.data['token'];
      final refreshToken = response.data['refresh_token'];
      
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }
  
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
  
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
```

---

## 6. Error Handling Widget

```dart
// lib/widgets/error_widget.dart
import 'package:flutter/material.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  
  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

## 7. Loading States

```dart
// lib/widgets/loading_widget.dart
import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  
  const LoadingWidget({super.key, this.message});
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!),
          ],
        ],
      ),
    );
  }
}
```

---

## 8. Local Database with Drift

### Setup
```yaml
# pubspec.yaml
dependencies:
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.18
  path_provider: ^2.1.1
  path: ^1.8.3

dev_dependencies:
  drift_dev: ^2.14.0
  build_runner: ^2.4.7
```

### Database Definition
```dart
// lib/database/app_database.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'app_database.g.dart';

class Products extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  RealColumn get price => real()();
  TextColumn get unit => text()();
  RealColumn get rating => real()();
  
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Products])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  @override
  int get schemaVersion => 1;
  
  Future<List<Product>> getAllProducts() {
    return select(products).get();
  }
  
  Future<void> insertProducts(List<Product> productList) async {
    await batch((batch) {
      batch.insertAll(products, productList);
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.db'));
    return NativeDatabase(file);
  });
}
```

---

## 9. Environment Configuration

### Setup
```yaml
# pubspec.yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

### Usage
```dart
// lib/config/env.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';
  static String get apiKey => dotenv.env['API_KEY'] ?? '';
  
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }
}
```

### .env file
```
API_BASE_URL=https://api.farmverse.com/v1
API_KEY=your_api_key_here
```

### main.dart
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  await _initLocale();
  runApp(const FarmVerseApp());
}
```

---

## 10. Testing Example

```dart
// test/repositories/product_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'product_repository_test.mocks.dart';

@GenerateMocks([ApiService, LocalDatabase])
void main() {
  late ProductRepository repository;
  late MockApiService mockApiService;
  late MockLocalDatabase mockLocalDatabase;
  
  setUp(() {
    mockApiService = MockApiService();
    mockLocalDatabase = MockLocalDatabase();
    repository = ProductRepository(mockApiService, mockLocalDatabase);
  });
  
  test('getProducts returns list of products from API', () async {
    // Arrange
    when(mockApiService.get('/products'))
        .thenAnswer((_) async => Response(
          data: [
            {'id': 1, 'name': 'Test Product', 'category': 'Seeds', 'price': 100.0, 'unit': 'kg', 'rating': 4.5}
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: '/products'),
        ));
    
    // Act
    final products = await repository.getProducts();
    
    // Assert
    expect(products.length, 1);
    expect(products.first.name, 'Test Product');
    verify(mockApiService.get('/products')).called(1);
  });
}
```

---

## Quick Start Checklist

- [ ] Add state management (Riverpod/Provider)
- [ ] Set up API client (Dio)
- [ ] Create data models with JSON serialization
- [ ] Implement repository pattern
- [ ] Add authentication service
- [ ] Set up local database
- [ ] Implement error handling
- [ ] Add loading states
- [ ] Configure environment variables
- [ ] Write unit tests
- [ ] Set up CI/CD pipeline

---

**Note**: This is a starting point. Each implementation should be customized based on your specific backend API and requirements.

