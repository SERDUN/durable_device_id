import 'dart:math';

/// Where a generated identifier is kept between runs.
///
/// Both calls may throw; a storage that cannot be used is the same as none.
abstract interface class DeviceIdStorage {
  String? read();

  void write(String id);
}

/// The identifier kept in [storage], created on the first call.
///
/// Null when the storage cannot be read or does not keep what was written: an
/// identifier that would be different on the next run is not one to hand out.
String? storedDeviceId(
  DeviceIdStorage storage, {
  String Function() generate = randomUuid,
}) {
  try {
    final existing = storage.read();
    if (existing != null && existing.isNotEmpty) return existing;

    storage.write(generate());

    // Read back rather than return what was generated: a storage that drops
    // writes must not look like one that keeps them. This does not make the
    // three steps atomic - the caller serialises them where it matters.
    final kept = storage.read();
    return (kept == null || kept.isEmpty) ? null : kept;
  } catch (_) {
    return null;
  }
}

/// The storage key of the app served from [baseUri].
///
/// Local storage is shared by everything on an origin, so the path the app is
/// served from is part of the key: two apps under one domain keep two
/// identifiers.
String storageKey(String baseUri) {
  final path = Uri.tryParse(baseUri)?.path ?? '';
  return 'durable_device_id:${path.isEmpty ? '/' : path}';
}

/// A random version 4 UUID in lowercase.
String randomUuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
}
