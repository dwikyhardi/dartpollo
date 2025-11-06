import 'package:dartpollo/cache/cache_entry.dart';
import 'package:test/test.dart';

void main() {
  group('CacheEntry', () {
    test('creates entry with required fields', () {
      final now = DateTime.now();
      final entry = CacheEntry(
        data: {'key': 'value'},
        timestamp: now,
      );

      expect(entry.data, {'key': 'value'});
      expect(entry.timestamp, now);
      expect(entry.ttl, isNull);
    });

    test('creates entry with TTL', () {
      final now = DateTime.now();
      const ttl = Duration(minutes: 5);
      final entry = CacheEntry(
        data: {'key': 'value'},
        timestamp: now,
        ttl: ttl,
      );

      expect(entry.ttl, ttl);
    });

    group('isExpired', () {
      test('returns false when no TTL is set', () {
        final entry = CacheEntry(
          data: {'key': 'value'},
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        );

        expect(entry.isExpired, isFalse);
      });

      test('returns false when TTL has not elapsed', () {
        final entry = CacheEntry(
          data: {'key': 'value'},
          timestamp: DateTime.now(),
          ttl: const Duration(minutes: 5),
        );

        expect(entry.isExpired, isFalse);
      });

      test('returns true when TTL has elapsed', () {
        final entry = CacheEntry(
          data: {'key': 'value'},
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          ttl: const Duration(minutes: 5),
        );

        expect(entry.isExpired, isTrue);
      });

      test('returns true when TTL exactly elapsed', () {
        final entry = CacheEntry(
          data: {'key': 'value'},
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          ttl: const Duration(minutes: 5),
        );

        // Should be expired (or very close to it)
        expect(entry.isExpired, isTrue);
      });
    });

    group('JSON serialization', () {
      test('toJson converts entry to map', () {
        final now = DateTime.now();
        final entry = CacheEntry(
          data: {'user': 'John', 'age': 30},
          timestamp: now,
          ttl: const Duration(minutes: 5),
        );

        final json = entry.toJson();

        expect(json['data'], {'user': 'John', 'age': 30});
        expect(json['timestamp'], now.toIso8601String());
        expect(json['ttl'], const Duration(minutes: 5).inMilliseconds);
      });

      test('toJson handles null TTL', () {
        final now = DateTime.now();
        final entry = CacheEntry(
          data: {'key': 'value'},
          timestamp: now,
        );

        final json = entry.toJson();

        expect(json['ttl'], isNull);
      });

      test('fromJson creates entry from map', () {
        final now = DateTime.now();
        final json = {
          'data': {'user': 'John', 'age': 30},
          'timestamp': now.toIso8601String(),
          'ttl': const Duration(minutes: 5).inMilliseconds,
        };

        final entry = CacheEntry.fromJson(json);

        expect(entry.data, {'user': 'John', 'age': 30});
        expect(entry.timestamp.toIso8601String(), now.toIso8601String());
        expect(entry.ttl, const Duration(minutes: 5));
      });

      test('fromJson handles null TTL', () {
        final now = DateTime.now();
        final json = {
          'data': {'key': 'value'},
          'timestamp': now.toIso8601String(),
          'ttl': null,
        };

        final entry = CacheEntry.fromJson(json);

        expect(entry.ttl, isNull);
      });

      test('roundtrip serialization preserves data', () {
        final original = CacheEntry(
          data: {
            'nested': {'key': 'value'},
            'list': [1, 2, 3],
          },
          timestamp: DateTime.now(),
          ttl: const Duration(hours: 1),
        );

        final json = original.toJson();
        final restored = CacheEntry.fromJson(json);

        expect(restored.data, original.data);
        expect(
          restored.timestamp.toIso8601String(),
          original.timestamp.toIso8601String(),
        );
        expect(restored.ttl, original.ttl);
      });
    });

    group('copyWith', () {
      test('creates copy with updated data', () {
        final original = CacheEntry(
          data: {'key': 'value'},
          timestamp: DateTime.now(),
          ttl: const Duration(minutes: 5),
        );

        final copy = original.copyWith(data: {'new': 'data'});

        expect(copy.data, {'new': 'data'});
        expect(copy.timestamp, original.timestamp);
        expect(copy.ttl, original.ttl);
      });

      test('creates copy with updated timestamp', () {
        final original = CacheEntry(
          data: {'key': 'value'},
          timestamp: DateTime.now(),
          ttl: const Duration(minutes: 5),
        );

        final newTimestamp = DateTime.now().add(const Duration(hours: 1));
        final copy = original.copyWith(timestamp: newTimestamp);

        expect(copy.data, original.data);
        expect(copy.timestamp, newTimestamp);
        expect(copy.ttl, original.ttl);
      });

      test('creates copy with updated TTL', () {
        final original = CacheEntry(
          data: {'key': 'value'},
          timestamp: DateTime.now(),
          ttl: const Duration(minutes: 5),
        );

        const newTtl = Duration(hours: 1);
        final copy = original.copyWith(ttl: newTtl);

        expect(copy.data, original.data);
        expect(copy.timestamp, original.timestamp);
        expect(copy.ttl, newTtl);
      });

      test('creates copy with no changes when no parameters provided', () {
        final original = CacheEntry(
          data: {'key': 'value'},
          timestamp: DateTime.now(),
          ttl: const Duration(minutes: 5),
        );

        final copy = original.copyWith();

        expect(copy.data, original.data);
        expect(copy.timestamp, original.timestamp);
        expect(copy.ttl, original.ttl);
      });
    });

    group('equality', () {
      test('entries with same data are equal', () {
        final now = DateTime.now();
        final entry1 = CacheEntry(
          data: {'key': 'value'},
          timestamp: now,
          ttl: const Duration(minutes: 5),
        );
        final entry2 = CacheEntry(
          data: {'key': 'value'},
          timestamp: now,
          ttl: const Duration(minutes: 5),
        );

        expect(entry1, equals(entry2));
        expect(entry1.hashCode, equals(entry2.hashCode));
      });

      test('entries with different data are not equal', () {
        final now = DateTime.now();
        final entry1 = CacheEntry(
          data: {'key': 'value1'},
          timestamp: now,
        );
        final entry2 = CacheEntry(
          data: {'key': 'value2'},
          timestamp: now,
        );

        expect(entry1, isNot(equals(entry2)));
      });

      test('entries with different timestamps are not equal', () {
        final entry1 = CacheEntry(
          data: {'key': 'value'},
          timestamp: DateTime.now(),
        );
        final entry2 = CacheEntry(
          data: {'key': 'value'},
          timestamp: DateTime.now().add(const Duration(seconds: 1)),
        );

        expect(entry1, isNot(equals(entry2)));
      });

      test('entries with different TTL are not equal', () {
        final now = DateTime.now();
        final entry1 = CacheEntry(
          data: {'key': 'value'},
          timestamp: now,
          ttl: const Duration(minutes: 5),
        );
        final entry2 = CacheEntry(
          data: {'key': 'value'},
          timestamp: now,
          ttl: const Duration(minutes: 10),
        );

        expect(entry1, isNot(equals(entry2)));
      });
    });

    test('toString includes relevant information', () {
      final entry = CacheEntry(
        data: {'user': 'John', 'age': 30},
        timestamp: DateTime.now(),
        ttl: const Duration(minutes: 5),
      );

      final str = entry.toString();

      expect(str, contains('CacheEntry'));
      expect(str, contains('timestamp'));
      expect(str, contains('ttl'));
      expect(str, contains('expired'));
      expect(str, contains('user'));
      expect(str, contains('age'));
    });
  });
}
