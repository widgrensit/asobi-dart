import '../asobi_client.dart';
import '../models/notification_models.dart';

class AsobiNotifications {
  final AsobiClient _client;
  AsobiNotifications(this._client);

  Future<List<Notification>> list() async {
    final resp = await _client.http.get('/api/v1/notifications');
    final notifications = resp['notifications'] as List<dynamic>;
    return notifications.map((notification) => Notification.fromJson(notification as Map<String, dynamic>)).toList();
  }

  Future<void> markRead(String notificationId) async {
    await _client.http.put('/api/v1/notifications/$notificationId/read');
  }

  Future<void> delete(String notificationId) async {
    await _client.http.delete('/api/v1/notifications/$notificationId');
  }
}
