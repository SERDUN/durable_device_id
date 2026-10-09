import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'stored_device_id.dart';

/// The identifier kept in the browser's local storage for this app.
///
/// It lasts through a reload and a restart of the browser. It does not last
/// through cleared site data or a private window, another browser on the same
/// computer has its own, and a browser may clear the storage of a site that
/// has not been visited for a while (Safari does after seven days).
Future<String?> browserDeviceId() async {
  final storage = _LocalStorage(storageKey(web.document.baseURI));

  // Read, write and read back are three steps, and two tabs opened together
  // can interleave them. The lock makes them one step across the tabs of the
  // origin.
  final navigator = web.window.navigator as JSObject;
  if (navigator.has('locks')) {
    try {
      final held = await web.window.navigator.locks
          .request(
            storage.key,
            ((JSAny? _) => storedDeviceId(storage)?.toJS).toJS,
          )
          .toDart;
      return (held as JSString?)?.toDart;
    } catch (_) {
      // Fall through: an identifier without the lock is better than none.
    }
  }

  // No Web Locks here (an old browser, or a page not served securely).
  return storedDeviceId(storage);
}

class _LocalStorage implements DeviceIdStorage {
  const _LocalStorage(this.key);

  final String key;

  @override
  String? read() => web.window.localStorage.getItem(key);

  @override
  void write(String id) => web.window.localStorage.setItem(key, id);
}
