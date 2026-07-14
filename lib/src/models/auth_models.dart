class AuthResponse {
  final String playerId;
  final String accessToken;
  final String refreshToken;
  final String username;
  final bool guest;
  final bool created;
  final bool upgraded;

  AuthResponse({
    required this.playerId,
    required this.accessToken,
    required this.refreshToken,
    required this.username,
    this.guest = false,
    this.created = false,
    this.upgraded = false,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        playerId: json['player_id'] as String,
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        username: json['username'] as String,
        guest: json['guest'] as bool? ?? false,
        created: json['created'] as bool? ?? false,
        upgraded: json['upgraded'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'player_id': playerId,
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'username': username,
        'guest': guest,
        'created': created,
        'upgraded': upgraded,
      };
}

class RefreshResponse {
  final String accessToken;
  final String refreshToken;

  RefreshResponse({required this.accessToken, required this.refreshToken});

  factory RefreshResponse.fromJson(Map<String, dynamic> json) => RefreshResponse(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
      );

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
      };
}
