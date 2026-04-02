import 'dart:developer';

import 'package:hive_ce/hive.dart';

import 'cache_entry.dart';
import 'cache_store.dart';

/// Persistent cache store implementation using Hive.
///
/// This store provides persistent storage for cache entries using Hive,
/// a fast, lightweight NoSQL database for Dart and Flutter.
///
/// Features:
/// - Persistent storage (survives app restarts)
/// - Fast O(1) lookups, inserts, and deletes
/// - Automatic expiration of TTL-based entries
/// - Lazy box opening for better performance
///
/// Requirements:
/// - Application must initialize Hive before using this store
/// - For Flutter: Use path_provider to get a writable directory
/// - For Dart: Use Hive.init() with a valid directory path
///
/// Example:
/// ```dart
/// // Initialize Hive (once in your app)
/// Hive.init('/path/to/app/data');
///
/// // Open the store
/// final store = await HiveCacheStore.open('dartpollo_cache');
///
/// // Use with DartpolloCachedClient
/// final client = DartpolloCachedClient(
///   'https://api.example.com/graphql',
///   cacheStore: store,
/// );
///
/// // Close when done (optional, but recommended)
/// await store.close();
/// ```
class HiveCacheStore implements CacheStore {
  /// Creates a Hive cache store with an already-opened box.
  ///
  /// Use [HiveCacheStore.open] instead for most cases.
  HiveCacheStore._(this._box);

  /// The underlying Hive box for storage.
  final Box<Map<dynamic, dynamic>> _box;

  Box<Map<dynamic, dynamic>> get _storageBox =>
      _box.isOpen ? _box : throw HiveError('Hive box is not open');

  /// Opens or creates a Hive cache store.
  ///
  /// [boxName] is the name of the Hive box to use for storage.
  /// Each box is a separate storage namespace.
  ///
  /// Throws [HiveError] if Hive is not initialized or if there's an error
  /// opening the box.
  ///
  /// Example:
  /// ```dart
  /// final store = await HiveCacheStore.open('my_cache');
  /// ```
  static Future<HiveCacheStore> open(String boxName) async {
    final box = await Hive.openBox<Map<dynamic, dynamic>>(boxName);
    return HiveCacheStore._(box);
  }

  @override
  CacheEntry? get(String key) {
    final json = _storageBox.get(key);
    if (json == null) return null;

    try {
      final entry = CacheEntry.fromJson(Map<String, dynamic>.from(json));

      // Check expiration
      if (entry.isExpired) {
        delete(key);
        return null;
      }

      return entry;
    } on Exception catch (e, s) {
      log(
        'HiveCacheStore: Failed to deserialize cache entry for key "$key": $e',
        level: 900,
        stackTrace: s,
      );
      // If deserialization fails, remove the corrupted entry
      delete(key);
      return null;
    }
  }

  @override
  void set(String key, CacheEntry entry) {
    _storageBox.put(key, entry.toJson());
  }

  @override
  void delete(String key) {
    _storageBox.delete(key);
  }

  @override
  void clear() {
    _storageBox.clear();
  }

  @override
  Map<String, CacheEntry> getAll() {
    final result = <String, CacheEntry>{};
    final expiredKeys = <String>[];

    for (final key in _storageBox.keys) {
      final json = _storageBox.get(key);
      if (json == null) continue;

      try {
        final entry = CacheEntry.fromJson(Map<String, dynamic>.from(json));

        if (entry.isExpired) {
          expiredKeys.add(key.toString());
        } else {
          result[key.toString()] = entry;
        }
      } on Exception catch (e, s) {
        log(
          'HiveCacheStore: Failed to deserialize cache entry for key "$key": $e',
          level: 900,
          stackTrace: s,
        );
        // If deserialization fails, mark for deletion
        expiredKeys.add(key.toString());
      }
    }

    // Clean up expired/corrupted entries
    expiredKeys.forEach(delete);

    return Map.unmodifiable(result);
  }

  @override
  int get size {
    // Count only non-expired entries
    var count = 0;
    for (final key in _storageBox.keys) {
      final json = _storageBox.get(key);
      if (json == null) continue;

      try {
        final entry = CacheEntry.fromJson(Map<String, dynamic>.from(json));
        if (!entry.isExpired) {
          count++;
        }
      } on Exception catch (e, s) {
        log(
          'HiveCacheStore: Failed to deserialize cache entry for key "$key": $e',
          level: 900,
          stackTrace: s,
        );
        // Skip corrupted entries
        continue;
      }
    }
    return count;
  }

  @override
  bool contains(String key) => get(key) != null;

  @override
  void evictExpired() {
    final expiredKeys = <String>[];

    for (final key in _storageBox.keys) {
      final json = _storageBox.get(key);
      if (json == null) continue;

      try {
        final entry = CacheEntry.fromJson(Map<String, dynamic>.from(json));
        if (entry.isExpired) {
          expiredKeys.add(key.toString());
        }
      } on Exception catch (e, s) {
        log(
          'HiveCacheStore: Failed to deserialize cache entry for key "$key": $e',
          level: 900,
          stackTrace: s,
        );
        // Mark corrupted entries for deletion
        expiredKeys.add(key.toString());
      }
    }

    expiredKeys.forEach(delete);
  }

  /// Closes the underlying Hive box.
  ///
  /// Call this when you're done with the store to release resources.
  /// After closing, the store cannot be used anymore.
  ///
  /// Example:
  /// ```dart
  /// await store.close();
  /// ```
  Future<void> close() async {
    await _storageBox.close();
  }

  /// Compacts the underlying Hive box to reclaim disk space.
  ///
  /// This is useful after deleting many entries to reduce the file size.
  ///
  /// Example:
  /// ```dart
  /// await store.compact();
  /// ```
  Future<void> compact() async {
    await _storageBox.compact();
  }

  /// Returns statistics about the cache.
  ///
  /// Useful for monitoring and debugging.
  Map<String, dynamic> getStats() {
    return {
      'size': size,
      'totalKeys': _storageBox.length,
      'boxName': _storageBox.name,
      'isOpen': _storageBox.isOpen,
      'path': _storageBox.path,
    };
  }

  @override
  String toString() {
    final stats = getStats();
    return 'HiveCacheStore(boxName: ${stats['boxName']}, size: ${stats['size']}, totalKeys: ${stats['totalKeys']})';
  }
}
