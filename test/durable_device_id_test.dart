// The native channel is asked on Android and iOS only; a browser never reaches it.
@TestOn('vm')
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:durable_device_id/durable_device_id.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('durable_device_id');
  const DurableDeviceId deviceId = PlatformDurableDeviceId();

  final calls = <String>[];

  void answer(Future<Object?> Function() handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) {
          calls.add(call.method);
          return handler();
        });
  }

  setUp(() {
    calls.clear();
    PlatformDurableDeviceId.debugForget();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('read returns what the platform gives', () async {
    answer(() async => 'a1b2c3');

    expect(await deviceId.read(), 'a1b2c3');
    expect(calls, ['read']);
  });

  test('read asks the platform on iOS too', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    answer(() async => 'a1b2c3');

    expect(await deviceId.read(), 'a1b2c3');
    expect(calls, ['read']);
  });

  test('read returns null when the platform has no identifier', () async {
    answer(() async => null);

    expect(await deviceId.read(), isNull);
  });

  test('read returns null for an empty identifier', () async {
    answer(() async => '');

    expect(await deviceId.read(), isNull);
  });

  test('read returns null when the platform fails', () async {
    answer(() async => throw PlatformException(code: 'unavailable'));

    expect(await deviceId.read(), isNull);
  });

  test('read returns null where the plugin is not registered', () async {
    expect(await deviceId.read(), isNull);
  });

  test('read does not ask a platform that has no implementation', () async {
    answer(() async => 'a1b2c3');

    for (final platform in [
      TargetPlatform.linux,
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.fuchsia,
    ]) {
      debugDefaultTargetPlatformOverride = platform;

      expect(await deviceId.read(), isNull, reason: '$platform');
    }
    expect(calls, isEmpty);
  });

  test('read asks the platform once and remembers the answer', () async {
    answer(() async => 'a1b2c3');

    expect(await deviceId.read(), 'a1b2c3');
    expect(await deviceId.read(), 'a1b2c3');
    expect(await const PlatformDurableDeviceId().read(), 'a1b2c3');
    expect(calls, ['read']);
  });

  test('read asks again after the platform had none to give', () async {
    answer(() async => null);
    expect(await deviceId.read(), isNull);

    answer(() async => 'a1b2c3');
    expect(await deviceId.read(), 'a1b2c3');
    expect(calls, ['read', 'read']);
  });

  test('read returns null for a failure of any kind', () async {
    answer(() async => throw StateError('no binary messenger'));
    expect(await deviceId.read(), isNull);

    answer(() async => 42);
    expect(await deviceId.read(), isNull);
  });
}
