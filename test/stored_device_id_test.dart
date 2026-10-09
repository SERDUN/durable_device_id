import 'package:flutter_test/flutter_test.dart';

import 'package:durable_device_id/src/stored_device_id.dart';

class _MemoryStorage implements DeviceIdStorage {
  _MemoryStorage([this.value]);

  String? value;
  int writes = 0;

  @override
  String? read() => value;

  @override
  void write(String id) {
    writes++;
    value = id;
  }
}

class _DroppingStorage implements DeviceIdStorage {
  @override
  String? read() => null;

  @override
  void write(String id) {}
}

class _OverwrittenStorage extends _MemoryStorage {
  @override
  void write(String id) {
    super.write(id);
    value = 'written-by-another-tab';
  }
}

class _FailingStorage implements DeviceIdStorage {
  _FailingStorage({this.onRead = false, this.onWrite = false});

  final bool onRead;
  final bool onWrite;

  @override
  String? read() => onRead ? throw StateError('storage is disabled') : null;

  @override
  void write(String id) {
    if (onWrite) throw StateError('quota exceeded');
  }
}

void main() {
  group('storedDeviceId', () {
    test('returns the identifier already kept and writes nothing', () {
      final storage = _MemoryStorage('kept');

      expect(storedDeviceId(storage, generate: () => 'new'), 'kept');
      expect(storage.writes, 0);
    });

    test('creates one on the first call and keeps it', () {
      final storage = _MemoryStorage();

      expect(storedDeviceId(storage, generate: () => 'new'), 'new');
      expect(storage.value, 'new');
    });

    test('gives the same identifier on every later call', () {
      final storage = _MemoryStorage();
      var generated = 0;
      String generate() => 'id-${++generated}';

      final first = storedDeviceId(storage, generate: generate);

      expect(storedDeviceId(storage, generate: generate), first);
      expect(storedDeviceId(storage, generate: generate), first);
      expect(generated, 1);
    });

    test('replaces an empty value', () {
      final storage = _MemoryStorage('');

      expect(storedDeviceId(storage, generate: () => 'new'), 'new');
    });

    test(
      'returns what the storage holds when another writer got there first',
      () {
        expect(
          storedDeviceId(_OverwrittenStorage(), generate: () => 'new'),
          'written-by-another-tab',
        );
      },
    );

    test('returns null when the storage does not keep what was written', () {
      expect(storedDeviceId(_DroppingStorage(), generate: () => 'new'), isNull);
    });

    test('returns null when the storage cannot be read', () {
      expect(storedDeviceId(_FailingStorage(onRead: true)), isNull);
    });

    test('returns null when the storage cannot be written', () {
      expect(storedDeviceId(_FailingStorage(onWrite: true)), isNull);
    });
  });

  group('storageKey', () {
    test('carries the path the app is served from', () {
      expect(storageKey('https://example.com/'), 'durable_device_id:/');
      expect(
        storageKey('https://example.com/admin/'),
        'durable_device_id:/admin/',
      );
    });

    test('differs for two apps on one origin', () {
      expect(
        storageKey('https://example.com/admin/'),
        isNot(storageKey('https://example.com/client/')),
      );
    });

    test('ignores the query and the fragment', () {
      expect(
        storageKey('https://example.com/app/?a=1#/home'),
        'durable_device_id:/app/',
      );
    });

    test('falls back to the root for a base it cannot read', () {
      expect(storageKey(''), 'durable_device_id:/');
    });
  });

  group('randomUuid', () {
    final uuidV4 = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    test('is a lowercase version 4 UUID', () {
      for (var i = 0; i < 200; i++) {
        expect(randomUuid(), matches(uuidV4));
      }
    });

    test('differs between calls', () {
      expect({for (var i = 0; i < 200; i++) randomUuid()}, hasLength(200));
    });
  });
}
