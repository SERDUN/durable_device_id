import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/browser_device_id_stub.dart'
    if (dart.library.js_interop) 'src/browser_device_id_web.dart';

/// Tells one device from another by something the app does not own, so the
/// answer is the same after the app is removed and installed again.
abstract interface class DurableDeviceId {
  /// The identifier of this device for this app, or null when the platform has
  /// none to give.
  ///
  /// Null is an answer, not a failure: the caller is expected to have another
  /// identifier to fall back on, and must not take null for "ask again later".
  Future<String?> read();
}

/// [DurableDeviceId] answered by the platform side of this plugin.
///
/// Android and iOS ask the native side, a browser keeps its own in local
/// storage; every other platform answers null without asking.
class PlatformDurableDeviceId implements DurableDeviceId {
  const PlatformDurableDeviceId();

  static const MethodChannel _methodChannel = MethodChannel(
    'durable_device_id',
  );

  /// The identifier once the platform has given one. It cannot change while
  /// the process lives, so the platform is asked once. A null answer is never
  /// kept: the Keychain may only be unreadable until the first unlock.
  static String? _known;

  /// Forgets the identifier kept from an earlier call.
  @visibleForTesting
  static void debugForget() => _known = null;

  @override
  Future<String?> read() async {
    final known = _known;
    if (known != null) return known;

    final id = await _ask();
    if (id == null || id.isEmpty) return null;
    return _known = id;
  }

  Future<String?> _ask() async {
    try {
      if (kIsWeb) return await browserDeviceId();
      if (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS) {
        return null;
      }

      return await _methodChannel.invokeMethod<String>('read');
    } catch (_) {
      // Whatever went wrong - the native side refused, the plugin is not
      // registered in this isolate, the binding is not up yet - the answer is
      // the same: no identifier from here, and the caller falls back.
      return null;
    }
  }
}
