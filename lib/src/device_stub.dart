import 'device.dart';

/// Fallback for platforms without `dart:io` (Flutter web). There is no default
/// on-disk location there, so [AsobiAuth.guestDevice] must be given an explicit
/// `store:` - e.g. one backed by `shared_preferences`.
DeviceStore defaultDeviceStore({String app = 'asobi'}) =>
    throw UnsupportedError(
      'No default DeviceStore on this platform (no dart:io). Pass a store: to '
      'AsobiAuth.guestDevice, e.g. one backed by shared_preferences.',
    );
