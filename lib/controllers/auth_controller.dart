import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/auth_service.dart';
import '../models/user/user_model.dart';
import '../core/utils/result.dart';

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
  
  bool get isAdmin => user?.isAdmin ?? false;
  String get role => user?.role ?? 'worker';
  String get userId => user?.id ?? '';
  String get userName => user?.name ?? '';
  
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
  
  Future<Result<UserModel>> login(String username, String password) async {
    state = state.copyWith(isLoading: true);
    final result = await _authService.login(username, password);
    
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
    required String username,
    required String password,
    String role = 'worker',
  }) async {
    state = state.copyWith(isLoading: true);
    final result = await _authService.register(
      username: username,
      password: password,
      role: role,
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
  
  /// Toggle user role between admin and worker (in-app switch)
  void toggleRole() {
    if (state.user == null) return;
    final newRole = state.user!.role == 'admin' ? 'worker' : 'admin';
    final updatedUser = state.user!.copyWith(role: newRole);
    state = state.copyWith(user: updatedUser);
    _authService.saveUser(updatedUser);
  }
  
  Future<void> logout() async {
    await _authService.logout();
    state = AuthState();
  }
}
