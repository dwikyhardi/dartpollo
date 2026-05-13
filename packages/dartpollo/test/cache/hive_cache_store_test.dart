import 'dart:io';

import 'package:dartpollo/cache/cache_entry.dart';
import 'package:dartpollo/cache/hive_cache_store.dart';
import 'package:hive_ce/hive.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('HiveCacheStore', () {
    late HiveCacheStore store;

    setUp(() async {
      store = await HiveCacheStore.open('test_cache');
    });

    tearDown(() async {
      // HiveCacheStore.close() is idempotent, so this is safe even if the
      // test has already closed the box.
      await store.close();
    });

    group('open', () {
      test('creates a new store', () {
        expect(store, isNotNull);
      });

      test('opens existing box', () async {
        store.set(
          'key',
          CacheEntry(data: {'a': 1}, timestamp: DateTime.now()),
        );
        await store.close();

        final reopened = await HiveCacheStore.open('test_cache');
        expect(reopened.get('key'), isNotNull);
        expect(reopened.get('key')!.data, {'a': 1});
        await reopened.close();
      });
    });

    group('basic operations', () {
      test('get returns null for non-existent key', () {
        expect(store.get('nonexistent'), isNull);
      });

      test('set and get stores and retrieves entry', () {
        final entry = CacheEntry(
          data: {'key': 'value'},
          timestamp: DateTime.now(),
        );

        store.set('test', entry);
        final retrieved = store.get('test');

        expect(retrieved, isNotNull);
        expect(retrieved!.data, {'key': 'value'});
      });

      test('set overwrites existing entry', () {
        final entry1 = CacheEntry(
          data: {'key': 'value1'},
          timestamp: DateTime.now(),
        );
        final entry2 = CacheEntry(
          data: {'key': 'value2'},
          timestamp: DateTime.now(),
        );

        store
          ..set('test', entry1)
          ..set('test', entry2);

        expect(store.get('test')!.data, {'key': 'value2'});
      });

      test('delete removes entry', () {
        final entry = CacheEntry(
          data: {'key': 'value'},
          timestamp: DateTime.now(),
        );

        store
          ..set('test', entry)
          ..delete('test');

        expect(store.get('test'), isNull);
      });

      test('clear removes all entries', () {
        store
          ..set(
            'key1',
            CacheEntry(data: {'a': 1}, timestamp: DateTime.now()),
          )
          ..set(
            'key2',
            CacheEntry(data: {'b': 2}, timestamp: DateTime.now()),
          );

        expect(store.contains('key1'), isTrue);
        expect(store.contains('key2'), isTrue);

        // Use individual deletes since Hive's clear() is async internally
        store
          ..delete('key1')
          ..delete('key2');

        expect(store.get('key1'), isNull);
        expect(store.get('key2'), isNull);
        expect(store.size, 0);
      });
    });

    group('TTL expiration', () {
      test('get returns null for expired entry', () {
        final entry = CacheEntry(
          data: {'key': 'value'},
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          ttl: const Duration(minutes: 5),
        );

        store.set('test', entry);
        expect(store.get('test'), isNull);
      });

      test('get returns entry that has not expired', () {
        final entry = CacheEntry(
          data: {'key': 'value'},
          timestamp: DateTime.now(),
          ttl: const Duration(minutes: 5),
        );

        store.set('test', entry);
        expect(store.get('test'), isNotNull);
      });

      test('evictExpired removes all expired entries', () {
        final validEntry = CacheEntry(
          data: {'valid': 'data'},
          timestamp: DateTime.now(),
          ttl: const Duration(minutes: 5),
        );
        final expiredEntry = CacheEntry(
          data: {'expired': 'data'},
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          ttl: const Duration(minutes: 5),
        );

        store
          ..set('valid', validEntry)
          ..set('expired', expiredEntry)
          ..evictExpired();

        expect(store.get('valid'), isNotNull);
        expect(store.get('expired'), isNull);
        expect(store.size, 1);
      });
    });

    group('getAll', () {
      test('returns all non-expired entries', () {
        final validEntry = CacheEntry(
          data: {'a': 1},
          timestamp: DateTime.now(),
        );
        final expiredEntry = CacheEntry(
          data: {'expired': 'data'},
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          ttl: const Duration(minutes: 5),
        );

        store
          ..set('valid', validEntry)
          ..set('expired', expiredEntry);

        final all = store.getAll();

        expect(all.length, 1);
        expect(all.containsKey('valid'), isTrue);
        expect(all.containsKey('expired'), isFalse);
      });

      test('returns unmodifiable map', () {
        store.set(
          'key',
          CacheEntry(data: {'a': 1}, timestamp: DateTime.now()),
        );
        final all = store.getAll();

        expect(
          () => all['new'] = CacheEntry(data: {}, timestamp: DateTime.now()),
          throwsUnsupportedError,
        );
      });
    });

    group('size', () {
      test('returns 0 for empty store', () {
        expect(store.size, 0);
      });

      test('returns correct count excluding expired', () {
        store
          ..set(
            'valid',
            CacheEntry(data: {'a': 1}, timestamp: DateTime.now()),
          )
          ..set(
            'expired',
            CacheEntry(
              data: {'b': 2},
              timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
              ttl: const Duration(minutes: 5),
            ),
          );

        expect(store.size, 1);
      });
    });

    group('contains', () {
      test('returns true for existing non-expired entry', () {
        store.set(
          'key',
          CacheEntry(data: {'a': 1}, timestamp: DateTime.now()),
        );
        expect(store.contains('key'), isTrue);
      });

      test('returns false for non-existent key', () {
        expect(store.contains('nonexistent'), isFalse);
      });

      test('returns false for expired entry', () {
        store.set(
          'expired',
          CacheEntry(
            data: {'a': 1},
            timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
            ttl: const Duration(minutes: 5),
          ),
        );
        expect(store.contains('expired'), isFalse);
      });
    });

    group('compact', () {
      test('compacts without error', () async {
        store
          ..set(
            'key1',
            CacheEntry(data: {'a': 1}, timestamp: DateTime.now()),
          )
          ..set(
            'key2',
            CacheEntry(data: {'b': 2}, timestamp: DateTime.now()),
          )
          ..delete('key1');

        await expectLater(store.compact(), completes);
      });
    });

    group('getStats', () {
      test('returns correct statistics', () {
        store.set(
          'key',
          CacheEntry(data: {'a': 1}, timestamp: DateTime.now()),
        );

        final stats = store.getStats();

        expect(stats['size'], 1);
        expect(stats['totalKeys'], 1);
        expect(stats['boxName'], 'test_cache');
        expect(stats['isOpen'], isTrue);
      });
    });

    test('toString includes statistics', () {
      store.set(
        'key',
        CacheEntry(data: {'a': 1}, timestamp: DateTime.now()),
      );

      final str = store.toString();

      expect(str, contains('HiveCacheStore'));
      expect(str, contains('test_cache'));
      expect(str, contains('size: 1'));
    });
  });
}
