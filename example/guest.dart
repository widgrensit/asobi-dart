import 'package:asobi/asobi.dart';

/// Guest / anonymous auth.
///
/// A guest is a real player (with a persistent `playerId`) that needs no
/// username or password. The device holds a [DeviceCredentials] keypair; the
/// same pair resumes the same player on every launch. `guestDevice` manages
/// that keypair for you (generate on first run, persist, reuse) and signs in.
Future<void> main() async {
  final client = AsobiClient('localhost', port: 8084);

  // --- The one-call flow (recommended) --------------------------------
  // Generates + saves the keypair on first run, reuses it after, signs in.
  // Standalone Dart persists under the OS app-support dir by default; inject a
  // `store:` (e.g. shared_preferences-backed on mobile) to choose where.
  final auth = await client.auth.guestDevice();

  // playerId is who you are in the backend - use it for everything.
  if (auth.created) {
    print('brand-new guest: ${auth.playerId}');
    // ... run first-time onboarding here ...
  } else {
    print('welcome back, guest: ${auth.playerId}');
  }

  // You now have an authenticated session. Do backend things:
  await client.leaderboards.submitScore('weekly', 1500);

  // --- Turning a guest into a real account ----------------------------
  // Call this when the player wants their progress to survive a reinstall or
  // move to another device. The playerId is KEPT - a username/password is just
  // added to the same player.
  // await client.auth.upgradeGuest('player1', 'secret123');

  // --- Switch guest / "forget me" / delete-my-data --------------------
  // Erase the stored keypair. The NEXT guestDevice mints a brand-new guest
  // (created == true). Local-only - it does not delete the server account, so
  // pair it with logout to end the current session. Pass the same store you
  // signed in with.
  // final store = FileDeviceStore.defaultLocation();
  // await client.auth.logout();
  // await AsobiDevice.clear(store);

  // --- Bring your own credentials -------------------------------------
  // Prefer to manage the keypair yourself (e.g. an OS keychain)? Skip the
  // helper and pass the values to guest() directly. deviceSecret must be
  // standard base64 of >= 32 random bytes; deviceId is any stable per-install
  // id.
  // final creds = AsobiDevice.generate();
  // await client.auth.guest(creds.deviceId, creds.deviceSecret);

  await client.dispose();
}
