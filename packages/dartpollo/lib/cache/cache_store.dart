import 'cache_entry.dart';

/// Abstract interface for cache storage implementations.
///
/// Implementations can use different storage backends such as:
/// - In-memory (Map-based)
/// - Hive (persistent local storage)
/// - SharedPreferences (simple persistent storage)
/// - Custom implementations (Redis, SQLite, etc.)
///
/// All implementations must handle:
/// - Thread-safe operations (if applicable)
/// - Automatic expiration of TTL-based entries
/// - Efficient key-based lookups
abstract class CacheStore {
  /// Retrieves a cache entry by its key.
  ///
  /// Returns `null` if:
  /// - The key doesn't exist
  /// - The entry has expired (implementations should auto-delete expired entries)
  ///
  /// Implementations should check [CacheEntry.isExpired] and automatically
  /// delete expired entries before returning null.
  CacheEntry? get(String key);

  /// Stores a cache entry with the given key.
  ///
  /// If an entry with the same key already exists, it should be replaced.
  ///
  /// Implementations may enforce size limits and evict old entries as needed
  /// (e.g., LRU eviction).
  void set(String key, CacheEntry entry);

  /// Deletes a cache entry by its key.
  ///
  /// Does nothing if the key doesn't exist.
  void delete(String key);

  /// Clears all entries from the cache.
  ///
  /// This operation should be atomic if possible.
  void clear();

  /// Returns all cache entries as a map.
  ///
  /// Useful for:
  /// - Debugging and inspection
  /// - Bulk operations
  /// - Cache migration
  ///
  /// Expired entries should be excluded from the result.
  Map<String, CacheEntry> getAll();

  /// Returns the number of entries in the cache.
  ///
  /// Expired entries should not be counted.
  int get size => getAll().length;

  /// Checks if a key exists in the cache and is not expired.
  bool contains(String key) => get(key) != null;

  /// Removes all expired entries from the cache.
  ///
  /// This is useful for periodic cleanup in long-running applications.
  /// Some implementations may call this automatically during get/set operations.
  void evictExpired() {
    final allEntries = getAll();
    for (final entry in allEntries.entries) {
      if (entry.value.isExpired) {
        delete(entry.key);
      }
    }
  }
}
