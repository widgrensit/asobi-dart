class Notification {
  final String id;
  final String playerId;
  final String type;
  final String subject;
  final String content;
  final bool read;
  final String sentAt;

  Notification({
    required this.id,
    required this.playerId,
    required this.type,
    required this.subject,
    required this.content,
    required this.read,
    required this.sentAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) => Notification(
        id: json['id'] as String? ?? '',
        playerId: json['player_id'] as String? ?? '',
        type: (json['type'] as String?) ?? (json['kind'] as String?) ?? '',
        subject: json['subject'] as String? ?? '',
        content: json['content'] as String? ?? '',
        read: json['read'] as bool? ?? false,
        sentAt: json['sent_at'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'player_id': playerId,
        'type': type,
        'subject': subject,
        'content': content,
        'read': read,
        'sent_at': sentAt,
      };
}
