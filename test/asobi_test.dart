import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'package:asobi/src/models/auth_models.dart';
import 'package:asobi/src/models/iap_models.dart';
import 'package:asobi/src/models/player_models.dart';
import 'package:asobi/src/models/match_models.dart';
import 'package:asobi/src/models/economy_models.dart';
import 'package:asobi/src/models/leaderboard_models.dart';
import 'package:asobi/src/models/social_models.dart';
import 'package:asobi/src/models/storage_models.dart';
import 'package:asobi/src/models/tournament_models.dart';
import 'package:asobi/src/models/notification_models.dart';
import 'package:asobi/src/models/realtime_models.dart';
import 'package:asobi/src/http_client.dart';
import 'package:asobi/src/asobi_client.dart';

void main() {
  group('AuthResponse', () {
    test('fromJson parses correctly', () {
      final json = {
        'player_id': 'p1',
        'session_token': 'tok123',
        'username': 'alice',
      };
      final r = AuthResponse.fromJson(json);
      expect(r.playerId, 'p1');
      expect(r.sessionToken, 'tok123');
      expect(r.username, 'alice');
    });
  });

  group('OAuthResponse', () {
    test('fromJson parses correctly', () {
      final json = {
        'player_id': 'p2',
        'session_token': 'oauth-tok',
        'username': 'bob',
        'created': true,
      };
      final r = OAuthResponse.fromJson(json);
      expect(r.playerId, 'p2');
      expect(r.sessionToken, 'oauth-tok');
      expect(r.username, 'bob');
      expect(r.created, true);
    });

    test('fromJson defaults created to false', () {
      final json = {
        'player_id': 'p2',
        'session_token': 'tok',
        'username': 'bob',
      };
      final r = OAuthResponse.fromJson(json);
      expect(r.created, false);
    });
  });

  group('RefreshResponse', () {
    test('fromJson parses correctly', () {
      final json = {'player_id': 'p3', 'session_token': 'refresh-tok'};
      final r = RefreshResponse.fromJson(json);
      expect(r.playerId, 'p3');
      expect(r.sessionToken, 'refresh-tok');
    });
  });

  group('Player', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'p1',
        'username': 'alice',
        'display_name': 'Alice',
        'avatar_url': 'https://example.com/a.png',
        'banned_at': null,
        'inserted_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-02T00:00:00Z',
      };
      final p = Player.fromJson(json);
      expect(p.id, 'p1');
      expect(p.username, 'alice');
      expect(p.displayName, 'Alice');
      expect(p.avatarUrl, 'https://example.com/a.png');
      expect(p.bannedAt, isNull);
      expect(p.insertedAt, '2026-01-01T00:00:00Z');
      expect(p.updatedAt, '2026-01-02T00:00:00Z');
    });

    test('fromJson with null optional fields', () {
      final json = {
        'id': 'p1',
        'username': 'alice',
        'display_name': 'Alice',
        'inserted_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-02T00:00:00Z',
      };
      final p = Player.fromJson(json);
      expect(p.avatarUrl, isNull);
      expect(p.bannedAt, isNull);
    });
  });

  group('Wallet', () {
    test('fromJson parses correctly', () {
      final json = {'currency': 'gold', 'balance': 500};
      final w = Wallet.fromJson(json);
      expect(w.currency, 'gold');
      expect(w.balance, 500);
    });
  });

  group('Transaction', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 't1',
        'wallet_id': 'w1',
        'amount': 100,
        'balance_after': 600,
        'reason': 'purchase',
        'reference_type': 'store',
        'reference_id': 'ref1',
        'inserted_at': '2026-01-01T00:00:00Z',
      };
      final t = Transaction.fromJson(json);
      expect(t.id, 't1');
      expect(t.walletId, 'w1');
      expect(t.amount, 100);
      expect(t.balanceAfter, 600);
      expect(t.reason, 'purchase');
      expect(t.referenceType, 'store');
      expect(t.referenceId, 'ref1');
    });

    test('fromJson with null optional fields', () {
      final json = {
        'id': 't2',
        'wallet_id': 'w1',
        'amount': -50,
        'balance_after': 450,
        'reason': 'debit',
        'inserted_at': '2026-01-01T00:00:00Z',
      };
      final t = Transaction.fromJson(json);
      expect(t.referenceType, isNull);
      expect(t.referenceId, isNull);
    });
  });

  group('StoreListing', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'sl1',
        'item_def_id': 'sword',
        'currency': 'gold',
        'price': 100,
        'active': true,
        'valid_from': '2026-01-01T00:00:00Z',
        'valid_until': '2026-12-31T23:59:59Z',
      };
      final s = StoreListing.fromJson(json);
      expect(s.id, 'sl1');
      expect(s.itemDefId, 'sword');
      expect(s.currency, 'gold');
      expect(s.price, 100);
      expect(s.active, true);
      expect(s.validFrom, '2026-01-01T00:00:00Z');
      expect(s.validUntil, '2026-12-31T23:59:59Z');
    });
  });

  group('PlayerItem', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'pi1',
        'item_def_id': 'sword',
        'player_id': 'p1',
        'quantity': 3,
        'acquired_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-02T00:00:00Z',
      };
      final pi = PlayerItem.fromJson(json);
      expect(pi.id, 'pi1');
      expect(pi.itemDefId, 'sword');
      expect(pi.playerId, 'p1');
      expect(pi.quantity, 3);
    });
  });

  group('PurchaseResponse', () {
    test('fromJson parses correctly', () {
      final json = {
        'success': true,
        'item': {
          'id': 'pi1',
          'item_def_id': 'sword',
          'player_id': 'p1',
          'quantity': 1,
          'acquired_at': '2026-01-01T00:00:00Z',
          'updated_at': '2026-01-01T00:00:00Z',
        },
      };
      final pr = PurchaseResponse.fromJson(json);
      expect(pr.success, true);
      expect(pr.item.id, 'pi1');
      expect(pr.item.itemDefId, 'sword');
    });
  });

  group('CloudSave', () {
    test('fromJson parses data as Map', () {
      final json = {
        'player_id': 'p1',
        'slot': 'slot1',
        'data': {'level': 5, 'score': 1000},
        'version': 2,
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final cs = CloudSave.fromJson(json);
      expect(cs.playerId, 'p1');
      expect(cs.slot, 'slot1');
      expect(cs.data, isA<Map<String, dynamic>>());
      expect(cs.data['level'], 5);
      expect(cs.data['score'], 1000);
      expect(cs.version, 2);
    });
  });

  group('CloudSaveSummary', () {
    test('fromJson parses correctly', () {
      final json = {
        'slot': 'slot1',
        'version': 3,
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final css = CloudSaveSummary.fromJson(json);
      expect(css.slot, 'slot1');
      expect(css.version, 3);
      expect(css.updatedAt, '2026-01-01T00:00:00Z');
    });
  });

  group('StorageObject', () {
    test('fromJson parses value as Map', () {
      final json = {
        'collection': 'settings',
        'key': 'prefs',
        'player_id': 'p1',
        'value': {'theme': 'dark', 'volume': 80},
        'version': 1,
        'read_perm': 'owner',
        'write_perm': 'owner',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final so = StorageObject.fromJson(json);
      expect(so.collection, 'settings');
      expect(so.key, 'prefs');
      expect(so.playerId, 'p1');
      expect(so.value, isA<Map<String, dynamic>>());
      expect(so.value['theme'], 'dark');
      expect(so.value['volume'], 80);
      expect(so.version, 1);
      expect(so.readPerm, 'owner');
      expect(so.writePerm, 'owner');
    });
  });

  group('MatchRecord', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'm1',
        'mode': 'ranked',
        'status': 'finished',
        'started_at': '2026-01-01T00:00:00Z',
        'finished_at': '2026-01-01T00:30:00Z',
        'inserted_at': '2026-01-01T00:00:00Z',
      };
      final m = MatchRecord.fromJson(json);
      expect(m.id, 'm1');
      expect(m.mode, 'ranked');
      expect(m.status, 'finished');
      expect(m.startedAt, '2026-01-01T00:00:00Z');
      expect(m.finishedAt, '2026-01-01T00:30:00Z');
    });

    test('fromJson with null optional fields', () {
      final json = {
        'id': 'm2',
        'mode': 'casual',
        'status': 'pending',
        'inserted_at': '2026-01-01T00:00:00Z',
      };
      final m = MatchRecord.fromJson(json);
      expect(m.startedAt, isNull);
      expect(m.finishedAt, isNull);
    });
  });

  group('MatchmakerTicket', () {
    test('fromJson parses correctly', () {
      final json = {'ticket_id': 'tk1', 'status': 'queued'};
      final t = MatchmakerTicket.fromJson(json);
      expect(t.ticketId, 'tk1');
      expect(t.status, 'queued');
    });
  });

  group('LeaderboardEntry', () {
    test('fromJson parses correctly', () {
      final json = {
        'leaderboard_id': 'lb1',
        'player_id': 'p1',
        'score': 9999,
        'sub_score': 42,
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final e = LeaderboardEntry.fromJson(json);
      expect(e.leaderboardId, 'lb1');
      expect(e.playerId, 'p1');
      expect(e.score, 9999);
      expect(e.subScore, 42);
    });

    test('fromJson defaults missing fields', () {
      final json = <String, dynamic>{};
      final e = LeaderboardEntry.fromJson(json);
      expect(e.leaderboardId, '');
      expect(e.playerId, '');
      expect(e.score, 0);
      expect(e.subScore, 0);
      expect(e.updatedAt, isNull);
    });
  });

  group('Friendship', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'f1',
        'player_id': 'p1',
        'friend_id': 'p2',
        'status': 'accepted',
        'inserted_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-02T00:00:00Z',
      };
      final f = Friendship.fromJson(json);
      expect(f.id, 'f1');
      expect(f.playerId, 'p1');
      expect(f.friendId, 'p2');
      expect(f.status, 'accepted');
    });
  });

  group('Group', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'g1',
        'name': 'Awesome Guild',
        'description': 'We are awesome',
        'max_members': 50,
        'open': true,
        'creator_id': 'p1',
        'inserted_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-02T00:00:00Z',
      };
      final g = Group.fromJson(json);
      expect(g.id, 'g1');
      expect(g.name, 'Awesome Guild');
      expect(g.description, 'We are awesome');
      expect(g.maxMembers, 50);
      expect(g.open, true);
      expect(g.creatorId, 'p1');
    });

    test('fromJson with null description', () {
      final json = {
        'id': 'g2',
        'name': 'No Desc',
        'max_members': 10,
        'open': false,
        'creator_id': 'p1',
        'inserted_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-02T00:00:00Z',
      };
      final g = Group.fromJson(json);
      expect(g.description, isNull);
    });
  });

  group('ChatMessage', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'cm1',
        'channel_type': 'group',
        'channel_id': 'g1',
        'sender_id': 'p1',
        'content': 'Hello!',
        'sent_at': '2026-01-01T00:00:00Z',
      };
      final cm = ChatMessage.fromJson(json);
      expect(cm.id, 'cm1');
      expect(cm.channelType, 'group');
      expect(cm.channelId, 'g1');
      expect(cm.senderId, 'p1');
      expect(cm.content, 'Hello!');
    });
  });

  group('Tournament', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 't1',
        'name': 'Weekly Cup',
        'leaderboard_id': 'lb1',
        'max_entries': 100,
        'status': 'active',
        'start_at': '2026-01-01T00:00:00Z',
        'end_at': '2026-01-07T23:59:59Z',
        'inserted_at': '2026-01-01T00:00:00Z',
      };
      final t = Tournament.fromJson(json);
      expect(t.id, 't1');
      expect(t.name, 'Weekly Cup');
      expect(t.leaderboardId, 'lb1');
      expect(t.maxEntries, 100);
      expect(t.status, 'active');
      expect(t.startAt, '2026-01-01T00:00:00Z');
      expect(t.endAt, '2026-01-07T23:59:59Z');
    });
  });

  group('Notification', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'n1',
        'player_id': 'p1',
        'type': 'friend_request',
        'subject': 'New friend request',
        'content': 'Bob wants to be your friend',
        'read': false,
        'sent_at': '2026-01-01T00:00:00Z',
      };
      final n = Notification.fromJson(json);
      expect(n.id, 'n1');
      expect(n.playerId, 'p1');
      expect(n.type, 'friend_request');
      expect(n.subject, 'New friend request');
      expect(n.content, 'Bob wants to be your friend');
      expect(n.read, false);
    });
  });

  group('WsMessage', () {
    test('fromJson parses correctly', () {
      final json = {
        'type': 'match_found',
        'payload': {'match_id': 'm1'},
        'cid': 'c1',
      };
      final ws = WsMessage.fromJson(json);
      expect(ws.type, 'match_found');
      expect(ws.payload['match_id'], 'm1');
      expect(ws.cid, 'c1');
    });

    test('fromJson defaults payload to empty map', () {
      final json = {'type': 'ping'};
      final ws = WsMessage.fromJson(json);
      expect(ws.payload, isEmpty);
      expect(ws.cid, isNull);
    });
  });

  group('IAPResult', () {
    test('fromJson parses correctly', () {
      final json = {
        'product_id': 'com.game.gems100',
        'transaction_id': 'txn1',
        'order_id': 'ord1',
        'valid': true,
      };
      final r = IAPResult.fromJson(json);
      expect(r.productId, 'com.game.gems100');
      expect(r.transactionId, 'txn1');
      expect(r.orderId, 'ord1');
      expect(r.valid, true);
    });

    test('fromJson defaults valid to false', () {
      final json = <String, dynamic>{};
      final r = IAPResult.fromJson(json);
      expect(r.valid, false);
      expect(r.productId, isNull);
    });

    test('fromJson falls back transactionId to orderId', () {
      final json = {
        'order_id': 'ord1',
        'valid': true,
      };
      final r = IAPResult.fromJson(json);
      expect(r.transactionId, 'ord1');
    });
  });

  group('LinkResponse', () {
    test('fromJson parses correctly', () {
      final json = {
        'provider': 'google',
        'provider_uid': 'uid123',
        'linked': true,
      };
      final r = LinkResponse.fromJson(json);
      expect(r.provider, 'google');
      expect(r.providerUid, 'uid123');
      expect(r.linked, true);
    });

    test('fromJson defaults linked to false', () {
      final json = {
        'provider': 'apple',
        'provider_uid': 'uid456',
      };
      final r = LinkResponse.fromJson(json);
      expect(r.linked, false);
    });
  });

  group('AsobiHttpClient', () {
    test('sets Authorization header when sessionToken is set', () {
      final client = AsobiHttpClient('http://localhost:8080');
      client.sessionToken = 'my-token';
      // Access headers via the getter (it's a computed map)
      final headers = client.headers;
      expect(headers['Authorization'], 'Bearer my-token');
    });

    test('omits Authorization header when sessionToken is null', () {
      final client = AsobiHttpClient('http://localhost:8080');
      final headers = client.headers;
      expect(headers.containsKey('Authorization'), false);
    });

    test('throws AsobiException on 400+', () {
      final response = http.Response(
        jsonEncode({'error': 'Not Found'}),
        404,
      );
      final client = AsobiHttpClient('http://localhost:8080');
      expect(
        () => client.handleResponse(response),
        throwsA(isA<AsobiException>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.message, 'message', 'Not Found')),
      );
    });

    test('throws with default message when error key missing', () {
      final response = http.Response('{}', 500);
      final client = AsobiHttpClient('http://localhost:8080');
      expect(
        () => client.handleResponse(response),
        throwsA(isA<AsobiException>()
            .having((e) => e.message, 'message', 'HTTP 500')),
      );
    });

    test('handles empty response body', () {
      final response = http.Response('', 204);
      final client = AsobiHttpClient('http://localhost:8080');
      final result = client.handleResponse(response);
      expect(result, isEmpty);
    });

    test('parses valid JSON response', () {
      final response = http.Response(jsonEncode({'ok': true}), 200);
      final client = AsobiHttpClient('http://localhost:8080');
      final result = client.handleResponse(response);
      expect(result['ok'], true);
    });
  });

  group('AsobiConfig', () {
    test('generates correct baseUrl without SSL', () {
      final config = AsobiConfig('localhost', port: 8080);
      expect(config.baseUrl, 'http://localhost:8080');
    });

    test('generates correct baseUrl with SSL', () {
      final config = AsobiConfig('example.com', port: 443, useSsl: true);
      expect(config.baseUrl, 'https://example.com:443');
    });

    test('generates correct wsUrl without SSL', () {
      final config = AsobiConfig('localhost', port: 8080);
      expect(config.wsUrl, 'ws://localhost:8080/ws');
    });

    test('generates correct wsUrl with SSL', () {
      final config = AsobiConfig('example.com', port: 443, useSsl: true);
      expect(config.wsUrl, 'wss://example.com:443/ws');
    });
  });

  group('AsobiClient', () {
    test('initializes all API modules', () {
      final client = AsobiClient('localhost');
      expect(client.auth, isNotNull);
      expect(client.players, isNotNull);
      expect(client.matchmaker, isNotNull);
      expect(client.matches, isNotNull);
      expect(client.leaderboards, isNotNull);
      expect(client.economy, isNotNull);
      expect(client.inventory, isNotNull);
      expect(client.social, isNotNull);
      expect(client.tournaments, isNotNull);
      expect(client.notifications, isNotNull);
      expect(client.storage, isNotNull);
      expect(client.iap, isNotNull);
      expect(client.votes, isNotNull);
      expect(client.realtime, isNotNull);
    });

    test('sessionToken propagates to http client', () {
      final client = AsobiClient('localhost');
      expect(client.http.sessionToken, isNull);
      client.sessionToken = 'abc123';
      expect(client.http.sessionToken, 'abc123');
    });

    test('isAuthenticated reflects token state', () {
      final client = AsobiClient('localhost');
      expect(client.isAuthenticated, false);
      client.sessionToken = 'tok';
      expect(client.isAuthenticated, true);
      client.sessionToken = null;
      expect(client.isAuthenticated, false);
    });
  });
}
