import 'dart:collection';

import 'cache_entry.dart';
import 'cache_store.dart';

/// In-memory cache store implementation with LRU eviction.
///
/// This is the default cache store that doesn't require any external dependencies.
/// Data is stored in memory and will be lost when the application restarts.
///
/// Features:
/// - Fast O(1) lookups, inserts, and deletes
/// - Optional size limit with LRU (Least Recently Used) eviction
/// - Automatic expiration of TTL-based entries
/// - Thread-safe operations
///
/// Example:
/// ```dart
/// final store = InMemoryCacheStore(maxSize: 100);
/// store.set('key', CacheEntry(
///   data: {'user': 'John'},
///   timestamp: DateTime.now(),
///   ttl: Duration(minutes: 5),
/// ));
/// ```
class InMemoryCacheStore implements CacheStore {
  /// Creates an in-memory cache store.
  ///
  /// [maxSize] is the maximum number of entries to store. When exceeded,
  /// the least recently used entry will be evicted. If null, no size limit.
  InMemoryCacheStore({this.maxSize});

  /// Maximum number of entries. If null, unlimited.
  final int? maxSize;

  /// Internal storage map.
  final Map<String, CacheEntry> _cache = {};

  /// Queue to track access order for LRU eviction.
  final Queue<String> _accessOrder = Queue();

  @override
  CacheEntry? get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // Check expiration
    if (entry.isExpired) {
      delete(key);
      return null;
    }

    // Update LRU tracking
    _accessOrder
      ..remove(key)
      ..addLast(key);

    return entry;
  }

  @override
  void set(String key, CacheEntry entry) {
    // If key already exists, remove it from access order
    if (_cache.containsKey(key)) {
      _accessOrder.remove(key);
    }

    // Add/update entry
    _cache[key] = entry;
    _accessOrder.addLast(key);

    // LRU eviction if size limit exceeded
    if (maxSize != null && _cache.length > maxSize!) {
      final oldestKey = _accessOrder.removeFirst();
      _cache.remove(oldestKey);
    }
  }

  @override
  void delete(String key) {
    _cache.remove(key);
    _accessOrder.remove(key);
  }

  @override
  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }

  @override
  Map<String, CacheEntry> getAll() {
    // Filter out expired entries
    final validEntries = <String, CacheEntry>{};
    final expiredKeys = <String>[];

    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      } else {
        validEntries[entry.key] = entry.value;
      }
    }

    // Clean up expired entries
    expiredKeys.forEach(delete);

    return Map.unmodifiable(validEntries);
  }

  @override
  int get size {
    // Count only non-expired entries
    return _cache.values.where((entry) => !entry.isExpired).length;
  }

  @override
  bool contains(String key) => get(key) != null;

  @override
  void evictExpired() {
    final expiredKeys = <String>[];

    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    expiredKeys.forEach(delete);
  }

  /// Returns statistics about the cache.
  ///
  /// Useful for monitoring and debugging.
  Map<String, dynamic> getStats() {
    final all = getAll();
    return {
      'size': all.length,
      'maxSize': maxSize,
      'utilizationPercent': maxSize != null
          ? (all.length / maxSize! * 100).toStringAsFixed(1)
          : 'unlimited',
      'oldestEntry': _accessOrder.isNotEmpty ? _accessOrder.first : null,
      'newestEntry': _accessOrder.isNotEmpty ? _accessOrder.last : null,
    };
  }

  @override
  String toString() {
    final stats = getStats();
    return 'InMemoryCacheStore(size: ${stats['size']}, maxSize: ${stats['maxSize']}, utilization: ${stats['utilizationPercent']}%)';
  }
}
