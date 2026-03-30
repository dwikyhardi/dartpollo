/// Defines the caching strategy for GraphQL requests.
///
/// Each policy determines how the cache and network are used to fulfill requests.
enum CachePolicy {
  /// Return cached data if available, otherwise fetch from network.
  ///
  /// This is the most common policy for read operations. It provides fast
  /// responses when data is cached while ensuring fresh data on cache misses.
  ///
  /// Flow:
  /// 1. Check cache
  /// 2. If found and not expired, return cached data
  /// 3. If not found, fetch from network and cache the result
  cacheFirst,

  /// Fetch from network first, fallback to cache on error.
  ///
  /// Use this when you want fresh data but need a fallback for offline scenarios.
  ///
  /// Flow:
  /// 1. Attempt network fetch
  /// 2. If successful, cache and return the result
  /// 3. If network fails, return cached data if available
  networkFirst,

  /// Only return cached data, never fetch from network.
  ///
  /// Use this for offline-only scenarios or when you know data is already cached.
  ///
  /// Flow:
  /// 1. Check cache
  /// 2. If found and not expired, return cached data
  /// 3. If not found, return null/error (no network request)
  cacheOnly,

  /// Always fetch from network, update cache.
  ///
  /// Use this when you need guaranteed fresh data (e.g., after mutations).
  ///
  /// Flow:
  /// 1. Fetch from network
  /// 2. Cache the result
  /// 3. Return the result
  networkOnly,

  /// Return cached data immediately, then fetch and update.
  ///
  /// Use this for optimistic UI updates where you want instant feedback
  /// followed by fresh data.
  ///
  /// Flow:
  /// 1. If cached data exists, return it immediately
  /// 2. Fetch from network in parallel
  /// 3. When network responds, cache and return updated data
  cacheAndNetwork,
}
