import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/user_model.dart';
import '../../core/utils/result.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final bool isAuthenticated;
  
  AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
  });
  
  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  
  AuthNotifier(this._authService) : super(AuthState()) {
    _checkAuthStatus();
  }
  
  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      final user = await _authService.getCurrentUser();
      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
      );
    }
  }
  
  Future<Result<UserModel>> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    final result = await _authService.login(email, password);
    
    result.when(
      success: (user) {
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
      },
      failure: (_) {
        state = state.copyWith(isLoading: false);
      },
    );
    
    return result;
  }
  
  Future<Result<UserModel>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true);
    final result = await _authService.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
    );
    
    result.when(
      success: (user) {
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
      },
      failure: (_) {
        state = state.copyWith(isLoading: false);
      },
    );
    
    return result;
  }
  
  Future<void> logout() async {
    await _authService.logout();
    state = AuthState();
  }
}

