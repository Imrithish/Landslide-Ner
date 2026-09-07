/// Application Constants
class AppConstants {
  static const String appName = 'NER Landslide Early Warning';
  static const String appSubtitle = 'Protecting communities through AI-powered risk monitoring';
  static const String appVersion = '1.0.0';
  static const String defaultModelVersion = '1.0.0';

  // 8 North Eastern States of India
  static const List<String> nerStates = [
    'Arunachal Pradesh',
    'Assam',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Sikkim',
    'Tripura',
  ];

  // Hazard Types for Field Reports
  static const List<String> hazardTypes = [
    'Landslide',
    'Road Crack',
    'Rockfall',
    'Soil Movement',
    'Flooding',
    'Other',
  ];

  // Severity Levels
  static const List<String> severities = [
    'low',
    'medium',
    'high',
    'critical',
  ];

  // Default initial coordinates centered around Shillong / Sikkim NER
  static const double defaultLatitude = 27.33;
  static const double defaultLongitude = 88.61;
  static const String defaultLocationName = 'Gangtok, Sikkim';

  // Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyUserData = 'auth_user';
  static const String keyBaseUrl = 'custom_api_base_url';
  static const String keyCachedPrediction = 'cached_last_prediction';
  static const String keyOfflineReports = 'offline_pending_reports';
  static const String keyCachedRiskZones = 'cached_risk_zones';
  static const String keyCachedAlerts = 'cached_alerts';
  static const String keyAppMode = 'app_mode'; // 'production' or 'mock'
}
