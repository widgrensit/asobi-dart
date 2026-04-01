import 'http_client.dart';
import 'api/auth.dart';
import 'api/players.dart';
import 'api/matchmaker.dart';
import 'api/matches.dart';
import 'api/leaderboards.dart';
import 'api/economy.dart';
import 'api/inventory.dart';
import 'api/social.dart';
import 'api/tournaments.dart';
import 'api/notifications.dart';
import 'api/storage.dart';
import 'api/iap.dart';
import 'api/votes.dart';
import 'realtime/asobi_realtime.dart';

/// Main entry point for the Asobi game backend SDK.
///
/// Provides access to all API modules ([AsobiAuth], [AsobiPlayers],
/// [AsobiRealtime], etc.) and manages session state.
class AsobiClient {
  /// Connection configuration.
  final AsobiConfig config;

  /// Underlying HTTP client used by all API modules.
  final AsobiHttpClient http;

  /// Authentication and session management.
  late final AsobiAuth auth;

  /// Player profile operations.
  late final AsobiPlayers players;

  /// Matchmaking queue operations.
  late final AsobiMatchmaker matchmaker;

  /// Match history queries.
  late final AsobiMatches matches;

  /// Leaderboard scores and rankings.
  late final AsobiLeaderboards leaderboards;

  /// Virtual currency wallets and store purchases.
  late final AsobiEconomy economy;

  /// Player inventory management.
  late final AsobiInventory inventory;

  /// Friends, groups, and chat.
  late final AsobiSocial social;

  /// Tournament listings and registration.
  late final AsobiTournaments tournaments;

  /// In-app notifications.
  late final AsobiNotifications notifications;

  /// Cloud saves and key-value storage.
  late final AsobiStorage storage;

  /// In-app purchase receipt verification.
  late final AsobiIAP iap;

  /// In-match voting sessions.
  late final AsobiVotes votes;

  /// WebSocket realtime connection for matches, chat, and presence.
  late final AsobiRealtime realtime;

  String? _sessionToken;

  /// The authenticated player's ID, set after login/register.
  String? playerId;

  /// Current session token, or `null` if not authenticated.
  String? get sessionToken => _sessionToken;

  /// Sets the session token and propagates it to the [http] client.
  set sessionToken(String? value) {
    _sessionToken = value;
    http.sessionToken = value;
  }

  /// Whether the client has an active session token.
  bool get isAuthenticated => _sessionToken != null;

  /// Creates a client connecting to [host] on [port].
  AsobiClient(String host, {int port = 8080, bool useSsl = false})
      : this.fromConfig(AsobiConfig(host, port: port, useSsl: useSsl));

  /// Creates a client from an existing [AsobiConfig].
  AsobiClient.fromConfig(this.config) : http = AsobiHttpClient(config.baseUrl) {
    auth = AsobiAuth(this);
    players = AsobiPlayers(this);
    matchmaker = AsobiMatchmaker(this);
    matches = AsobiMatches(this);
    leaderboards = AsobiLeaderboards(this);
    economy = AsobiEconomy(this);
    inventory = AsobiInventory(this);
    social = AsobiSocial(this);
    tournaments = AsobiTournaments(this);
    notifications = AsobiNotifications(this);
    storage = AsobiStorage(this);
    iap = AsobiIAP(this);
    votes = AsobiVotes(this);
    realtime = AsobiRealtime(this);
  }

  /// Disconnects the realtime connection and cleans up resources.
  Future<void> dispose() async {
    await realtime.disconnect();
  }
}

/// Connection configuration for [AsobiClient].
class AsobiConfig {
  /// Server hostname or IP address.
  final String host;

  /// Server port number.
  final int port;

  /// Whether to use TLS (https/wss).
  final bool useSsl;

  /// Computed HTTP base URL.
  final String baseUrl;

  /// Computed WebSocket URL.
  final String wsUrl;

  /// Creates a config targeting [host] on [port].
  AsobiConfig(this.host, {this.port = 8080, this.useSsl = false})
      : baseUrl = '${useSsl ? 'https' : 'http'}://$host:$port',
        wsUrl = '${useSsl ? 'wss' : 'ws'}://$host:$port/ws';
}
