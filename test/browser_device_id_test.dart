@TestOn('browser')
library;

import 'package:flutter/foundation.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

import 'package:durable_device_id/durable_device_id.dart';
import 'package:durable_device_id/src/stored_device_id.dart';

void main() {
  final key = storageKey(web.document.baseURI);
  const DurableDeviceId deviceId = PlatformDurableDeviceId();

  // Forgetting stands for a new page load: the storage is what is under test.
  setUp(() {
    web.window.localStorage.removeItem(key);
    PlatformDurableDeviceId.debugForget();
  });
  tearDown(() => web.window.localStorage.removeItem(key));

  test('this test runs in a browser', () {
    expect(kIsWeb, isTrue);
  });

  test('read creates an identifier in local storage', () async {
    final id = await deviceId.read();

    expect(id, isNotNull);
    expect(web.window.localStorage.getItem(key), id);
  });

  test('read returns the same identifier on the next page load', () async {
    final first = await deviceId.read();
    PlatformDurableDeviceId.debugForget();

    expect(await deviceId.read(), first);
  });

  test('read returns the identifier local storage already holds', () async {
    web.window.localStorage.setItem(key, 'kept-from-an-earlier-visit');

    expect(await deviceId.read(), 'kept-from-an-earlier-visit');
  });

  test('read gives a new identifier once site data is cleared', () async {
    final first = await deviceId.read();
    web.window.localStorage.removeItem(key);
    PlatformDurableDeviceId.debugForget();

    expect(await deviceId.read(), isNot(first));
  });

  test('reads started together agree on one identifier', () async {
    final ids = await Future.wait([
      for (var i = 0; i < 8; i++) const PlatformDurableDeviceId().read(),
    ]);

    expect(ids.toSet(), hasLength(1));
    expect(web.window.localStorage.getItem(key), ids.first);
  });
}
