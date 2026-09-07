import '../core/network/api_client.dart';

/// Notification Service for handling early warning push alerts and notification tokens
class NotificationService {
  final ApiClient _apiClient;

  NotificationService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<void> registerFcmToken(String fcmToken, {String? state, String? district}) async {
    try {
      // Backend FCM token registration endpoint
      await _apiClient.post(
        '/notifications/subscribe',
        data: {
          'fcm_token': fcmToken,
          'state': state,
          'district': district,
        },
      );
    } catch (_) {
      // Gracefully ignore if notifications subscription is optional/unavailable
    }
  }
}
