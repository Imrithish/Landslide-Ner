import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Service for encrypted storage of sensitive credentials & JWT tokens
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
            );

  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.keyAuthToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.keyAuthToken);
  }

  Future<void> saveUserData(String userJson) async {
    await _storage.write(key: AppConstants.keyUserData, value: userJson);
  }

  Future<String?> getUserData() async {
    return await _storage.read(key: AppConstants.keyUserData);
  }

  Future<void> clearAuth() async {
    await _storage.delete(key: AppConstants.keyAuthToken);
    await _storage.delete(key: AppConstants.keyUserData);
  }
}
