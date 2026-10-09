## 0.1.0

### Added

- `DurableDeviceId.read()` and its platform-backed implementation `PlatformDurableDeviceId`.
- Android: a SHA-256 digest of the package name and `Settings.Secure.ANDROID_ID`.
- iOS: a UUID kept in the Keychain under the bundle identifier, readable after the first unlock and bound to the
  device.
- Web: a UUID kept in the local storage of the origin, under a key that carries the path of the app; tabs opened
  together agree on one identifier through the Web Locks API.
- Other platforms, and every failure, answer `null`.
- The platform is asked once per run; a `null` answer is not remembered.

### Requirements

- Flutter 3.47 or later; on Android an app built with Android Gradle Plugin 9 or later.
