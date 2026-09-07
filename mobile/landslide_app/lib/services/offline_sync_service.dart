import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/storage/local_cache_service.dart';

/// Service that monitors network connectivity and syncs pending offline hazard reports to FastAPI
class OfflineSyncService {
  final ApiClient _apiClient;
  final LocalCacheService _localCache;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isSyncing = false;

  OfflineSyncService({
    required ApiClient apiClient,
    required LocalCacheService localCache,
  })  : _apiClient = apiClient,
        _localCache = localCache;

  void startAutoSyncListener({Function(int syncedCount)? onSyncComplete}) {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        syncPendingReports().then((count) {
          if (count > 0 && onSyncComplete != null) {
            onSyncComplete(count);
          }
        });
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<int> syncPendingReports() async {
    if (_isSyncing) return 0;
    _isSyncing = true;

    final queue = _localCache.getOfflineReportsQueue();
    if (queue.isEmpty) {
      _isSyncing = false;
      return 0;
    }

    int syncedCount = 0;
    for (final report in List<Map<String, dynamic>>.from(queue)) {
      try {
        final idempotencyKey = report['idempotency_key']?.toString();
        await _apiClient.post(
          ApiEndpoints.reports,
          data: {
            'location': report['location'],
            'latitude': report['latitude'],
            'longitude': report['longitude'],
            'hazard_type': report['hazard_type'] ?? 'landslide',
            'severity': report['severity'] ?? 'medium',
            'description': report['description'],
            'state': report['state'],
            'district': report['district'],
            'media_url': report['media_url'],
            'reporter_name': report['reporter_name'],
            'contact_info': report['contact_info'],
            'visible_cracks': report['visible_cracks'] == true,
            'rockfall_observed': report['rockfall_observed'] == true,
            'road_blocked': report['road_blocked'] == true,
            'water_accumulation': report['water_accumulation'] == true,
            'soil_movement': report['soil_movement'] == true,
            'idempotency_key': idempotencyKey,
          },
        );

        if (idempotencyKey != null) {
          await _localCache.removeOfflineReportFromQueue(idempotencyKey);
        }
        syncedCount++;
      } catch (e) {
        // Stop syncing on network failure
        break;
      }
    }

    _isSyncing = false;
    return syncedCount;
  }

  int get pendingReportsCount => _localCache.getOfflineReportsQueue().length;
}
