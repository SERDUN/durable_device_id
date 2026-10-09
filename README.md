# durable_device_id

[![pub package](https://img.shields.io/pub/v/durable_device_id.svg)](https://pub.dev/packages/durable_device_id)

A Flutter plugin that gives an identifier of the device which stays the same after the app is removed and installed
again.

An identifier an app generates and keeps in its own data is lost with a reinstall, so a backend that tells devices
apart by it sees the same phone come back as a new one. That matters as soon as something is counted per device: a
limit on signed-in devices, a list of active sessions, a trusted-device check. This plugin takes the identifier from
where the platform keeps it outside the app.

## Features

- **Survives a reinstall:** on Android and iOS the identifier is the same after the app is removed and installed again,
  and after its data is cleared.
- **Scoped to the app:** another app on the same device gets another identifier, so it cannot be used to follow a user
  across apps.
- **Never throws:** `read()` answers `null` when the platform has no identifier to give or anything goes wrong, and
  the app falls back to its own.
- **Web included:** in a browser the identifier is kept in local storage, with the limits a browser has.
- **No permissions**, no advertising identifier, no hardware serials.
- **Testable:** depend on the `DurableDeviceId` interface and pass a fake.

## Requirements

- Flutter 3.47 or later.
- Android: Android 7.0 (API 24) or later, and an app built with Android Gradle Plugin 9 or later. The plugin relies
  on the Kotlin support built into AGP 9 and does not build in an app that is still on AGP 8.
- iOS 13 or later.

## Installation

Add the following line to your `pubspec.yaml` under dependencies:

```yaml
dependencies:
  durable_device_id: ^0.1.0
```

Then, run:

```sh
flutter pub get
```

## Usage

```dart
import 'package:durable_device_id/durable_device_id.dart';

const DurableDeviceId deviceId = PlatformDurableDeviceId();

Future<String> resolveIdentifier() async {
  final id = await deviceId.read();
  // null: the platform has none to give. Fall back to an identifier of your own.
  return id ?? await generatedAndStoredIdentifier();
}
```

`null` is an answer, not a failure to retry: it means this platform, or this device right now, has no durable
identifier. Keep a fallback.

The identifier cannot change while the app runs, so the platform is asked once and later calls answer from memory. A
`null` is not remembered: the next call asks again.

In tests, implement the interface:

```dart
class FakeDeviceId implements DurableDeviceId {
  @override
  Future<String?> read() async => 'test-device';
}
```

## Platform behavior

| Platform    | Source                       | Details                                                                                                                                              |
|-------------|------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Android** | `Settings.Secure.ANDROID_ID` | SHA-256 of the package name and the system value, 64 lowercase hex characters. `null` when the system value is empty.                                |
| **iOS**     | Keychain                     | A UUID created on the first call and kept in the Keychain, readable after the first unlock and bound to this device. `null` while it cannot be read. |
| **Web**     | `window.localStorage`        | A UUID created on the first call, under a key that carries the path the app is served from.                                                          |
| **Others**  | none                         | Always `null`.                                                                                                                                       |

The raw `ANDROID_ID` never leaves the native side; only the digest does.

The identifier belongs to one app. On Android the package name is part of the digest. On iOS the Keychain item is
named after the bundle identifier, so apps that share a Keychain access group still get different identifiers. On the
web the storage key carries the path of the app, so two apps under one domain keep two identifiers.

## Identifier lifetime

| Event                                            | Android   | iOS  | Web  |
|--------------------------------------------------|-----------|------|------|
| App update, restart, page reload                 | same      | same | same |
| Reinstall, cleared app data                      | same      | same | -    |
| Cleared site data, private window                | -         | -    | new  |
| Another browser or browser profile               | -         | -    | new  |
| A site not visited for a week (Safari)           | -         | -    | new  |
| The app moved to another path of the domain      | -         | -    | new  |
| Factory reset                                    | new       | new  | new  |
| Another signing key (Android 8+)                 | new       | -    | -    |
| Another user or work profile                     | new       | -    | -    |
| Backup restored on another device                | new       | new  | -    |
| OS upgrade from Android 7 to 8, then a reinstall | new, once | -    | -    |

Things to know before relying on it:

- **Android signing key.** From Android 8 on, `ANDROID_ID` is different for every signing key. A debug build and the
  build from the store give different identifiers on the same phone.
- **iOS Keychain.** iOS has so far kept Keychain items when an app is removed, and this plugin relies on that. Apple
  does not document it as a guarantee.
- **Web.** A page has nothing that outlives cleared site data, so a cleared browser is a new device. The plugin does
  not fingerprint the browser to get around that.
- **Safari.** Safari deletes the local storage of a site the user has not opened for seven days. A user who comes
  back after a week is a new device there. Do not count devices on the web by this identifier alone.
- **Two tabs at once.** Tabs opened together agree on one identifier through the Web Locks API. Where it is missing
  (an old browser, a page not served over HTTPS) two tabs opened at the very same moment on a first visit can each
  get one, and only the later one is kept.

## Example

The [example](example) app shows the identifier and prints it to the device log, which is the quickest way to check
the reinstall behavior on a phone of your own.
