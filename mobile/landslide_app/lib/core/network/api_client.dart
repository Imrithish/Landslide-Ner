import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage_service.dart';
import '../storage/local_cache_service.dart';
import 'network_exceptions.dart';

/// Centralized API Client for HTTP communication with FastAPI Backend
class ApiClient {
  final SecureStorageService _secureStorage;
  final LocalCacheService _cacheService;
  late final Dio _dio;

  ApiClient({
    required SecureStorageService secureStorage,
    required LocalCacheService cacheService,
    String? baseUrl,
  })  : _secureStorage = secureStorage,
        _cacheService = cacheService {
    final effectiveBaseUrl = baseUrl ?? _cacheService.getCustomBaseUrl() ?? ApiEndpoints.defaultBaseUrl;

    _dio = Dio(
      BaseOptions(
        baseUrl: effectiveBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
    _cacheService.setCustomBaseUrl(newBaseUrl);
  }

  String get currentBaseUrl => _dio.options.baseUrl;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw NetworkException(message: e.toString());
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw NetworkException(message: e.toString());
    }
  }

  Future<dynamic> postFormData(
    String path, {
    required Map<String, dynamic> formMap,
  }) async {
    try {
      final formData = FormData.fromMap(formMap);
      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw NetworkException(message: e.toString());
    }
  }

  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw NetworkException(message: e.toString());
    }
  }

  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw NetworkException(message: e.toString());
    }
  }

  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw NetworkException(message: e.toString());
    }
  }

  NetworkException _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return TimeoutException();
    }

    if (error.type == DioExceptionType.connectionError ||
        error.error is SocketException) {
      return NoInternetException();
    }

    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    String detail = 'Request failed';
    if (responseData is Map<String, dynamic>) {
      detail = responseData['detail']?.toString() ??
          responseData['message']?.toString() ??
          detail;
    } else if (responseData is String) {
      detail = responseData;
    }

    if (statusCode == 401) {
      return UnauthorizedException(message: detail);
    }

    return NetworkException(
      message: detail,
      statusCode: statusCode,
      data: responseData,
    );
  }
}
