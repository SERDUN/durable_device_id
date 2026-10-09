# durable_device_id_example

Shows the identifier `durable_device_id` gives on this device.

```sh
flutter run
```

Note the identifier, remove the app, install it again and compare: on Android and iOS it is
the same. The value is also printed to the device log as `durable_device_id: <id>`.

To check the platform side without the UI:

```sh
flutter test integration_test -d <device>
```
