import 'package:dartpollo/cache/cache_context.dart';
import 'package:dartpollo/cache/cache_policy.dart';
import 'package:gql_exec/gql_exec.dart';
import 'package:test/test.dart';

void main() {
  group('CachePolicyEntry', () {
    test('stores policy value', () {
      const entry = CachePolicyEntry(CachePolicy.cacheFirst);
      expect(entry.policy, CachePolicy.cacheFirst);
    });

    test('equality based on policy', () {
      const entry1 = CachePolicyEntry(CachePolicy.cacheFirst);
      const entry2 = CachePolicyEntry(CachePolicy.cacheFirst);
      const entry3 = CachePolicyEntry(CachePolicy.networkOnly);

      expect(entry1, equals(entry2));
      expect(entry1, isNot(equals(entry3)));
    });
  });

  group('CacheTtlEntry', () {
    test('stores ttl value', () {
      const entry = CacheTtlEntry(Duration(minutes: 5));
      expect(entry.ttl, const Duration(minutes: 5));
    });

    test('equality based on ttl', () {
      const entry1 = CacheTtlEntry(Duration(minutes: 5));
      const entry2 = CacheTtlEntry(Duration(minutes: 5));
      const entry3 = CacheTtlEntry(Duration(minutes: 10));

      expect(entry1, equals(entry2));
      expect(entry1, isNot(equals(entry3)));
    });
  });

  group('CacheContextExtension', () {
    test('withCachePolicy adds policy to context', () {
      final context = const Context().withCachePolicy(CachePolicy.networkFirst);
      final entry = context.entry<CachePolicyEntry>();

      expect(entry, isNotNull);
      expect(entry!.policy, CachePolicy.networkFirst);
    });

    test('withCacheTtl adds ttl to context', () {
      final context = const Context().withCacheTtl(const Duration(minutes: 10));
      final entry = context.entry<CacheTtlEntry>();

      expect(entry, isNotNull);
      expect(entry!.ttl, const Duration(minutes: 10));
    });

    test('withCacheTtl with null returns same context', () {
      const original = Context();
      final result = original.withCacheTtl(null);

      expect(identical(result, original), isTrue);
    });

    test('withCache adds both policy and ttl', () {
      final context = const Context().withCache(
        policy: CachePolicy.cacheFirst,
        ttl: const Duration(minutes: 30),
      );

      final policyEntry = context.entry<CachePolicyEntry>();
      final ttlEntry = context.entry<CacheTtlEntry>();

      expect(policyEntry!.policy, CachePolicy.cacheFirst);
      expect(ttlEntry!.ttl, const Duration(minutes: 30));
    });

    test('withCache with only policy', () {
      final context = const Context().withCache(
        policy: CachePolicy.networkOnly,
      );

      expect(
        context.entry<CachePolicyEntry>()!.policy,
        CachePolicy.networkOnly,
      );
      expect(context.entry<CacheTtlEntry>(), isNull);
    });

    test('withCache with only ttl', () {
      final context = const Context().withCache(
        ttl: const Duration(hours: 1),
      );

      expect(context.entry<CachePolicyEntry>(), isNull);
      expect(context.entry<CacheTtlEntry>()!.ttl, const Duration(hours: 1));
    });

    test('withCache with neither returns same context entries', () {
      final context = const Context().withCache();

      expect(context.entry<CachePolicyEntry>(), isNull);
      expect(context.entry<CacheTtlEntry>(), isNull);
    });

    test('withoutCache sets networkOnly policy', () {
      final context = const Context().withoutCache();
      final entry = context.entry<CachePolicyEntry>();

      expect(entry!.policy, CachePolicy.networkOnly);
    });

    test('cacheOnly sets cacheOnly policy', () {
      final context = const Context().cacheOnly();
      final entry = context.entry<CachePolicyEntry>();

      expect(entry!.policy, CachePolicy.cacheOnly);
    });

    test('cacheAndNetwork sets cacheAndNetwork policy', () {
      final context = const Context().cacheAndNetwork();
      final entry = context.entry<CachePolicyEntry>();

      expect(entry!.policy, CachePolicy.cacheAndNetwork);
    });
  });
}
