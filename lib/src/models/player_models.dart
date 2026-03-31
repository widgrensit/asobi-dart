class Player {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? bannedAt;
  final String insertedAt;
  final String updatedAt;

  Player({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.bannedAt,
    required this.insertedAt,
    required this.updatedAt,
  });

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['display_name'] as String,
        avatarUrl: json['avatar_url'] as String?,
        bannedAt: json['banned_at'] as String?,
        insertedAt: json['inserted_at'] as String,
        updatedAt: json['updated_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (bannedAt != null) 'banned_at': bannedAt,
        'inserted_at': insertedAt,
        'updated_at': updatedAt,
      };
}
