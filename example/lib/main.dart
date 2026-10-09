import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:durable_device_id/durable_device_id.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({
    super.key,
    this.deviceId = const PlatformDurableDeviceId(),
  });

  final DurableDeviceId deviceId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'durable_device_id',
      home: DeviceIdPage(deviceId: deviceId),
    );
  }
}

class DeviceIdPage extends StatefulWidget {
  const DeviceIdPage({super.key, required this.deviceId});

  final DurableDeviceId deviceId;

  @override
  State<DeviceIdPage> createState() => _DeviceIdPageState();
}

class _DeviceIdPageState extends State<DeviceIdPage> {
  late Future<String?> _id = _read();

  Future<String?> _read() async {
    final id = await widget.deviceId.read();
    // Printed so the value can be compared across reinstalls from the device log.
    debugPrint('durable_device_id: $id');
    return id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('durable_device_id')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<String?>(
            future: _id,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const CircularProgressIndicator();
              }

              final id = snapshot.data;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    id == null
                        ? 'This platform has no durable identifier'
                        : 'Identifier of this device',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (id != null) ...[
                    const SizedBox(height: 16),
                    SelectableText(
                      id,
                      key: const Key('device-id'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Remove the app, install it again and compare.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    children: [
                      if (id != null)
                        OutlinedButton(
                          onPressed: () =>
                              Clipboard.setData(ClipboardData(text: id)),
                          child: const Text('Copy'),
                        ),
                      FilledButton(
                        onPressed: () => setState(() => _id = _read()),
                        child: const Text('Read again'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
