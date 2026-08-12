import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:asobi/src/token_store.dart';

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
import 'package:asobi/src/models/vote_models.dart';
import 'package:asobi/src/models/realtime_models.dart';
import 'package:asobi/src/http_client.dart';
import 'package:asobi/src/asobi_client.dart';

void main() {
  group('AuthResponse', () {
    test('fromJson parses token pair', () {
      final json = {
        'player_id': 'p1',
        'access_token': 'access123',
        'refresh_token': 'refresh123',
        'username': 'alice',
      };
      final r = AuthResponse.fromJson(json);
      expect(r.playerId, 'p1');
      expect(r.accessToken, 'access123');
      expect(r.refreshToken, 'refresh123');
      expect(r.username, 'alice');
    });
  });

  group('OAuthResponse', () {
    test('fromJson parses token pair', () {
      final json = {
        'player_id': 'p2',
        'access_token': 'oauth-access',
        'refresh_token': 'oauth-refresh',
        'username': 'bob',
        'created': true,
      };
      final r = OAuthResponse.fromJson(json);
      expect(r.playerId, 'p2');
      expect(r.accessToken, 'oauth-access');
      expect(r.refreshToken, 'oauth-refresh');
      expect(r.username, 'bob');
      expect(r.created, true);
    });

    test('fromJson defaults created to false', () {
      final json = {
        'player_id': 'p2',
        'access_token': 'a',
        'refresh_token': 'r',
        'username': 'bob',
      };
      final r = OAuthResponse.fromJson(json);
      expect(r.created, false);
    });
  });

  group('RefreshResponse', () {
    test('fromJson parses rotated token pair', () {
      final json = {'access_token': 'new-access', 'refresh_token': 'new-refresh'};
      final r = RefreshResponse.fromJson(json);
      expect(r.accessToken, 'new-access');
      expect(r.refreshToken, 'new-refresh');
    });
  });

  group('Player', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'p1',
        'username': 'alice',
        'display_name': 'Alice',
        'avatar_url': 'https://example.com/a.png',
        'metadata': {'level': 3},
        'inserted_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-02T00:00:00Z',
      };
      final p = Player.fromJson(json);
      expect(p.id, 'p1');
      expect(p.username, 'alice');
      expect(p.displayName, 'Alice');
      expect(p.avatarUrl, 'https://example.com/a.png');
      expect(p.metadata, {'level': 3});
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
      expect(p.metadata, isEmpty);
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

  group('MatchResult', () {
    test('fromJson reads the match.finished result object', () {
      final json = {
        'match_id': 'm1',
        'result': {
          'winner': 'p1',
          'losers': ['p2'],
          'scores': {'p1': 10, 'p2': 3},
        },
      };
      final r = MatchResult.fromJson(json);
      expect(r.matchId, 'm1');
      expect(r.result['winner'], 'p1');
      expect(r.result['losers'], ['p2']);
      expect(r.toJson()['result'], json['result']);
    });

    test('fromJson defaults result to empty when the game returned none', () {
      final r = MatchResult.fromJson({'match_id': 'm2'});
      expect(r.matchId, 'm2');
      expect(r.result, isEmpty);
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
      expect(cm.sentAt, '2026-01-01T00:00:00Z');
    });

    test('fromJson accepts the integer sent_at of a live chat/dm frame', () {
      final json = {
        'channel_id': 'world:w1',
        'sender_id': 'p1',
        'content': 'Hello!',
        'sent_at': 1785312000000,
      };
      final cm = ChatMessage.fromJson(json);
      expect(cm.sentAt, '1785312000000');
      expect(cm.senderId, 'p1');
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
      expect(t.entryFee, isEmpty);
      expect(t.rewards, isEmpty);
      expect(t.metadata, isEmpty);
    });

    test('fromJson parses the jsonb entry_fee, rewards and metadata', () {
      final json = {
        'id': 't2',
        'name': 'Season Final',
        'leaderboard_id': 'lb2',
        'max_entries': 32,
        'status': 'pending',
        'start_at': '2026-01-01T00:00:00Z',
        'end_at': '2026-01-07T23:59:59Z',
        'inserted_at': '2026-01-01T00:00:00Z',
        'entry_fee': {'currency': 'gold', 'amount': 100},
        'rewards': {
          '1': {'currency': 'gold', 'amount': 1000}
        },
        'metadata': {'season': 3},
      };
      final t = Tournament.fromJson(json);
      expect(t.entryFee['currency'], 'gold');
      expect(t.entryFee['amount'], 100);
      expect(t.rewards['1'], {'currency': 'gold', 'amount': 1000});
      expect(t.metadata['season'], 3);
      expect(t.toJson()['entry_fee'], json['entry_fee']);
      expect(t.toJson()['rewards'], json['rewards']);
      expect(t.toJson()['metadata'], json['metadata']);
    });
  });

  group('Notification', () {
    test('fromJson parses the REST record with jsonb content', () {
      final json = {
        'id': 'n1',
        'player_id': 'p1',
        'type': 'friend_request',
        'subject': 'New friend request',
        'content': {'from': 'p2', 'message': 'Bob wants to be your friend'},
        'read': false,
        'sent_at': '2026-01-01T00:00:00Z',
      };
      final n = Notification.fromJson(json);
      expect(n.id, 'n1');
      expect(n.playerId, 'p1');
      expect(n.type, 'friend_request');
      expect(n.subject, 'New friend request');
      expect(n.content['message'], 'Bob wants to be your friend');
      expect(n.read, false);
    });

    test('fromJson parses the notification.new WS push (kind, no content)', () {
      final n = Notification.fromJson({
        'id': 'n2',
        'kind': 'friend_request',
        'from': 'p2',
      });
      expect(n.id, 'n2');
      expect(n.type, 'friend_request');
      expect(n.content, isEmpty);
    });

    test('fromJson tolerates a legacy string content', () {
      final n = Notification.fromJson({'id': 'n3', 'content': 'hello'});
      expect(n.content['text'], 'hello');
    });
  });

  group('Vote', () {
    test('fromJson parses the backend record shape', () {
      final json = {
        'id': 'v1',
        'match_id': 'm1',
        'template': 'mvp',
        'method': 'plurality',
        'options': ['p1', 'p2'],
        'votes_cast': {'p1': 3, 'p2': 1},
        'result': {'winner': 'p1'},
        'distribution': {'p1': 0.75, 'p2': 0.25},
        'turnout': 0.8,
        'eligible_count': 5,
        'window_ms': 30000,
        'opened_at': '2026-01-01T00:00:00Z',
        'closed_at': '2026-01-01T00:00:30Z',
        'inserted_at': '2026-01-01T00:00:30Z',
      };
      final v = Vote.fromJson(json);
      expect(v.id, 'v1');
      expect(v.matchId, 'm1');
      expect(v.template, 'mvp');
      expect(v.method, 'plurality');
      expect(v.options, ['p1', 'p2']);
      expect(v.votesCast['p1'], 3);
      expect(v.result['winner'], 'p1');
      expect(v.turnout, 0.8);
      expect(v.eligibleCount, 5);
      expect(v.windowMs, 30000);
    });

    test('fromJson does not throw on a hidden vote missing optional fields', () {
      final v = Vote.fromJson({
        'id': 'v2',
        'match_id': 'm1',
        'template': 'mvp',
        'method': 'plurality',
        'window_ms': 30000,
        'inserted_at': '2026-01-01T00:00:30Z',
      });
      expect(v.votesCast, isEmpty);
      expect(v.turnout, 0.0);
      expect(v.openedAt, isNull);
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
    test('sets Authorization header when accessToken is set', () {
      final client = AsobiHttpClient('http://localhost:8080');
      client.accessToken = 'my-token';
      final headers = client.headers;
      expect(headers['Authorization'], 'Bearer my-token');
    });

    test('omits Authorization header when accessToken is null', () {
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

    test('accessToken propagates to http client', () {
      final client = AsobiClient('localhost');
      expect(client.http.accessToken, isNull);
      client.accessToken = 'abc123';
      expect(client.http.accessToken, 'abc123');
    });

    test('isAuthenticated reflects access token state', () {
      final client = AsobiClient('localhost');
      expect(client.isAuthenticated, false);
      client.accessToken = 'tok';
      expect(client.isAuthenticated, true);
      client.accessToken = null;
      expect(client.isAuthenticated, false);
    });
  });

  group('AsobiPlayers.update', () {
    test('sends metadata alongside display_name and avatar_url', () async {
      Map<String, dynamic>? sentBody;
      final mock = MockClient((req) async {
        expect(req.url.path, '/api/v1/players/p1');
        expect(req.method, 'PUT');
        sentBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'id': 'p1',
            'username': 'alice',
            'display_name': 'Alice',
            'metadata': {'level': 7},
            'inserted_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-02T00:00:00Z',
          }),
          200,
        );
      });
      final client = AsobiClient.fromConfig(AsobiConfig('localhost'),
          httpClient: mock, tokenStore: InMemoryTokenStore());
      client.accessToken = 'access-1';

      await client.players.update(
        'p1',
        displayName: 'Alice',
        avatarUrl: 'https://example.com/a.png',
        metadata: {'level': 7},
      );

      expect(sentBody!['display_name'], 'Alice');
      expect(sentBody!['avatar_url'], 'https://example.com/a.png');
      expect(sentBody!['metadata'], {'level': 7});
    });

    test('omits metadata when not provided', () async {
      Map<String, dynamic>? sentBody;
      final mock = MockClient((req) async {
        sentBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'id': 'p1',
            'username': 'alice',
            'display_name': 'Alice',
            'inserted_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-02T00:00:00Z',
          }),
          200,
        );
      });
      final client = AsobiClient.fromConfig(AsobiConfig('localhost'),
          httpClient: mock, tokenStore: InMemoryTokenStore());
      client.accessToken = 'access-1';

      await client.players.update('p1', displayName: 'Alice');

      expect(sentBody!.containsKey('metadata'), false);
    });
  });

  group('RealtimeError', () {
    test('fromJson prefers reason over message and error', () {
      final e = RealtimeError.fromJson({
        'reason': 'invalid_message',
        'message': 'ignored',
        'error': 'ignored',
      });
      expect(e.message, 'invalid_message');
    });

    test('fromJson falls back to message then error', () {
      expect(RealtimeError.fromJson({'message': 'boom'}).message, 'boom');
      expect(RealtimeError.fromJson({'error': 'bang'}).message, 'bang');
      expect(RealtimeError.fromJson(<String, dynamic>{}).message, 'Unknown error');
    });
  });

  group('AsobiRealtime error dispatch', () {
    test('onError surfaces payload.reason', () async {
      final client = AsobiClient('localhost');
      final got = client.realtime.onError.stream.first;
      client.realtime.debugHandleMessage(
        '{"type":"error","payload":{"reason":"rate_limited"}}',
      );
      final err = await got.timeout(const Duration(seconds: 1));
      expect(err.message, 'rate_limited');
    });
  });

  group('InMemoryTokenStore', () {
    test('write/read/clear round-trips the refresh token', () async {
      final store = InMemoryTokenStore();
      expect(await store.read(), isNull);
      await store.write('refresh-1');
      expect(await store.read(), 'refresh-1');
      await store.clear();
      expect(await store.read(), isNull);
    });
  });

  group('401 refresh interceptor', () {
    test('refreshes token pair and retries the original request once', () async {
      var protectedCalls = 0;
      var refreshCalls = 0;
      final mock = MockClient((req) async {
        if (req.url.path == '/api/v1/players/me') {
          protectedCalls++;
          if (req.headers['Authorization'] == 'Bearer new-access') {
            return http.Response(jsonEncode({'ok': true}), 200);
          }
          return http.Response(jsonEncode({'error': 'invalid_token'}), 401);
        }
        if (req.url.path == '/api/v1/auth/refresh') {
          refreshCalls++;
          expect(jsonDecode(req.body)['refresh_token'], 'refresh-1');
          return http.Response(
            jsonEncode({'access_token': 'new-access', 'refresh_token': 'refresh-2'}),
            200,
          );
        }
        return http.Response('{}', 404);
      });
      final store = InMemoryTokenStore();
      await store.write('refresh-1');
      final client =
          AsobiHttpClient('http://x', httpClient: mock, tokenStore: store);
      client.accessToken = 'old-access';

      final result = await client.get('/api/v1/players/me');

      expect(result['ok'], true);
      expect(protectedCalls, 2);
      expect(refreshCalls, 1);
      expect(client.accessToken, 'new-access');
      expect(await store.read(), 'refresh-2');
    });

    test('surfaces AsobiAuthExpiredException when refresh fails', () async {
      final mock = MockClient((req) async {
        if (req.url.path == '/api/v1/auth/refresh') {
          return http.Response(jsonEncode({'error': 'invalid_token'}), 401);
        }
        return http.Response(jsonEncode({'error': 'invalid_token'}), 401);
      });
      final store = InMemoryTokenStore();
      await store.write('refresh-dead');
      final client =
          AsobiHttpClient('http://x', httpClient: mock, tokenStore: store);
      client.accessToken = 'old-access';

      expect(
        () => client.get('/api/v1/players/me'),
        throwsA(isA<AsobiAuthExpiredException>()),
      );
    });

    test('does not attempt refresh for /auth/ paths', () async {
      var refreshCalls = 0;
      final mock = MockClient((req) async {
        if (req.url.path == '/api/v1/auth/refresh') refreshCalls++;
        return http.Response(jsonEncode({'error': 'invalid_credentials'}), 401);
      });
      final store = InMemoryTokenStore();
      await store.write('refresh-1');
      final client =
          AsobiHttpClient('http://x', httpClient: mock, tokenStore: store);

      expect(
        () => client.post('/api/v1/auth/login', body: {'username': 'a'}),
        throwsA(isA<AsobiException>()
            .having((e) => e.statusCode, 'statusCode', 401)),
      );
      await Future<void>.delayed(Duration.zero);
      expect(refreshCalls, 0);
    });
  });

  group('AsobiAuth flow', () {
    test('login stores both tokens and player id', () async {
      final mock = MockClient((req) async {
        expect(req.url.path, '/api/v1/auth/login');
        return http.Response(
          jsonEncode({
            'player_id': 'p1',
            'access_token': 'access-1',
            'refresh_token': 'refresh-1',
            'username': 'alice',
          }),
          200,
        );
      });
      final client = AsobiClient.fromConfig(AsobiConfig('localhost'),
          httpClient: mock, tokenStore: InMemoryTokenStore());

      final auth = await client.auth.login('alice', 'pw');

      expect(auth.accessToken, 'access-1');
      expect(client.accessToken, 'access-1');
      expect(await client.refreshToken, 'refresh-1');
      expect(client.playerId, 'p1');
      expect(client.isAuthenticated, true);
    });

    test('refresh rotates and stores the new token pair', () async {
      final mock = MockClient((req) async {
        expect(req.url.path, '/api/v1/auth/refresh');
        expect(jsonDecode(req.body)['refresh_token'], 'refresh-1');
        return http.Response(
          jsonEncode({'access_token': 'access-2', 'refresh_token': 'refresh-2'}),
          200,
        );
      });
      final store = InMemoryTokenStore();
      await store.write('refresh-1');
      final client = AsobiClient.fromConfig(AsobiConfig('localhost'),
          httpClient: mock, tokenStore: store);
      client.accessToken = 'access-1';

      final result = await client.auth.refresh();

      expect(result.accessToken, 'access-2');
      expect(result.refreshToken, 'refresh-2');
      expect(client.accessToken, 'access-2');
      expect(await store.read(), 'refresh-2');
    });

    test('logout posts refresh token with bearer and clears tokens', () async {
      Map<String, dynamic>? logoutBody;
      String? logoutAuth;
      final mock = MockClient((req) async {
        expect(req.url.path, '/api/v1/auth/logout');
        logoutBody = jsonDecode(req.body) as Map<String, dynamic>;
        logoutAuth = req.headers['Authorization'];
        return http.Response(jsonEncode({'success': true}), 200);
      });
      final store = InMemoryTokenStore();
      await store.write('refresh-1');
      final client = AsobiClient.fromConfig(AsobiConfig('localhost'),
          httpClient: mock, tokenStore: store);
      client.accessToken = 'access-1';
      client.playerId = 'p1';

      await client.auth.logout();

      expect(logoutBody!['refresh_token'], 'refresh-1');
      expect(logoutAuth, 'Bearer access-1');
      expect(client.accessToken, isNull);
      expect(await store.read(), isNull);
      expect(client.playerId, isNull);
      expect(client.isAuthenticated, false);
    });

    test('guest creates and stores both tokens and player id', () async {
      Map<String, dynamic>? guestBody;
      final mock = MockClient((req) async {
        expect(req.url.path, '/api/v1/auth/guest');
        guestBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'player_id': 'g1',
            'access_token': 'guest-access',
            'refresh_token': 'guest-refresh',
            'username': 'guest-1',
            'created': true,
            'guest': true,
          }),
          200,
        );
      });
      final client = AsobiClient.fromConfig(AsobiConfig('localhost'),
          httpClient: mock, tokenStore: InMemoryTokenStore());

      final auth = await client.auth.guest('device-1', 'c2VjcmV0');

      expect(guestBody!['device_id'], 'device-1');
      expect(guestBody!['device_secret'], 'c2VjcmV0');
      expect(auth.accessToken, 'guest-access');
      expect(client.accessToken, 'guest-access');
      expect(await client.refreshToken, 'guest-refresh');
      expect(client.playerId, 'g1');
      expect(client.isAuthenticated, true);
      expect(auth.guest, true);
      expect(auth.created, true);
      expect(auth.upgraded, false);
    });

    test('guest resume omits created flag', () async {
      final mock = MockClient((req) async {
        expect(req.url.path, '/api/v1/auth/guest');
        return http.Response(
          jsonEncode({
            'player_id': 'g1',
            'access_token': 'guest-access',
            'refresh_token': 'guest-refresh',
            'username': 'guest-1',
            'guest': true,
          }),
          200,
        );
      });
      final client = AsobiClient.fromConfig(AsobiConfig('localhost'),
          httpClient: mock, tokenStore: InMemoryTokenStore());

      final auth = await client.auth.guest('device-1', 'c2VjcmV0');

      expect(auth.guest, true);
      expect(auth.created, false);
    });

    test('guest surfaces backend error code', () async {
      final mock = MockClient((req) async {
        expect(req.url.path, '/api/v1/auth/guest');
        return http.Response(jsonEncode({'error': 'weak_device_secret'}), 400);
      });
      final client = AsobiClient.fromConfig(AsobiConfig('localhost'),
          httpClient: mock, tokenStore: InMemoryTokenStore());

      expect(
        () => client.auth.guest('device-1', 'short'),
        throwsA(isA<AsobiException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having((e) => e.message, 'message', 'weak_device_secret')),
      );
    });

    test('upgradeGuest sends bearer and replaces stored tokens', () async {
      Map<String, dynamic>? upgradeBody;
      String? upgradeAuth;
      final mock = MockClient((req) async {
        expect(req.url.path, '/api/v1/auth/guest/upgrade');
        upgradeBody = jsonDecode(req.body) as Map<String, dynamic>;
        upgradeAuth = req.headers['Authorization'];
        return http.Response(
          jsonEncode({
            'player_id': 'g1',
            'access_token': 'claimed-access',
            'refresh_token': 'claimed-refresh',
            'username': 'alice',
            'upgraded': true,
          }),
          200,
        );
      });
      final store = InMemoryTokenStore();
      await store.write('guest-refresh');
      final client = AsobiClient.fromConfig(AsobiConfig('localhost'),
          httpClient: mock, tokenStore: store);
      client.accessToken = 'guest-access';
      client.playerId = 'g1';

      final auth = await client.auth.upgradeGuest('alice', 'pw');

      expect(upgradeBody!['username'], 'alice');
      expect(upgradeBody!['password'], 'pw');
      expect(upgradeAuth, 'Bearer guest-access');
      expect(auth.accessToken, 'claimed-access');
      expect(client.accessToken, 'claimed-access');
      expect(await store.read(), 'claimed-refresh');
      expect(client.playerId, 'g1');
      expect(auth.upgraded, true);
    });
  });
}
