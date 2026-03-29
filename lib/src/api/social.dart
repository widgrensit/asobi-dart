import '../asobi_client.dart';
import '../models/social_models.dart';

class AsobiSocial {
  final AsobiClient _client;
  AsobiSocial(this._client);

  Future<List<Friendship>> getFriends({String? status, int limit = 50}) async {
    final query = <String, String>{'limit': limit.toString()};
    if (status != null) query['status'] = status;
    final resp = await _client.http.get('/api/v1/friends', query: query);
    final friends = resp['friends'] as List<dynamic>;
    return friends.map((f) => Friendship.fromJson(f as Map<String, dynamic>)).toList();
  }

  Future<Friendship> addFriend(String friendId) async {
    final resp = await _client.http.post('/api/v1/friends', body: {'friend_id': friendId});
    return Friendship.fromJson(resp);
  }

  Future<Friendship> acceptFriend(String friendId) async {
    final resp = await _client.http.put('/api/v1/friends/$friendId', body: {'status': 'accepted'});
    return Friendship.fromJson(resp);
  }

  Future<Friendship> blockFriend(String friendId) async {
    final resp = await _client.http.put('/api/v1/friends/$friendId', body: {'status': 'blocked'});
    return Friendship.fromJson(resp);
  }

  Future<void> removeFriend(String friendId) async {
    await _client.http.delete('/api/v1/friends/$friendId');
  }

  Future<Group> createGroup(String name, {String? description, int maxMembers = 50, bool open = false}) async {
    final resp = await _client.http.post('/api/v1/groups', body: {
      'name': name,
      'description': description,
      'max_members': maxMembers,
      'open': open,
    });
    return Group.fromJson(resp);
  }

  Future<Group> getGroup(String groupId) async {
    final resp = await _client.http.get('/api/v1/groups/$groupId');
    return Group.fromJson(resp);
  }

  Future<void> joinGroup(String groupId) async {
    await _client.http.post('/api/v1/groups/$groupId/join');
  }

  Future<void> leaveGroup(String groupId) async {
    await _client.http.post('/api/v1/groups/$groupId/leave');
  }

  Future<List<ChatMessage>> getChatHistory(String channelId) async {
    final resp = await _client.http.get('/api/v1/chat/$channelId/history');
    final messages = resp['messages'] as List<dynamic>;
    return messages.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>)).toList();
  }
}
