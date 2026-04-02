import 'package:dartpollo/cache/cache_entry.dart';
import 'package:dartpollo/cache/in_memory_cache_store.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryCacheStore', () {
    late InMemoryCacheStore store;

    setUp(() {
      store = InMemoryCacheStore();
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

        final retrieved = store.get('test');
        expect(retrieved!.data, {'key': 'value2'});
      });

      test('delete removes entry', () {
        final entry = CacheEntry(
          data: {'key': 'value'},
          timestamp: DateTime.now(),
        );

        store.set('test', entry);
        expect(store.get('test'), isNotNull);

        store.delete('test');
        expect(store.get('test'), isNull);
      });

      test('delete on non-existent key does nothing', () {
        expect(() => store.delete('nonexistent'), returnsNormally);
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
          )
          ..set(
            'key3',
            CacheEntry(data: {'c': 3}, timestamp: DateTime.now()),
          );

        expect(store.size, 3);

        store.clear();

        expect(store.size, 0);
        expect(store.get('key1'), isNull);
        expect(store.get('key2'), isNull);
        expect(store.get('key3'), isNull);
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

      test('expired entries are removed from cache on get', () {
        final entry = CacheEntry(
          data: {'key': 'value'},
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          ttl: const Duration(minutes: 5),
        );

        store
          ..set('test', entry)
          ..get('test'); // Should trigger removal

        // Verify it's actually removed from internal storage
        expect(store.contains('test'), isFalse);
      });

      test('evictExpired removes all expired entries', () {
        final validEntry = CacheEntry(
          data: {'valid': 'data'},
          timestamp: DateTime.now(),
          ttl: const Duration(minutes: 5),
        );
        final expiredEntry1 = CacheEntry(
          data: {'expired': '1'},
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          ttl: const Duration(minutes: 5),
        );
        final expiredEntry2 = CacheEntry(
          data: {'expired': '2'},
          timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
          ttl: const Duration(minutes: 5),
        );

        store
          ..set('valid', validEntry)
          ..set('expired1', expiredEntry1)
          ..set('expired2', expiredEntry2)
          ..evictExpired();

        expect(store.get('valid'), isNotNull);
        expect(store.get('expired1'), isNull);
        expect(store.get('expired2'), isNull);
        expect(store.size, 1);
      });
    });

    group('LRU eviction', () {
      test('respects maxSize limit', () {
        final limitedStore = InMemoryCacheStore(maxSize: 3)
          ..set(
            'key1',
            CacheEntry(data: {'a': 1}, timestamp: DateTime.now()),
          )
          ..set(
            'key2',
            CacheEntry(data: {'b': 2}, timestamp: DateTime.now()),
          )
          ..set(
            'key3',
            CacheEntry(data: {'c': 3}, timestamp: DateTime.now()),
          );

        expect(limitedStore.size, 3);

        // Adding 4th entry should evict the oldest (key1)
        limitedStore.set(
          'key4',
          CacheEntry(data: {'d': 4}, timestamp: DateTime.now()),
        );

        expect(limitedStore.size, 3);
        expect(limitedStore.get('key1'), isNull); // Evicted
        expect(limitedStore.get('key2'), isNotNull);
        expect(limitedStore.get('key3'), isNotNull);
        expect(limitedStore.get('key4'), isNotNull);
      });

      test('get updates access order', () {
        final limitedStore = InMemoryCacheStore(maxSize: 3)
          ..set(
            'key1',
            CacheEntry(data: {'a': 1}, timestamp: DateTime.now()),
          )
          ..set(
            'key2',
            CacheEntry(data: {'b': 2}, timestamp: DateTime.now()),
          )
          ..set(
            'key3',
            CacheEntry(data: {'c': 3}, timestamp: DateTime.now()),
          )
          // Access key1 to make it most recently used
          ..get('key1')
          // Adding key4 should evict key2 (now the oldest)
          ..set(
            'key4',
            CacheEntry(data: {'d': 4}, timestamp: DateTime.now()),
          );

        expect(limitedStore.get('key1'), isNotNull); // Still present
        expect(limitedStore.get('key2'), isNull); // Evicted
        expect(limitedStore.get('key3'), isNotNull);
        expect(limitedStore.get('key4'), isNotNull);
      });

      test('set on existing key updates access order', () {
        final limitedStore = InMemoryCacheStore(maxSize: 3)
          ..set(
            'key1',
            CacheEntry(data: {'a': 1}, timestamp: DateTime.now()),
          )
          ..set(
            'key2',
            CacheEntry(data: {'b': 2}, timestamp: DateTime.now()),
          )
          ..set(
            'key3',
            CacheEntry(data: {'c': 3}, timestamp: DateTime.now()),
          )
          // Update key1 to make it most recently used
          ..set(
            'key1',
            CacheEntry(data: {'a': 'updated'}, timestamp: DateTime.now()),
          )
          // Adding key4 should evict key2 (now the oldest)
          ..set(
            'key4',
            CacheEntry(data: {'d': 4}, timestamp: DateTime.now()),
          );

        expect(limitedStore.get('key1'), isNotNull); // Still present
        expect(limitedStore.get('key2'), isNull); // Evicted
        expect(limitedStore.get('key3'), isNotNull);
        expect(limitedStore.get('key4'), isNotNull);
      });

      test('no size limit when maxSize is null', () {
        final unlimitedStore = InMemoryCacheStore();

        for (var i = 0; i < 1000; i++) {
          unlimitedStore.set(
            'key$i',
            CacheEntry(data: {'i': i}, timestamp: DateTime.now()),
          );
        }

        expect(unlimitedStore.size, 1000);
      });
    });

    group('getAll', () {
      test('returns all non-expired entries', () {
        final validEntry1 = CacheEntry(
          data: {'a': 1},
          timestamp: DateTime.now(),
        );
        final validEntry2 = CacheEntry(
          data: {'b': 2},
          timestamp: DateTime.now(),
        );
        final expiredEntry = CacheEntry(
          data: {'expired': 'data'},
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          ttl: const Duration(minutes: 5),
        );

        store
          ..set('valid1', validEntry1)
          ..set('valid2', validEntry2)
          ..set('expired', expiredEntry);

        final all = store.getAll();

        expect(all.length, 2);
        expect(all.containsKey('valid1'), isTrue);
        expect(all.containsKey('valid2'), isTrue);
        expect(all.containsKey('expired'), isFalse);
      });

      test('returns empty map when store is empty', () {
        expect(store.getAll(), isEmpty);
      });

      test('returns unmodifiable map', () {
        store.set('key', CacheEntry(data: {'a': 1}, timestamp: DateTime.now()));
        final all = store.getAll();

        expect(
          () => all['new'] = CacheEntry(data: {}, timestamp: DateTime.now()),
          throwsUnsupportedError,
        );
      });

      test('cleans up expired entries', () {
        final expiredEntry = CacheEntry(
          data: {'expired': 'data'},
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          ttl: const Duration(minutes: 5),
        );

        store
          ..set('expired', expiredEntry)
          ..getAll(); // Should trigger cleanup

        expect(store.contains('expired'), isFalse);
      });
    });

    group('size', () {
      test('returns 0 for empty store', () {
        expect(store.size, 0);
      });

      test('returns correct count of entries', () {
        store.set(
          'key1',
          CacheEntry(data: {'a': 1}, timestamp: DateTime.now()),
        );
        expect(store.size, 1);

        store.set(
          'key2',
          CacheEntry(data: {'b': 2}, timestamp: DateTime.now()),
        );
        expect(store.size, 2);

        store.set(
          'key3',
          CacheEntry(data: {'c': 3}, timestamp: DateTime.now()),
        );
        expect(store.size, 3);
      });

      test('excludes expired entries', () {
        final validEntry = CacheEntry(
          data: {'valid': 'data'},
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

        expect(store.size, 1);
      });

      test('updates after delete', () {
        store
          ..set(
            'key1',
            CacheEntry(data: {'a': 1}, timestamp: DateTime.now()),
          )
          ..set(
            'key2',
            CacheEntry(data: {'b': 2}, timestamp: DateTime.now()),
          );
        expect(store.size, 2);

        store.delete('key1');
        expect(store.size, 1);
      });
    });

    group('contains', () {
      test('returns true for existing non-expired entry', () {
        store.set('key', CacheEntry(data: {'a': 1}, timestamp: DateTime.now()));
        expect(store.contains('key'), isTrue);
      });

      test('returns false for non-existent key', () {
        expect(store.contains('nonexistent'), isFalse);
      });

      test('returns false for expired entry', () {
        final expiredEntry = CacheEntry(
          data: {'expired': 'data'},
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          ttl: const Duration(minutes: 5),
        );

        store.set('expired', expiredEntry);
        expect(store.contains('expired'), isFalse);
      });
    });

    group('getStats', () {
      test('returns correct statistics', () {
        final limitedStore = InMemoryCacheStore(maxSize: 10)
          ..set(
            'key1',
            CacheEntry(data: {'a': 1}, timestamp: DateTime.now()),
          )
          ..set(
            'key2',
            CacheEntry(data: {'b': 2}, timestamp: DateTime.now()),
          );

        final stats = limitedStore.getStats();

        expect(stats['size'], 2);
        expect(stats['maxSize'], 10);
        expect(stats['utilizationPercent'], '20.0');
        expect(stats['oldestEntry'], 'key1');
        expect(stats['newestEntry'], 'key2');
      });

      test('shows unlimited for null maxSize', () {
        store.set('key', CacheEntry(data: {'a': 1}, timestamp: DateTime.now()));
        final stats = store.getStats();

        expect(stats['utilizationPercent'], 'unlimited');
      });
    });

    test('toString includes statistics', () {
      final limitedStore = InMemoryCacheStore(maxSize: 10)
        ..set(
          'key',
          CacheEntry(data: {'a': 1}, timestamp: DateTime.now()),
        );

      final str = limitedStore.toString();

      expect(str, contains('InMemoryCacheStore'));
      expect(str, contains('size'));
      expect(str, contains('maxSize'));
      expect(str, contains('utilization'));
    });
  });
}
