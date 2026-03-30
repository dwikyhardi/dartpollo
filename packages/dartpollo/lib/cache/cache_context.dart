import 'package:gql_exec/gql_exec.dart';

import 'cache_policy.dart';

/// ContextEntry wrapper for CachePolicy.
class CachePolicyEntry extends ContextEntry {
  const CachePolicyEntry(this.policy);

  final CachePolicy policy;

  @override
  List<Object?> get fieldsForEquality => [policy];
}

/// ContextEntry wrapper for cache TTL Duration.
class CacheTtlEntry extends ContextEntry {
  const CacheTtlEntry(this.ttl);

  final Duration ttl;

  @override
  List<Object?> get fieldsForEquality => [ttl];
}

/// Extension methods for [Context] to configure cache behavior per-request.
///
/// These extensions provide a fluent API for overriding cache policies
/// and TTL values on a per-request basis.
///
/// Example:
/// ```dart
/// // Override cache policy for a single request
/// final response = await client.execute(
///   query,
///   context: Context().withCachePolicy(CachePolicy.networkOnly),
/// );
///
/// // Override both policy and TTL
/// final response = await client.execute(
///   query,
///   context: Context().withCache(
///     policy: CachePolicy.cacheFirst,
///     ttl: Duration(hours: 1),
///   ),
/// );
/// ```
extension CacheContextExtension on Context {
  /// Creates a new context with the specified cache policy.
  ///
  /// This overrides the default cache policy for a single request.
  ///
  /// Example:
  /// ```dart
  /// // Force fresh data from network
  /// final response = await client.execute(
  ///   query,
  ///   context: Context().withCachePolicy(CachePolicy.networkOnly),
  /// );
  ///
  /// // Use cache only, don't fetch from network
  /// final response = await client.execute(
  ///   query,
  ///   context: Context().withCachePolicy(CachePolicy.cacheOnly),
  /// );
  /// ```
  Context withCachePolicy(CachePolicy policy) {
    return withEntry(CachePolicyEntry(policy));
  }

  /// Creates a new context with the specified cache TTL.
  ///
  /// This overrides the default TTL for a single request.
  ///
  /// Example:
  /// ```dart
  /// // Cache for 1 hour instead of default
  /// final response = await client.execute(
  ///   query,
  ///   context: Context().withCacheTtl(Duration(hours: 1)),
  /// );
  ///
  /// // Cache indefinitely (no expiration)
  /// final response = await client.execute(
  ///   query,
  ///   context: Context().withCacheTtl(null),
  /// );
  /// ```
  Context withCacheTtl(Duration? ttl) {
    return ttl != null ? withEntry(CacheTtlEntry(ttl)) : this;
  }

  /// Creates a new context with both cache policy and TTL.
  ///
  /// This is a convenience method that combines [withCachePolicy] and [withCacheTtl].
  ///
  /// Example:
  /// ```dart
  /// final response = await client.execute(
  ///   query,
  ///   context: Context().withCache(
  ///     policy: CachePolicy.cacheFirst,
  ///     ttl: Duration(minutes: 30),
  ///   ),
  /// );
  /// ```
  Context withCache({
    CachePolicy? policy,
    Duration? ttl,
  }) {
    var context = this;
    if (policy != null) context = context.withCachePolicy(policy);
    if (ttl != null) context = context.withCacheTtl(ttl);
    return context;
  }

  /// Disables caching for this request.
  ///
  /// Equivalent to `withCachePolicy(CachePolicy.networkOnly)`.
  ///
  /// Example:
  /// ```dart
  /// // Always fetch fresh data
  /// final response = await client.execute(
  ///   query,
  ///   context: Context().withoutCache(),
  /// );
  /// ```
  Context withoutCache() {
    return withCachePolicy(CachePolicy.networkOnly);
  }

  /// Forces the request to use only cached data.
  ///
  /// Equivalent to `withCachePolicy(CachePolicy.cacheOnly)`.
  ///
  /// Example:
  /// ```dart
  /// // Offline mode - only use cache
  /// final response = await client.execute(
  ///   query,
  ///   context: Context().cacheOnly(),
  /// );
  /// ```
  Context cacheOnly() {
    return withCachePolicy(CachePolicy.cacheOnly);
  }

  /// Returns cached data immediately, then fetches fresh data.
  ///
  /// Equivalent to `withCachePolicy(CachePolicy.cacheAndNetwork)`.
  /// Use with `client.stream()` to receive both responses.
  ///
  /// Example:
  /// ```dart
  /// client.stream(
  ///   query,
  ///   context: Context().cacheAndNetwork(),
  /// ).listen((response) {
  ///   // First: cached data (if available)
  ///   // Second: fresh network data
  ///   updateUI(response.data);
  /// });
  /// ```
  Context cacheAndNetwork() {
    return withCachePolicy(CachePolicy.cacheAndNetwork);
  }
}
