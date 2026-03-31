class Friendship {
  final String id;
  final String playerId;
  final String friendId;
  final String status;
  final String insertedAt;
  final String updatedAt;

  Friendship({
    required this.id,
    required this.playerId,
    required this.friendId,
    required this.status,
    required this.insertedAt,
    required this.updatedAt,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) => Friendship(
        id: json['id'] as String,
        playerId: json['player_id'] as String,
        friendId: json['friend_id'] as String,
        status: json['status'] as String,
        insertedAt: json['inserted_at'] as String,
        updatedAt: json['updated_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'player_id': playerId,
        'friend_id': friendId,
        'status': status,
        'inserted_at': insertedAt,
        'updated_at': updatedAt,
      };
}

class Group {
  final String id;
  final String name;
  final String? description;
  final int maxMembers;
  final bool open;
  final String creatorId;
  final String insertedAt;
  final String updatedAt;

  Group({
    required this.id,
    required this.name,
    this.description,
    required this.maxMembers,
    required this.open,
    required this.creatorId,
    required this.insertedAt,
    required this.updatedAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        maxMembers: json['max_members'] as int,
        open: json['open'] as bool,
        creatorId: json['creator_id'] as String,
        insertedAt: json['inserted_at'] as String,
        updatedAt: json['updated_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        'max_members': maxMembers,
        'open': open,
        'creator_id': creatorId,
        'inserted_at': insertedAt,
        'updated_at': updatedAt,
      };
}

class ChatMessage {
  final String id;
  final String channelType;
  final String channelId;
  final String senderId;
  final String content;
  final String sentAt;

  ChatMessage({
    required this.id,
    required this.channelType,
    required this.channelId,
    required this.senderId,
    required this.content,
    required this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        channelType: json['channel_type'] as String,
        channelId: json['channel_id'] as String,
        senderId: json['sender_id'] as String,
        content: json['content'] as String,
        sentAt: json['sent_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'channel_type': channelType,
        'channel_id': channelId,
        'sender_id': senderId,
        'content': content,
        'sent_at': sentAt,
      };
}
