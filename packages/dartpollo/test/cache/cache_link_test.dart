import 'package:dartpollo/cache/cache_context.dart';
import 'package:dartpollo/cache/cache_entry.dart';
import 'package:dartpollo/cache/cache_link.dart';
import 'package:dartpollo/cache/cache_policy.dart';
import 'package:dartpollo/cache/in_memory_cache_store.dart';
import 'package:gql/language.dart';
import 'package:gql_exec/gql_exec.dart';
import 'package:gql_link/gql_link.dart';
import 'package:test/test.dart';

Request _makeRequest({
  String query = 'query Test { test }',
  String? operationName = 'Test',
  Map<String, dynamic> variables = const {},
  Context context = const Context(),
}) {
  return Request(
    operation: Operation(
      document: parseString(query),
      operationName: operationName,
    ),
    variables: variables,
    context: context,
  );
}

NextLink _mockForward(Map<String, dynamic> data) {
  return (Request request) => Stream.value(
    Response(data: data, response: const {}, context: request.context),
  );
}

NextLink _errorForward(Object error) {
  return (Request request) => Stream.error(error);
}

void main() {
  group('CacheLink', () {
    late InMemoryCacheStore store;
    late CacheLink cacheLink;

    setUp(() {
      store = InMemoryCacheStore();
      cacheLink = CacheLink(
        store: store,
        defaultTtl: const Duration(minutes: 5),
      );
    });

    group('constructor', () {
      test('uses InMemoryCacheStore by default', () {
        final link = CacheLink();
        expect(link.store, isA<InMemoryCacheStore>());
      });

      test('uses provided store', () {
        expect(cacheLink.store, same(store));
      });

      test('defaults to cacheFirst policy', () {
        final link = CacheLink();
        expect(link.defaultPolicy, CachePolicy.cacheFirst);
      });
    });

    group('generateCacheKey', () {
      test('produces deterministic key for same request', () {
        final request = _makeRequest();
        final key1 = cacheLink.generateCacheKey(request);
        final key2 = cacheLink.generateCacheKey(request);

        expect(key1, equals(key2));
      });

      test('produces different keys for different variables', () {
        final request1 = _makeRequest(variables: {'id': '1'});
        final request2 = _makeRequest(variables: {'id': '2'});

        expect(
          cacheLink.generateCacheKey(request1),
          isNot(equals(cacheLink.generateCacheKey(request2))),
        );
      });

      test('produces different keys for different operations', () {
        final request1 = _makeRequest(
          query: 'query A { a }',
          operationName: 'A',
        );
        final request2 = _makeRequest(
          query: 'query B { b }',
          operationName: 'B',
        );

        expect(
          cacheLink.generateCacheKey(request1),
          isNot(equals(cacheLink.generateCacheKey(request2))),
        );
      });
    });

    group('cacheFirst policy', () {
      test('returns cached data when available', () async {
        final request = _makeRequest();
        final cacheKey = cacheLink.generateCacheKey(request);

        store.set(
          cacheKey,
          CacheEntry(
            data: {'cached': true},
            timestamp: DateTime.now(),
          ),
        );

        final responses = await cacheLink
            .request(request, _mockForward({'network': true}))
            .toList();

        expect(responses, hasLength(1));
        expect(responses.first.data, {'cached': true});
      });

      test('fetches from network when cache miss', () async {
        final request = _makeRequest();

        final responses = await cacheLink
            .request(request, _mockForward({'network': true}))
            .toList();

        expect(responses, hasLength(1));
        expect(responses.first.data, {'network': true});
      });

      test('stores network response in cache', () async {
        final request = _makeRequest();
        final cacheKey = cacheLink.generateCacheKey(request);

        await cacheLink
            .request(request, _mockForward({'network': true}))
            .toList();

        expect(store.get(cacheKey), isNotNull);
        expect(store.get(cacheKey)!.data, {'network': true});
      });
    });

    group('networkFirst policy', () {
      late CacheLink networkFirstLink;

      setUp(() {
        networkFirstLink = CacheLink(
          store: store,
          defaultPolicy: CachePolicy.networkFirst,
        );
      });

      test('returns network data when available', () async {
        final request = _makeRequest();

        final responses = await networkFirstLink
            .request(request, _mockForward({'network': true}))
            .toList();

        expect(responses, hasLength(1));
        expect(responses.first.data, {'network': true});
      });

      test('falls back to cache on network error', () async {
        final request = _makeRequest();
        final cacheKey = networkFirstLink.generateCacheKey(request);

        store.set(
          cacheKey,
          CacheEntry(
            data: {'cached': true},
            timestamp: DateTime.now(),
          ),
        );

        final responses = await networkFirstLink
            .request(request, _errorForward(Exception('Network error')))
            .toList();

        expect(responses, hasLength(1));
        expect(responses.first.data, {'cached': true});
      });

      test('rethrows error when no cache available', () {
        final request = _makeRequest();

        expect(
          () => networkFirstLink
              .request(request, _errorForward(Exception('Network error')))
              .toList(),
          throwsException,
        );
      });

      test('falls back to cache when forward is null', () async {
        final request = _makeRequest();
        final cacheKey = networkFirstLink.generateCacheKey(request);

        store.set(
          cacheKey,
          CacheEntry(
            data: {'cached': true},
            timestamp: DateTime.now(),
          ),
        );

        final responses = await networkFirstLink.request(request).toList();

        expect(responses, hasLength(1));
        expect(responses.first.data, {'cached': true});
      });
    });

    group('cacheOnly policy', () {
      late CacheLink cacheOnlyLink;

      setUp(() {
        cacheOnlyLink = CacheLink(
          store: store,
          defaultPolicy: CachePolicy.cacheOnly,
        );
      });

      test('returns cached data', () async {
        final request = _makeRequest();
        final cacheKey = cacheOnlyLink.generateCacheKey(request);

        store.set(
          cacheKey,
          CacheEntry(
            data: {'cached': true},
            timestamp: DateTime.now(),
          ),
        );

        final responses = await cacheOnlyLink.request(request).toList();

        expect(responses, hasLength(1));
        expect(responses.first.data, {'cached': true});
      });

      test('returns empty stream when no cache', () async {
        final request = _makeRequest();

        final responses = await cacheOnlyLink.request(request).toList();

        expect(responses, isEmpty);
      });
    });

    group('networkOnly policy', () {
      late CacheLink networkOnlyLink;

      setUp(() {
        networkOnlyLink = CacheLink(
          store: store,
          defaultPolicy: CachePolicy.networkOnly,
        );
      });

      test('always fetches from network', () async {
        final request = _makeRequest();
        final cacheKey = networkOnlyLink.generateCacheKey(request);

        // Pre-populate cache
        store.set(
          cacheKey,
          CacheEntry(
            data: {'cached': true},
            timestamp: DateTime.now(),
          ),
        );

        final responses = await networkOnlyLink
            .request(request, _mockForward({'network': true}))
            .toList();

        expect(responses, hasLength(1));
        expect(responses.first.data, {'network': true});
      });

      test('updates cache with network response', () async {
        final request = _makeRequest();
        final cacheKey = networkOnlyLink.generateCacheKey(request);

        await networkOnlyLink
            .request(request, _mockForward({'fresh': true}))
            .toList();

        expect(store.get(cacheKey)!.data, {'fresh': true});
      });
    });

    group('cacheAndNetwork policy', () {
      late CacheLink cacheAndNetworkLink;

      setUp(() {
        cacheAndNetworkLink = CacheLink(
          store: store,
          defaultPolicy: CachePolicy.cacheAndNetwork,
        );
      });

      test('yields cached then network data', () async {
        final request = _makeRequest();
        final cacheKey = cacheAndNetworkLink.generateCacheKey(request);

        store.set(
          cacheKey,
          CacheEntry(
            data: {'cached': true},
            timestamp: DateTime.now(),
          ),
        );

        final responses = await cacheAndNetworkLink
            .request(request, _mockForward({'network': true}))
            .toList();

        expect(responses, hasLength(2));
        expect(responses[0].data, {'cached': true});
        expect(responses[1].data, {'network': true});
      });

      test('yields only network data when no cache', () async {
        final request = _makeRequest();

        final responses = await cacheAndNetworkLink
            .request(request, _mockForward({'network': true}))
            .toList();

        expect(responses, hasLength(1));
        expect(responses.first.data, {'network': true});
      });
    });

    group('context overrides', () {
      test('respects per-request cache policy override', () async {
        // Default is cacheFirst, but override to networkOnly
        final request = _makeRequest(
          context: const Context().withCachePolicy(CachePolicy.networkOnly),
        );
        final cacheKey = cacheLink.generateCacheKey(request);

        store.set(
          cacheKey,
          CacheEntry(
            data: {'cached': true},
            timestamp: DateTime.now(),
          ),
        );

        final responses = await cacheLink
            .request(request, _mockForward({'network': true}))
            .toList();

        // networkOnly ignores cache
        expect(responses.first.data, {'network': true});
      });

      test('respects per-request TTL override', () async {
        final request = _makeRequest(
          context: const Context().withCacheTtl(const Duration(hours: 1)),
        );
        final cacheKey = cacheLink.generateCacheKey(request);

        await cacheLink.request(request, _mockForward({'data': true})).toList();

        final entry = store.get(cacheKey)!;
        expect(entry.ttl, const Duration(hours: 1));
      });
    });

    group('direct cache management', () {
      test('read returns cache entry', () {
        cacheLink.write('key', {'data': true});
        final entry = cacheLink.read('key');

        expect(entry, isNotNull);
        expect(entry!.data, {'data': true});
      });

      test('read returns null for missing key', () {
        expect(cacheLink.read('missing'), isNull);
      });

      test('write stores data with ttl', () {
        cacheLink.write('key', {
          'data': true,
        }, ttl: const Duration(minutes: 10));
        final entry = cacheLink.read('key');

        expect(entry!.ttl, const Duration(minutes: 10));
      });

      test('evict removes entry', () {
        cacheLink
          ..write('key', {'data': true})
          ..evict('key');

        expect(cacheLink.read('key'), isNull);
      });

      test('clear removes all entries', () {
        cacheLink
          ..write('key1', {'a': 1})
          ..write('key2', {'b': 2})
          ..clear();

        expect(store.size, 0);
      });

      test('getStats returns statistics', () {
        cacheLink.write('key', {'data': true});
        final stats = cacheLink.getStats();

        expect(stats['size'], 1);
        expect(stats['defaultPolicy'], contains('cacheFirst'));
        expect(stats['defaultTtl'], '0:05:00.000000');
      });
    });
  });
}
