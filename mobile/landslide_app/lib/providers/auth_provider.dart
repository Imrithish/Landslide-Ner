import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/secure_storage_service.dart';
import '../core/storage/local_cache_service.dart';
import '../core/network/api_client.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final localCacheProvider = Provider<LocalCacheService>((ref) {
  throw UnimplementedError('localCacheProvider must be overridden in main.dart');
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final localCache = ref.watch(localCacheProvider);
  return ApiClient(
    secureStorage: secureStorage,
    cacheService: localCache,
  );
});

final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthService(apiClient: apiClient, secureStorage: secureStorage);
});

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(User user) => AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated([String? message]) => AuthState(status: AuthStatus.unauthenticated, errorMessage: message);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState.initial()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = AuthState.loading();
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (_) {
      state = AuthState.unauthenticated();
    }
  }

  Future<bool> login(String email, String password) async {
    state = AuthState.loading();
    try {
      final result = await _authService.login(email: email, password: password);
      state = AuthState.authenticated(result.user);
      return true;
    } catch (e) {
      state = AuthState.unauthenticated(e.toString());
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? stateName,
    String? district,
  }) async {
    state = AuthState.loading();
    try {
      final result = await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        state: stateName,
        district: district,
      );
      state = AuthState.authenticated(result.user);
      return true;
    } catch (e) {
      state = AuthState.unauthenticated(e.toString());
      return false;
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? stateName,
    String? district,
  }) async {
    try {
      final updatedUser = await _authService.updateProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        state: stateName,
        district: district,
      );
      state = AuthState.authenticated(updatedUser);
    } catch (e) {
      // Keep existing state but record error if needed
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AuthState.unauthenticated();
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
