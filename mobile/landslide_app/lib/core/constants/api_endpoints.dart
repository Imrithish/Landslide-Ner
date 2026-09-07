/// Centralized API Endpoints Configuration for NER Landslide Early Warning
class ApiEndpoints {
  // Default base URL for Android Emulator pointing to local machine FastAPI
  // On physical device, change to host machine LAN IP e.g. http://192.168.1.X:8000
  static const String defaultBaseUrl = 'http://10.0.2.2:8000/api/v1';
  static const String defaultLocalhostUrl = 'http://127.0.0.1:8000/api/v1';

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';

  // Prediction & ML Endpoints
  static const String predictions = '/predictions';
  static const String predictionHistory = '/predictions/history';
  static const String multiHazardForecast = '/predictions/multi-hazard-forecast';
  static const String modelInfo = '/predictions/model-info';

  // GIS & Risk Zones Endpoints
  static const String riskZones = '/risk-zones';
  static const String riskMap = '/risk-map';
  static const String gisRiskZones = '/gis/risk-zones';
  static const String gisHeatmap = '/gis/heatmap';
  static const String gisRegions = '/gis/regions';

  // Alerts & Dashboard Endpoints
  static const String alerts = '/alerts';
  static const String alertsSync = '/alerts/sync';
  static const String dashboardSummary = '/dashboard/summary';

  // Field Hazard Reports Endpoints
  static const String reports = '/reports';
  static const String uploadMedia = '/reports/upload-media';

  // Health & System
  static const String health = '/health';
  static const String ready = '/ready';
}
