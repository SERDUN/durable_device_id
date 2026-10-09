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

## Comparison with other packages

Several packages on pub.dev already give a device identifier that outlives a reinstall. This one exists because we
needed a combination none of them had: an identifier that is scoped to the app on every Android version, never a
hardware identifier, a call that cannot throw, and the web. The table is what their published code did when we read it
in October 2026.

|                                   | durable_device_id            | [flutter_udid] 4.1.6       | [stable_device_id] 0.2.0            | [persistent_device_id] 2.0.0             |
|-----------------------------------|------------------------------|----------------------------|-------------------------------------|------------------------------------------|
| Android source                    | `ANDROID_ID`                 | `ANDROID_ID`               | `ANDROID_ID`, Widevine on request   | Widevine, else a UUID in app storage     |
| What leaves the Android side      | digest with the package name | the raw value              | the raw value (Widevine: a digest)  | the raw Widevine identifier              |
| Scoped to the app below Android 8 | yes                          | no                         | no                                  | n/a                                      |
| iOS source                        | Keychain                     | Keychain                   | Keychain                            | Keychain                                 |
| Native dependencies               | none                         | KeychainAccess             | none                                | AndroidX Security Crypto                 |
| Web                               | local storage                | no                         | no                                  | no                                       |
| macOS, Windows, Linux             | no                           | yes                        | no                                  | no                                       |
| When there is no identifier       | `null`                       | throws                     | throws                              | `null`, channel errors throw             |
| Faking it in tests                | an interface                 | static call                | platform interface                  | platform interface                       |

What the differences mean in practice:

- **No raw system identifier leaves the device.** The backend receives a digest of `ANDROID_ID` and the package name.
  Below Android 8 `ANDROID_ID` is one value for every app on the phone, so a raw value there identifies the user
  across apps; the digest does not.
- **No hardware identifier.** The Widevine device ID belongs to the hardware and usually survives a factory reset.
  That is more than "the same phone after a reinstall" needs, and a factory reset is a point where a device changing
  hands should become a new device.
- **One answer for "no identifier".** `read()` returns `null` on an unsupported platform, an empty system value, a
  Keychain that cannot be read yet, a missing plugin registration or any other failure. There is nothing to catch.
- **The web is covered, with its limits stated.** The others leave the web out; this one gives the best a browser has
  and says where it ends.
- **Nothing to audit but this package.** Around 150 lines of Kotlin and Swift, no native libraries pulled in.

When another package is the better choice:

- You need **desktop** platforms: `flutter_udid` has them, this package does not.
- You need the identifier to **survive a factory reset**: only the Widevine-based ones can, with the trade-off above.
- You are moving an iOS app that already has an identifier and want to **keep that value**: `stable_device_id` can
  seed the Keychain with it. This package always generates its own.
- You want a package with **years of use behind it**: `flutter_udid` has that; this one is new.

[flutter_udid]: https://pub.dev/packages/flutter_udid
[stable_device_id]: https://pub.dev/packages/stable_device_id
[persistent_device_id]: https://pub.dev/packages/persistent_device_id

## Example

The [example](example) app shows the identifier and prints it to the device log, which is the quickest way to check
the reinstall behavior on a phone of your own.
