// Runs on a device or a browser, against the real platform side:
//
//   flutter test integration_test -d <device>

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:durable_device_id/durable_device_id.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const DurableDeviceId deviceId = PlatformDurableDeviceId();

  testWidgets('read gives an identifier', (tester) async {
    final id = await deviceId.read();

    expect(id, isNotNull);
    expect(id, isNotEmpty);
  });

  testWidgets('read gives the same identifier every time', (tester) async {
    final first = await deviceId.read();

    expect(await deviceId.read(), first);
    expect(await deviceId.read(), first);
  });
}
