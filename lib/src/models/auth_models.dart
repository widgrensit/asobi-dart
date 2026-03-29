class AuthResponse {
  final String playerId;
  final String sessionToken;
  final String username;

  AuthResponse({required this.playerId, required this.sessionToken, required this.username});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        playerId: json['player_id'] as String,
        sessionToken: json['session_token'] as String,
        username: json['username'] as String,
      );
}

class RefreshResponse {
  final String playerId;
  final String sessionToken;

  RefreshResponse({required this.playerId, required this.sessionToken});

  factory RefreshResponse.fromJson(Map<String, dynamic> json) => RefreshResponse(
        playerId: json['player_id'] as String,
        sessionToken: json['session_token'] as String,
      );
}
