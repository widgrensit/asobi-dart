import '../asobi_client.dart';
import '../models/notification_models.dart';

class AsobiNotifications {
  final AsobiClient _client;
  AsobiNotifications(this._client);

  Future<List<Notification>> list({bool? read, int? limit}) async {
    final query = <String, String>{};
    if (read != null) query['read'] = read.toString();
    if (limit != null) query['limit'] = limit.toString();
    final resp = await _client.http.get('/api/v1/notifications', query: query.isNotEmpty ? query : null);
    final notifications = resp['notifications'] as List<dynamic>;
    return notifications.map((notification) => Notification.fromJson(notification as Map<String, dynamic>)).toList();
  }

  Future<Notification> markRead(String notificationId) async {
    final resp = await _client.http.put('/api/v1/notifications/$notificationId/read');
    return Notification.fromJson(resp);
  }

  Future<void> delete(String notificationId) async {
    await _client.http.delete('/api/v1/notifications/$notificationId');
  }
}
