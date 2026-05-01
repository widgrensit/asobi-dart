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

  String? _sessionToken;
  String? playerId;

  String? get sessionToken => _sessionToken;
  set sessionToken(String? value) {
    _sessionToken = value;
    http.sessionToken = value;
  }

  bool get isAuthenticated => _sessionToken != null;

  AsobiClient(String host, {int port = 8084, bool useSsl = false})
      : this.fromConfig(AsobiConfig(host, port: port, useSsl: useSsl));

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
    worlds = AsobiWorlds(http);
    realtime = AsobiRealtime(this);
  }

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
