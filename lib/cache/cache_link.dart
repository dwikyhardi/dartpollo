import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:gql_exec/gql_exec.dart';
import 'package:gql_link/gql_link.dart';

import 'cache_context.dart';
import 'cache_entry.dart';
import 'cache_policy.dart';
import 'cache_store.dart';
import 'in_memory_cache_store.dart';

/// A [Link] that provides caching capabilities for GraphQL requests.
///
/// CacheLink intercepts GraphQL requests and responses, storing them according
/// to the configured [CachePolicy]. It integrates seamlessly into the gql_link
/// chain and can be combined with other links like DedupeLink and HttpLink.
///
/// Example:
/// ```dart
/// final cacheLink = CacheLink(
///   store: InMemoryCacheStore(maxSize: 100),
///   defaultPolicy: CachePolicy.cacheFirst,
///   defaultTtl: Duration(minutes: 5),
/// );
///
/// final link = Link.from([
///   DedupeLink(),
///   cacheLink,
///   HttpLink('https://api.example.com/graphql'),
/// ]);
/// ```
class CacheLink extends Link {
  /// Creates a cache link.
  ///
  /// [store] is the cache storage backend. Defaults to [InMemoryCacheStore].
  /// [defaultPolicy] is the caching strategy to use when not specified per-request.
  /// [defaultTtl] is the default time-to-live for cached entries.
  CacheLink({
    CacheStore? store,
    this.defaultPolicy = CachePolicy.cacheFirst,
    this.defaultTtl,
  }) : store = store ?? InMemoryCacheStore();

  /// The cache storage backend.
  final CacheStore store;

  /// Default cache policy when not specified in request context.
  final CachePolicy defaultPolicy;

  /// Default TTL for cached entries when not specified in request context.
  final Duration? defaultTtl;

  @override
  Stream<Response> request(Request request, [NextLink? forward]) async* {
    final policy = _getPolicyFromContext(request.context) ?? defaultPolicy;
    final ttl = _getTtlFromContext(request.context) ?? defaultTtl;
    final cacheKey = generateCacheKey(request);

    switch (policy) {
      case CachePolicy.cacheFirst:
        yield* _cacheFirst(request, forward, cacheKey, ttl);
      case CachePolicy.networkFirst:
        yield* _networkFirst(request, forward, cacheKey, ttl);
      case CachePolicy.cacheOnly:
        yield* _cacheOnly(request, cacheKey);
      case CachePolicy.networkOnly:
        yield* _networkOnly(request, forward, cacheKey, ttl);
      case CachePolicy.cacheAndNetwork:
        yield* _cacheAndNetwork(request, forward, cacheKey, ttl);
    }
  }

  /// Generates a deterministic cache key for a request.
  ///
  /// The key is a SHA-256 hash of:
  /// - Operation name
  /// - Query document string
  /// - JSON-encoded variables
  ///
  /// This ensures that identical queries with identical variables
  /// produce the same cache key.
  String generateCacheKey(Request request) {
    final operation = request.operation;
    final queryString = operation.document.toString();
    final variables = request.variables;
    final operationName = operation.operationName ?? '';

    // Create deterministic string representation
    final keyComponents = [
      operationName,
      queryString,
      jsonEncode(variables),
    ];

    // Generate SHA-256 hash for compact, collision-resistant key
    return sha256.convert(utf8.encode(keyComponents.join('|'))).toString();
  }

  /// Cache-first policy: Return cached data if available, otherwise fetch from network.
  Stream<Response> _cacheFirst(
    Request request,
    NextLink? forward,
    String cacheKey,
    Duration? ttl,
  ) async* {
    // Try cache first
    final cached = store.get(cacheKey);
    if (cached != null) {
      yield Response(
        data: cached.data,
        response: const <String, dynamic>{'fromCache': true},
        context: request.context,
      );
      return;
    }

    // Fallback to network
    if (forward != null) {
      await for (final response in forward(request)) {
        if (response.data != null) {
          store.set(
            cacheKey,
            CacheEntry(
              data: response.data!,
              timestamp: DateTime.now(),
              ttl: ttl,
            ),
          );
        }
        yield response;
      }
    }
  }

  /// Network-first policy: Fetch from network first, fallback to cache on error.
  Stream<Response> _networkFirst(
    Request request,
    NextLink? forward,
    String cacheKey,
    Duration? ttl,
  ) async* {
    if (forward == null) {
      // No network available, try cache
      final cached = store.get(cacheKey);
      if (cached != null) {
        yield Response(
          data: cached.data,
          response: const <String, dynamic>{'fromCache': true},
          context: request.context,
        );
      }
      return;
    }

    try {
      await for (final response in forward(request)) {
        if (response.data != null) {
          store.set(
            cacheKey,
            CacheEntry(
              data: response.data!,
              timestamp: DateTime.now(),
              ttl: ttl,
            ),
          );
        }
        yield response;
      }
    } catch (e) {
      // Network error, fallback to cache
      final cached = store.get(cacheKey);
      if (cached != null) {
        yield Response(
          data: cached.data,
          response: const <String, dynamic>{'fromCache': true},
          context: request.context,
        );
      } else {
        rethrow;
      }
    }
  }

  /// Cache-only policy: Only return cached data, never fetch from network.
  Stream<Response> _cacheOnly(Request request, String cacheKey) async* {
    final cached = store.get(cacheKey);
    if (cached != null) {
      yield Response(
        data: cached.data,
        response: const <String, dynamic>{'fromCache': true},
        context: request.context,
      );
    }
  }

  /// Network-only policy: Always fetch from network, update cache.
  Stream<Response> _networkOnly(
    Request request,
    NextLink? forward,
    String cacheKey,
    Duration? ttl,
  ) async* {
    if (forward != null) {
      await for (final response in forward(request)) {
        if (response.data != null) {
          store.set(
            cacheKey,
            CacheEntry(
              data: response.data!,
              timestamp: DateTime.now(),
              ttl: ttl,
            ),
          );
        }
        yield response;
      }
    }
  }

  /// Cache-and-network policy: Return cached data immediately, then fetch and update.
  Stream<Response> _cacheAndNetwork(
    Request request,
    NextLink? forward,
    String cacheKey,
    Duration? ttl,
  ) async* {
    // Yield cached data immediately if available
    final cached = store.get(cacheKey);
    if (cached != null) {
      yield Response(
        data: cached.data,
        response: const <String, dynamic>{'fromCache': true},
        context: request.context,
      );
    }

    // Then fetch from network
    if (forward != null) {
      await for (final response in forward(request)) {
        if (response.data != null) {
          store.set(
            cacheKey,
            CacheEntry(
              data: response.data!,
              timestamp: DateTime.now(),
              ttl: ttl,
            ),
          );
        }
        yield response;
      }
    }
  }

  /// Extracts cache policy from request context.
  CachePolicy? _getPolicyFromContext(Context context) {
    final entry = context.entry<CachePolicyEntry>();
    return entry?.policy;
  }

  /// Extracts TTL from request context.
  Duration? _getTtlFromContext(Context context) {
    final entry = context.entry<CacheTtlEntry>();
    return entry?.ttl;
  }

  /// Reads a cache entry directly by key.
  CacheEntry? read(String key) => store.get(key);

  /// Writes data to cache directly.
  void write(String key, Map<String, dynamic> data, {Duration? ttl}) {
    store.set(
      key,
      CacheEntry(
        data: data,
        timestamp: DateTime.now(),
        ttl: ttl,
      ),
    );
  }

  /// Evicts a specific cache entry.
  void evict(String key) => store.delete(key);

  /// Clears all cache entries.
  void clear() => store.clear();

  /// Returns cache statistics.
  Map<String, dynamic> getStats() {
    return {
      'size': store.size,
      'defaultPolicy': defaultPolicy.toString(),
      'defaultTtl': defaultTtl?.toString() ?? 'none',
    };
  }
}
