import 'dart:io';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/storage/local_cache_service.dart';
import '../models/report.dart';

/// Report Service for submitting field hazard reports, photo uploads, and offline queueing
class ReportService {
  final ApiClient _apiClient;
  final LocalCacheService _localCache;

  ReportService({
    required ApiClient apiClient,
    required LocalCacheService localCache,
  })  : _apiClient = apiClient,
        _localCache = localCache;

  Future<String?> uploadPhoto(File imageFile) async {
    try {
      final fileName = imageFile.path.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _apiClient.post(
        ApiEndpoints.uploadMedia,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return response['media_url'] as String?;
    } catch (e) {
      // Photo upload failure
      return null;
    }
  }

  Future<HazardReport> submitReport({
    required String location,
    required double latitude,
    required double longitude,
    required String description,
    String hazardType = 'Landslide',
    String severity = 'medium',
    String? state,
    String? district,
    File? imageFile,
    String? mediaUrl,
    String? reporterName,
    String? contactInfo,
    bool visibleCracks = false,
    bool rockfallObserved = false,
    bool roadBlocked = false,
    bool waterAccumulation = false,
    bool soilMovement = false,
  }) async {
    final idempotencyKey = const Uuid().v4();
    String? finalMediaUrl = mediaUrl;

    // Upload photo if provided
    if (imageFile != null && finalMediaUrl == null) {
      finalMediaUrl = await uploadPhoto(imageFile);
    }

    final reportPayload = {
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'hazard_type': hazardType,
      'severity': severity,
      'description': description,
      'state': state ?? 'Meghalaya',
      'district': district,
      'media_url': finalMediaUrl,
      'reporter_name': reporterName,
      'contact_info': contactInfo,
      'visible_cracks': visibleCracks,
      'rockfall_observed': rockfallObserved,
      'road_blocked': roadBlocked,
      'water_accumulation': waterAccumulation,
      'soil_movement': soilMovement,
      'idempotency_key': idempotencyKey,
    };

    try {
      final response = await _apiClient.post(
        ApiEndpoints.reports,
        data: reportPayload,
      );

      final reportId = response['report_id']?.toString() ?? idempotencyKey;
      return HazardReport(
        id: reportId,
        location: location,
        state: state,
        district: district,
        latitude: latitude,
        longitude: longitude,
        hazardType: hazardType,
        severity: severity,
        description: description,
        status: 'NEW',
        visibleCracks: visibleCracks,
        rockfallObserved: rockfallObserved,
        roadBlocked: roadBlocked,
        waterAccumulation: waterAccumulation,
        soilMovement: soilMovement,
        mediaUrl: finalMediaUrl,
        reporterName: reporterName,
        contactInfo: contactInfo,
        idempotencyKey: idempotencyKey,
        isSynced: true,
        createdAt: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      // Offline fallback: Queue report locally to sync when connection resumes
      reportPayload['is_synced'] = false;
      reportPayload['created_at'] = DateTime.now().toIso8601String();
      reportPayload['id'] = 'offline_${idempotencyKey.substring(0, 8)}';
      await _localCache.addOfflineReportToQueue(reportPayload);

      return HazardReport(
        id: 'offline_${idempotencyKey.substring(0, 8)}',
        location: location,
        state: state,
        district: district,
        latitude: latitude,
        longitude: longitude,
        hazardType: hazardType,
        severity: severity,
        description: description,
        status: 'NEW',
        visibleCracks: visibleCracks,
        rockfallObserved: rockfallObserved,
        roadBlocked: roadBlocked,
        waterAccumulation: waterAccumulation,
        soilMovement: soilMovement,
        mediaUrl: finalMediaUrl,
        reporterName: reporterName,
        contactInfo: contactInfo,
        idempotencyKey: idempotencyKey,
        isSynced: false,
        createdAt: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<List<HazardReport>> getReports({
    String? status,
    String? severity,
    String? state,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.reports,
        queryParameters: {
          if (status != null) 'status': status,
          if (severity != null) 'severity': severity,
          if (state != null) 'state': state,
        },
      );

      final reportsList = (response['reports'] as List<dynamic>? ?? []);
      final serverReports = reportsList
          .map((e) => HazardReport.fromJson(e as Map<String, dynamic>))
          .toList();

      // Merge with pending offline reports
      final offlineQueue = _localCache.getOfflineReportsQueue();
      final offlineReports = offlineQueue.map((e) => HazardReport.fromJson(e)).toList();

      return [...offlineReports, ...serverReports];
    } catch (_) {
      final offlineQueue = _localCache.getOfflineReportsQueue();
      return offlineQueue.map((e) => HazardReport.fromJson(e)).toList();
    }
  }
}
