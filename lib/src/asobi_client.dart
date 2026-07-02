import 'package:http/http.dart' as http_pkg;

import 'http_client.dart';
import 'token_store.dart';
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
import 'api/worlds.dart';
import 'realtime/asobi_realtime.dart';

class AsobiClient {
  final AsobiConfig config;
  final AsobiHttpClient http;

  late final AsobiAuth auth;
  late final AsobiPlayers players;
  late final AsobiMatchmaker matchmaker;
  late final AsobiMatches matches;
  late final AsobiLeaderboards leaderboards;
  late final AsobiEconomy economy;
  late final AsobiInventory inventory;
  late final AsobiSocial social;
  late final AsobiTournaments tournaments;
  late final AsobiNotifications notifications;
  late final AsobiStorage storage;
  late final AsobiIAP iap;
  late final AsobiVotes votes;
  late final AsobiWorlds worlds;
  late final AsobiRealtime realtime;

  String? playerId;

  String? get accessToken => http.accessToken;
  set accessToken(String? value) => http.accessToken = value;

  bool get isAuthenticated => http.accessToken != null;

  Future<String?> get refreshToken => http.tokenStore.read();
  Future<void> saveRefreshToken(String? token) => http.tokenStore.write(token);

  AsobiClient(String host,
      {int port = 8084, bool useSsl = false, TokenStore? tokenStore})
      : this.fromConfig(AsobiConfig(host, port: port, useSsl: useSsl),
            tokenStore: tokenStore);

  AsobiClient.fromConfig(this.config, {http_pkg.Client? httpClient, TokenStore? tokenStore})
      : http = AsobiHttpClient(config.baseUrl,
            httpClient: httpClient, tokenStore: tokenStore) {
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
    worlds = AsobiWorlds(http);
    realtime = AsobiRealtime(this);
    http.onAccessTokenRefreshed = (token) => realtime.reauthenticate(token);
  }

  /// Notifies the realtime layer that the access token rotated so the
  /// WebSocket re-authenticates. Called after a manual [AsobiAuth.refresh].
  void notifyAccessTokenRotated(String token) =>
      realtime.reauthenticate(token);

  Future<void> dispose() async {
    await realtime.disconnect();
  }
}

class AsobiConfig {
  final String host;
  final int port;
  final bool useSsl;
  final String baseUrl;
  final String wsUrl;

  AsobiConfig(this.host, {this.port = 8084, this.useSsl = false})
      : baseUrl = '${useSsl ? 'https' : 'http'}://$host:$port',
        wsUrl = '${useSsl ? 'wss' : 'ws'}://$host:$port/ws';
}
