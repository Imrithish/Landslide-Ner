import 'dart:convert';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/user.dart';

/// Authentication Service communicating with FastAPI /auth/login, /auth/register, /auth/me
class AuthService {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  AuthService({
    required ApiClient apiClient,
    required SecureStorageService secureStorage,
  })  : _apiClient = apiClient,
        _secureStorage = secureStorage;

  Future<AuthTokenResult> login({
    required String email,
    required String password,
  }) async {
    // OAuth2PasswordRequestForm expects form data with 'username' and 'password'
    final response = await _apiClient.postFormData(
      ApiEndpoints.login,
      formMap: {
        'username': email.trim(),
        'password': password,
      },
    );

    final result = AuthTokenResult.fromJson(response as Map<String, dynamic>);
    await _secureStorage.saveToken(result.accessToken);
    await _secureStorage.saveUserData(jsonEncode(result.user.toJson()));
    return result;
  }

  Future<AuthTokenResult> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? state,
    String? district,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.register,
      data: {
        'email': email.trim(),
        'password': password,
        'full_name': fullName.trim(),
        'phone_number': phoneNumber?.trim(),
        'role': 'CITIZEN',
        'state': state,
        'district': district,
      },
    );

    final result = AuthTokenResult.fromJson(response as Map<String, dynamic>);
    await _secureStorage.saveToken(result.accessToken);
    await _secureStorage.saveUserData(jsonEncode(result.user.toJson()));
    return result;
  }

  Future<User?> getCurrentUser() async {
    try {
      final token = await _secureStorage.getToken();
      if (token == null || token.isEmpty) return null;

      final response = await _apiClient.get(ApiEndpoints.me);
      final user = User.fromJson(response as Map<String, dynamic>);
      await _secureStorage.saveUserData(jsonEncode(user.toJson()));
      return user;
    } catch (_) {
      // Fallback to locally cached user info if offline
      final cachedJson = await _secureStorage.getUserData();
      if (cachedJson != null) {
        return User.fromJson(jsonDecode(cachedJson));
      }
      return null;
    }
  }

  Future<User> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? state,
    String? district,
  }) async {
    final response = await _apiClient.put(
      ApiEndpoints.me,
      data: {
        if (fullName != null) 'full_name': fullName.trim(),
        if (phoneNumber != null) 'phone_number': phoneNumber.trim(),
        if (state != null) 'state': state,
        if (district != null) 'district': district,
      },
    );

    final user = User.fromJson(response as Map<String, dynamic>);
    await _secureStorage.saveUserData(jsonEncode(user.toJson()));
    return user;
  }

  Future<void> logout() async {
    await _secureStorage.clearAuth();
  }

  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.getToken();
    return token != null && token.isNotEmpty;
  }
}
