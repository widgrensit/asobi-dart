class Player {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final Map<String, dynamic> metadata;
  final String insertedAt;
  final String updatedAt;

  Player({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.metadata = const {},
    required this.insertedAt,
    required this.updatedAt,
  });

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['display_name'] as String,
        avatarUrl: json['avatar_url'] as String?,
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
        insertedAt: json['inserted_at'] as String,
        updatedAt: json['updated_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'metadata': metadata,
        'inserted_at': insertedAt,
        'updated_at': updatedAt,
      };
}
