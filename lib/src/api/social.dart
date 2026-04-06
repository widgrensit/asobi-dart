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
    return friends.map((friendship) => Friendship.fromJson(friendship as Map<String, dynamic>)).toList();
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

  Future<Group> updateGroup(String groupId, {
    String? name,
    String? description,
    int? maxMembers,
    bool? open,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (maxMembers != null) body['max_members'] = maxMembers;
    if (open != null) body['open'] = open;
    final resp = await _client.http.put('/api/v1/groups/$groupId', body: body);
    return Group.fromJson(resp);
  }

  Future<void> joinGroup(String groupId) async {
    await _client.http.post('/api/v1/groups/$groupId/join');
  }

  Future<void> leaveGroup(String groupId) async {
    await _client.http.post('/api/v1/groups/$groupId/leave');
  }

  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    final resp = await _client.http.get('/api/v1/groups/$groupId/members');
    final members = resp['members'] as List<dynamic>;
    return members.map((m) => GroupMember.fromJson(m as Map<String, dynamic>)).toList();
  }

  Future<GroupMember> updateMemberRole(String groupId, String playerId, String role) async {
    final resp = await _client.http.put(
      '/api/v1/groups/$groupId/members/$playerId/role',
      body: {'role': role},
    );
    return GroupMember.fromJson(resp);
  }

  Future<void> removeMember(String groupId, String playerId) async {
    await _client.http.delete('/api/v1/groups/$groupId/members/$playerId');
  }

  Future<List<ChatMessage>> getChatHistory(String channelId, {int? limit}) async {
    final query = <String, String>{};
    if (limit != null) query['limit'] = limit.toString();
    final resp = await _client.http.get('/api/v1/chat/$channelId/history', query: query.isNotEmpty ? query : null);
    final messages = resp['messages'] as List<dynamic>;
    return messages.map((message) => ChatMessage.fromJson(message as Map<String, dynamic>)).toList();
  }

  Future<DmResponse> sendDm(String recipientId, String content) async {
    final resp = await _client.http.post('/api/v1/dm', body: {
      'recipient_id': recipientId,
      'content': content,
    });
    return DmResponse.fromJson(resp);
  }

  Future<DmHistory> getDmHistory(String playerId, {int? limit}) async {
    final query = <String, String>{};
    if (limit != null) query['limit'] = limit.toString();
    final resp = await _client.http.get('/api/v1/dm/$playerId/history', query: query.isNotEmpty ? query : null);
    return DmHistory.fromJson(resp);
  }

  Future<Friendship> updateFriend(String friendId, {required String status}) async {
    final resp = await _client.http.put('/api/v1/friends/$friendId', body: {'status': status});
    return Friendship.fromJson(resp);
  }
}
