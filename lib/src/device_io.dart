import 'dart:convert';
import 'dart:io';

import 'device.dart';

/// Persists the keypair as JSON at [path]. Pure Dart on a `dart:io` platform
/// (native / Flutter mobile+desktop, not web): the default location lives under
/// the OS app-support/home directory. On mobile, prefer a [DeviceStore] backed
/// by `path_provider` / `shared_preferences` instead.
class FileDeviceStore implements DeviceStore {
  final String path;

  FileDeviceStore(this.path);

  factory FileDeviceStore.defaultLocation({String app = 'asobi'}) =>
      FileDeviceStore(_defaultDevicePath(app));

  @override
  Future<DeviceCredentials?> read() async {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, dynamic>) return null;
      return DeviceCredentials.fromJson(json);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(DeviceCredentials credentials) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(credentials.toJson()));
  }

  @override
  Future<void> clear() async {
    final file = File(path);
    if (file.existsSync()) await file.delete();
  }
}

/// The platform default store used by [AsobiAuth.guestDevice] when no `store:`
/// is injected. Backed by [FileDeviceStore] on `dart:io` platforms.
DeviceStore defaultDeviceStore({String app = 'asobi'}) =>
    FileDeviceStore.defaultLocation(app: app);

String _defaultDevicePath(String app) {
  final env = Platform.environment;
  final home = env['HOME'] ?? Directory.current.path;
  String base;
  if (Platform.isWindows) {
    base = env['APPDATA'] ?? env['USERPROFILE'] ?? Directory.current.path;
  } else if (Platform.isMacOS) {
    base = '$home/Library/Application Support';
  } else {
    base = env['XDG_DATA_HOME'] ?? '$home/.local/share';
  }
  return '$base/$app/guest_device.json';
}
