import 'package:dartpollo/cache/cache_link.dart';
import 'package:dartpollo/cache/in_memory_cache_store.dart';
import 'package:dartpollo/cached_client.dart';
import 'package:dartpollo_annotation/schema/graphql_response.dart';
import 'package:gql_link/gql_link.dart';
import 'package:test/test.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('DartpolloCachedClient', () {
    late InMemoryCacheStore store;
    late CacheLink cacheLink;
    late DartpolloCachedClient client;

    setUp(() {
      store = InMemoryCacheStore();
      cacheLink = CacheLink(
        store: store,
        defaultTtl: const Duration(minutes: 5),
      );
      final mockLink = MockLink({'hello': 'world'});
      final link = Link.from([cacheLink, mockLink]);
      client = DartpolloCachedClient.fromLink(link, cacheLink: cacheLink);
    });

    group('fromLink constructor', () {
      test('creates client', () {
        expect(client, isNotNull);
      });
    });

    group('execute', () {
      test('returns parsed response', () async {
        final response = await client.execute(SimpleQuery());

        expect(response, isA<GraphQLResponse<Map<String, dynamic>>>());
        expect(response.data, {'hello': 'world'});
      });

      test('caches response after execute', () async {
        await client.execute(SimpleQuery());

        expect(store.size, 1);
      });

      test('returns cached response on second call', () async {
        await client.execute(SimpleQuery());
        final response = await client.execute(SimpleQuery());

        expect(response.data, {'hello': 'world'});
      });
    });

    group('stream', () {
      test('returns stream of responses', () async {
        final responses = await client.stream(SimpleQuery()).toList();

        expect(responses, isNotEmpty);
        expect(responses.first.data, {'hello': 'world'});
      });
    });

    group('readCache', () {
      test('returns null when not cached', () async {
        final result = await client.readCache(SimpleQuery());
        expect(result, isNull);
      });

      test('returns cached data after execute', () async {
        await client.execute(SimpleQuery());

        final result = await client.readCache(SimpleQuery());
        expect(result, {'hello': 'world'});
      });
    });

    group('writeCache', () {
      test('writes data to cache', () async {
        await client.writeCache(SimpleQuery(), {'custom': 'data'});

        final result = await client.readCache(SimpleQuery());
        expect(result, {'custom': 'data'});
      });

      test('writes data with TTL', () async {
        await client.writeCache(
          SimpleQuery(),
          {'custom': 'data'},
          ttl: const Duration(minutes: 10),
        );

        expect(store.size, 1);
      });
    });

    group('evictCache', () {
      test('removes cached data for query', () async {
        await client.execute(SimpleQuery());
        expect(store.size, 1);

        await client.evictCache(SimpleQuery());
        expect(store.size, 0);
      });
    });

    group('clearCache', () {
      test('removes all cached data', () async {
        await client.execute(SimpleQuery());
        await client.execute(TestQueryWithVars(const {'id': '1'}));

        expect(store.size, 2);

        await client.clearCache();
        expect(store.size, 0);
      });
    });

    group('getCacheStats', () {
      test('returns statistics', () {
        final stats = client.getCacheStats();

        expect(stats['size'], 0);
        expect(stats['defaultPolicy'], contains('cacheFirst'));
        expect(stats['defaultTtl'], '0:05:00.000000');
      });

      test('reflects cache size after operations', () async {
        await client.execute(SimpleQuery());

        final stats = client.getCacheStats();
        expect(stats['size'], 1);
      });
    });

    group('cacheStore', () {
      test('returns the underlying cache store', () {
        expect(client.cacheStore, same(store));
      });
    });

    group('dispose', () {
      test('dispose on fromLink client does not throw', () {
        expect(() => client.dispose(), returnsNormally);
      });
    });
  });
}
