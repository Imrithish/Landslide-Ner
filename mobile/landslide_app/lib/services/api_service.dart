import '../core/network/api_client.dart';
import '../core/constants/api_endpoints.dart';
import '../core/storage/secure_storage_service.dart';
import '../core/storage/local_cache_service.dart';

/// Central API Service coordinating network clients
class ApiService {
  final ApiClient client;
  final SecureStorageService secureStorage;
  final LocalCacheService localCache;

  ApiService({
    required this.client,
    required this.secureStorage,
    required this.localCache,
  });

  factory ApiService.create({
    required SecureStorageService secureStorage,
    required LocalCacheService localCache,
  }) {
    final client = ApiClient(
      secureStorage: secureStorage,
      cacheService: localCache,
    );
    return ApiService(
      client: client,
      secureStorage: secureStorage,
      localCache: localCache,
    );
  }

  void updateBaseUrl(String url) {
    client.updateBaseUrl(url);
  }

  String get currentBaseUrl => client.currentBaseUrl;
}
