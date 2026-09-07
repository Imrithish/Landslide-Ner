import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Local Cache Service for offline support, sync queues, and cached telemetry
class LocalCacheService {
  final SharedPreferences _prefs;

  LocalCacheService(this._prefs);

  static Future<LocalCacheService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalCacheService(prefs);
  }

  // Base URL override
  String? getCustomBaseUrl() {
    return _prefs.getString(AppConstants.keyBaseUrl);
  }

  Future<void> setCustomBaseUrl(String url) async {
    await _prefs.setString(AppConstants.keyBaseUrl, url);
  }

  // App Mode ('production' or 'mock')
  String getAppMode() {
    return _prefs.getString(AppConstants.keyAppMode) ?? 'production';
  }

  Future<void> setAppMode(String mode) async {
    await _prefs.setString(AppConstants.keyAppMode, mode);
  }

  // Cached Prediction
  Map<String, dynamic>? getCachedPrediction() {
    final raw = _prefs.getString(AppConstants.keyCachedPrediction);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> cachePrediction(Map<String, dynamic> predictionMap) async {
    await _prefs.setString(
      AppConstants.keyCachedPrediction,
      jsonEncode(predictionMap),
    );
  }

  // Offline Pending Reports Queue
  List<Map<String, dynamic>> getOfflineReportsQueue() {
    final raw = _prefs.getString(AppConstants.keyOfflineReports);
    if (raw == null) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> addOfflineReportToQueue(Map<String, dynamic> report) async {
    final queue = getOfflineReportsQueue();
    queue.add(report);
    await _prefs.setString(AppConstants.keyOfflineReports, jsonEncode(queue));
  }

  Future<void> removeOfflineReportFromQueue(String idempotencyKey) async {
    final queue = getOfflineReportsQueue();
    queue.removeWhere((item) => item['idempotency_key'] == idempotencyKey);
    await _prefs.setString(AppConstants.keyOfflineReports, jsonEncode(queue));
  }

  Future<void> clearOfflineReportsQueue() async {
    await _prefs.remove(AppConstants.keyOfflineReports);
  }

  // Cached Risk Zones
  List<Map<String, dynamic>> getCachedRiskZones() {
    final raw = _prefs.getString(AppConstants.keyCachedRiskZones);
    if (raw == null) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> cacheRiskZones(List<Map<String, dynamic>> zones) async {
    await _prefs.setString(AppConstants.keyCachedRiskZones, jsonEncode(zones));
  }

  // Cached Alerts
  List<Map<String, dynamic>> getCachedAlerts() {
    final raw = _prefs.getString(AppConstants.keyCachedAlerts);
    if (raw == null) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> cacheAlerts(List<Map<String, dynamic>> alerts) async {
    await _prefs.setString(AppConstants.keyCachedAlerts, jsonEncode(alerts));
  }
}
