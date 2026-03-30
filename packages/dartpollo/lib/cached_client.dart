import 'dart:async';

import 'package:dartpollo_annotation/schema/graphql_query.dart';
import 'package:dartpollo_annotation/schema/graphql_response.dart';
import 'package:gql_dedupe_link/gql_dedupe_link.dart';
import 'package:gql_exec/gql_exec.dart';
import 'package:gql_http_link/gql_http_link.dart';
import 'package:gql_link/gql_link.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';

import 'cache/cache_link.dart';
import 'cache/cache_policy.dart';
import 'cache/cache_store.dart';
import 'cache/in_memory_cache_store.dart';

/// A GraphQL client with built-in response caching capabilities.
///
/// [DartpolloCachedClient] extends the functionality of [DartpolloClient]
/// by adding a caching layer that can significantly improve performance
/// and reduce network requests.
///
/// Features:
/// - Multiple cache policies (cacheFirst, networkFirst, cacheOnly, networkOnly, cacheAndNetwork)
/// - Configurable TTL (Time To Live) for cache entries
/// - Pluggable storage backends (in-memory, Hive, etc.)
/// - Per-request cache policy overrides
/// - Direct cache access methods
///
/// Example:
/// ```dart
/// final client = DartpolloCachedClient(
///   'https://api.example.com/graphql',
///   cacheStore: InMemoryCacheStore(maxSize: 100),
///   defaultCachePolicy: CachePolicy.cacheFirst,
///   defaultCacheTtl: Duration(minutes: 5),
/// );
///
/// // Execute query with default cache policy
/// final response = await client.execute(GetUserQuery(variables: GetUserArguments(id: '123')));
///
/// // Override cache policy for specific request
/// final freshResponse = await client.execute(
///   GetUserQuery(variables: GetUserArguments(id: '123')),
///   context: Context().withCachePolicy(CachePolicy.networkOnly),
/// );
/// ```
class DartpolloCachedClient {
  /// Creates a cached GraphQL client.
  ///
  /// [graphQLEndpoint] is the GraphQL API endpoint URL.
  /// [httpClient] is an optional custom HTTP client.
  /// [cacheStore] is the cache storage backend. Defaults to [InMemoryCacheStore].
  /// [defaultCachePolicy] is the default caching strategy. Defaults to [CachePolicy.cacheFirst].
  /// [defaultCacheTtl] is the default time-to-live for cached entries.
  factory DartpolloCachedClient(
    String graphQLEndpoint, {
    http.Client? httpClient,
    CacheStore? cacheStore,
    CachePolicy defaultCachePolicy = CachePolicy.cacheFirst,
    Duration? defaultCacheTtl,
  }) {
    final httpLink = HttpLink(
      graphQLEndpoint,
      httpClient: httpClient,
    );

    final cacheLink = CacheLink(
      store: cacheStore ?? InMemoryCacheStore(),
      defaultPolicy: defaultCachePolicy,
      defaultTtl: defaultCacheTtl,
    );

    final link = Link.from([
      DedupeLink(),
      cacheLink,
      httpLink,
    ]);

    return DartpolloCachedClient.fromLink(
      link,
      cacheLink: cacheLink,
      httpLink: httpLink,
    );
  }

  /// Creates a cached client from a custom [Link].
  ///
  /// This constructor is useful when you need full control over the link chain.
  /// You must provide the [cacheLink] separately for cache management methods to work.
  DartpolloCachedClient.fromLink(
    this._link, {
    required CacheLink cacheLink,
    HttpLink? httpLink,
  }) : _cacheLink = cacheLink,
       _httpLink = httpLink;

  final Link _link;
  final CacheLink _cacheLink;
  final HttpLink? _httpLink;

  /// Executes a [GraphQLQuery], returning a typed response.
  ///
  /// The cache policy can be overridden per-request using the [context] parameter:
  /// ```dart
  /// final response = await client.execute(
  ///   query,
  ///   context: Context().withCachePolicy(CachePolicy.networkOnly),
  /// );
  /// ```
  Future<GraphQLResponse<T>> execute<T, U extends JsonSerializable>(
    GraphQLQuery<T, U> query, {
    Context context = const Context(),
  }) async {
    final request = Request(
      operation: Operation(
        document: query.document,
        operationName: query.operationName,
      ),
      variables: query.getVariablesMap(),
      context: context,
    );

    final response = await _link.request(request).first;

    return GraphQLResponse<T>(
      data: response.data == null ? null : query.parse(response.data ?? {}),
      errors: response.errors,
      context: response.context,
    );
  }

  /// Streams a [GraphQLQuery], returning a typed response stream.
  ///
  /// Useful for subscriptions or when using [CachePolicy.cacheAndNetwork]
  /// which yields cached data first, then network data.
  ///
  /// Example:
  /// ```dart
  /// client.stream(
  ///   query,
  ///   context: Context().withCachePolicy(CachePolicy.cacheAndNetwork),
  /// ).listen((response) {
  ///   // First response: cached data (if available)
  ///   // Second response: fresh network data
  /// });
  /// ```
  Stream<GraphQLResponse<T>> stream<T, U extends JsonSerializable>(
    GraphQLQuery<T, U> query, {
    Context context = const Context(),
  }) {
    final request = Request(
      operation: Operation(
        document: query.document,
        operationName: query.operationName,
      ),
      variables: query.getVariablesMap(),
      context: context,
    );

    return _link
        .request(request)
        .map(
          (response) => GraphQLResponse<T>(
            data: response.data == null
                ? null
                : query.parse(response.data ?? {}),
            errors: response.errors,
            context: response.context,
          ),
        );
  }

  /// Reads cached data for a query without making a network request.
  ///
  /// Returns `null` if:
  /// - The query is not cached
  /// - The cached entry has expired
  ///
  /// Example:
  /// ```dart
  /// final cachedUser = await client.readCache(
  ///   GetUserQuery(variables: GetUserArguments(id: '123')),
  /// );
  /// if (cachedUser != null) {
  ///   print('Found in cache: $cachedUser');
  /// }
  /// ```
  Future<T?> readCache<T, U extends JsonSerializable>(
    GraphQLQuery<T, U> query,
  ) async {
    final request = Request(
      operation: Operation(
        document: query.document,
        operationName: query.operationName,
      ),
      variables: query.getVariablesMap(),
    );

    final cacheKey = _cacheLink.generateCacheKey(request);
    final cached = _cacheLink.read(cacheKey);

    return cached != null ? query.parse(cached.data) : null;
  }

  /// Writes data to the cache for a specific query.
  ///
  /// This is useful for:
  /// - Optimistic updates
  /// - Pre-populating cache
  /// - Manual cache management
  ///
  /// Example:
  /// ```dart
  /// await client.writeCache(
  ///   GetUserQuery(variables: GetUserArguments(id: '123')),
  ///   {'user': {'id': '123', 'name': 'John Doe'}},
  ///   ttl: Duration(minutes: 10),
  /// );
  /// ```
  Future<void> writeCache<T, U extends JsonSerializable>(
    GraphQLQuery<T, U> query,
    Map<String, dynamic> data, {
    Duration? ttl,
  }) async {
    final request = Request(
      operation: Operation(
        document: query.document,
        operationName: query.operationName,
      ),
      variables: query.getVariablesMap(),
    );

    final cacheKey = _cacheLink.generateCacheKey(request);
    _cacheLink.write(cacheKey, data, ttl: ttl);
  }

  /// Evicts (removes) cached data for a specific query.
  ///
  /// Use this after mutations to invalidate stale cache entries.
  ///
  /// Example:
  /// ```dart
  /// // After updating user
  /// await client.execute(UpdateUserMutation(...));
  /// await client.evictCache(GetUserQuery(variables: GetUserArguments(id: '123')));
  /// ```
  Future<void> evictCache<T, U extends JsonSerializable>(
    GraphQLQuery<T, U> query,
  ) async {
    final request = Request(
      operation: Operation(
        document: query.document,
        operationName: query.operationName,
      ),
      variables: query.getVariablesMap(),
    );

    final cacheKey = _cacheLink.generateCacheKey(request);
    _cacheLink.evict(cacheKey);
  }

  /// Clears all cached data.
  ///
  /// Use this sparingly as it removes all cache entries.
  ///
  /// Example:
  /// ```dart
  /// // On user logout
  /// await client.clearCache();
  /// ```
  Future<void> clearCache() async {
    _cacheLink.clear();
  }

  /// Returns cache statistics.
  ///
  /// Useful for monitoring and debugging cache behavior.
  ///
  /// Example:
  /// ```dart
  /// final stats = client.getCacheStats();
  /// print('Cache size: ${stats['size']}');
  /// print('Default policy: ${stats['defaultPolicy']}');
  /// ```
  Map<String, dynamic> getCacheStats() {
    return _cacheLink.getStats();
  }

  /// Accesses the underlying cache store directly.
  ///
  /// Use this for advanced cache operations not covered by the convenience methods.
  CacheStore get cacheStore => _cacheLink.store;

  /// Closes the HTTP client and releases resources.
  ///
  /// Call this when you're done with the client to prevent resource leaks.
  void dispose() {
    _httpLink?.dispose();
  }
}
