class AuthResponse {
  final String playerId;
  final String accessToken;
  final String refreshToken;
  final String username;

  AuthResponse({
    required this.playerId,
    required this.accessToken,
    required this.refreshToken,
    required this.username,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        playerId: json['player_id'] as String,
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        username: json['username'] as String,
      );

  Map<String, dynamic> toJson() => {
        'player_id': playerId,
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'username': username,
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
