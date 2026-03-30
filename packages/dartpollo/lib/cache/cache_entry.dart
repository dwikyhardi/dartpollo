// ignore_for_file: unintended_html_in_doc_comment

/// Represents a cached entry with metadata.
///
/// Each cache entry contains the cached data along with timing information
/// to support TTL (Time To Live) expiration.
class CacheEntry {
  /// Creates a cache entry.
  ///
  /// [data] is the cached GraphQL response data.
  /// [timestamp] is when this entry was created/updated.
  /// [ttl] is the optional time-to-live duration. If null, the entry never expires.
  CacheEntry({
    required this.data,
    required this.timestamp,
    this.ttl,
  });

  /// Creates a cache entry from a JSON map.
  ///
  /// Useful for deserializing from persistent storage.
  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
    data: _deepConvertMap(json['data'] as Map),
    timestamp: DateTime.parse(json['timestamp'] as String),
    ttl: json['ttl'] != null
        ? Duration(milliseconds: json['ttl'] as int)
        : null,
  );

  /// Recursively converts Map<dynamic, dynamic> to Map<String, dynamic>
  static Map<String, dynamic> _deepConvertMap(Map<dynamic, dynamic> map) {
    final result = <String, dynamic>{};
    map.forEach((key, value) {
      result[key.toString()] = _deepConvertValue(value);
    });
    return result;
  }

  /// Recursively converts values, handling nested maps and lists
  static dynamic _deepConvertValue(dynamic value) {
    if (value is Map) {
      return _deepConvertMap(value);
    } else if (value is List) {
      return value.map(_deepConvertValue).toList();
    }
    return value;
  }

  /// The cached response data.
  final Map<String, dynamic> data;

  /// When this entry was created or last updated.
  final DateTime timestamp;

  /// Time-to-live duration. If null, the entry never expires.
  final Duration? ttl;

  /// Checks if this cache entry has expired based on its TTL.
  ///
  /// Returns `false` if no TTL is set (never expires).
  /// Returns `true` if the current time exceeds timestamp + TTL.
  bool get isExpired {
    if (ttl == null) return false;
    return DateTime.now().difference(timestamp) > ttl!;
  }

  /// Converts this cache entry to a JSON-serializable map.
  ///
  /// Useful for persistent storage implementations like Hive or SharedPreferences.
  Map<String, dynamic> toJson() => {
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'ttl': ttl?.inMilliseconds,
  };

  /// Creates a copy of this entry with updated fields.
  CacheEntry copyWith({
    Map<String, dynamic>? data,
    DateTime? timestamp,
    Duration? ttl,
  }) => CacheEntry(
    data: data ?? this.data,
    timestamp: timestamp ?? this.timestamp,
    ttl: ttl ?? this.ttl,
  );

  @override
  String toString() =>
      'CacheEntry('
      'timestamp: $timestamp, '
      'ttl: $ttl, '
      'expired: $isExpired, '
      'dataKeys: ${data.keys.join(", ")}'
      ')';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CacheEntry &&
          runtimeType == other.runtimeType &&
          data.toString() == other.data.toString() &&
          timestamp == other.timestamp &&
          ttl == other.ttl;

  @override
  int get hashCode => Object.hash(data.toString(), timestamp, ttl);
}
