import 'dart:io';

import 'package:path/path.dart' as p;

/// Service responsible for file operations including path manipulation,
/// validation, and file system abstractions.
class FileService {
  /// Private constructor to prevent instantiation.
  const FileService._();

  static const FileService instance = FileService._();

  /// Extracts the basename without extension from a file path
  ///
  /// Example:
  /// - extractBasename('/path/to/file.dart') returns 'file'
  /// - extractBasename('file.graphql.dart') returns 'file'
  static String extractBasename(String path) {
    if (path.isEmpty) {
      throw ArgumentError('Path cannot be empty');
    }

    return p.basenameWithoutExtension(path);
  }

  /// Extracts the directory path from a full file path
  ///
  /// Example:
  /// - extractPath('/path/to/file.dart') returns '/path/to'
  /// - extractPath('file.dart') returns '.'
  static String extractPath(String fullPath) {
    if (fullPath.isEmpty) {
      throw ArgumentError('Path cannot be empty');
    }

    return p.dirname(fullPath);
  }

  /// Validates that a path is valid and accessible
  ///
  /// Throws [ArgumentError] if the path is invalid
  /// Throws [FileSystemException] if the path is not accessible
  static void validatePath(String path) {
    if (path.isEmpty) {
      throw ArgumentError('Path cannot be empty');
    }

    // Check for invalid characters (basic validation)
    if (path.contains('\x00')) {
      throw ArgumentError('Path contains null character');
    }

    // Normalize the path to handle relative paths and redundant separators
    final normalizedPath = p.normalize(path);

    // Check if the path is absolute or relative
    if (p.isAbsolute(normalizedPath)) {
      // For absolute paths, check if parent directory exists
      final parentDir = p.dirname(normalizedPath);
      if (!Directory(parentDir).existsSync()) {
        throw FileSystemException('Parent directory does not exist', parentDir);
      }
    }

    // Additional validation can be added here as needed
  }

  /// Normalizes a file path by resolving relative components and redundant separators
  ///
  /// Example:
  /// - normalizePath('./path/../file.dart') returns 'file.dart'
  /// - normalizePath('/path//to/file.dart') returns '/path/to/file.dart'
  static String normalizePath(String path) {
    if (path.isEmpty) {
      throw ArgumentError('Path cannot be empty');
    }

    return p.normalize(path);
  }

  /// Joins multiple path components into a single path
  ///
  /// Example:
  /// - joinPath(['path', 'to', 'file.dart']) returns 'path/to/file.dart'
  static String joinPath(List<String> components) {
    if (components.isEmpty) {
      throw ArgumentError('Path components cannot be empty');
    }

    return p.joinAll(components);
  }

  /// Checks if a path is absolute
  ///
  /// Example:
  /// - isAbsolute('/path/to/file') returns true
  /// - isAbsolute('relative/path') returns false
  static bool isAbsolute(String path) {
    if (path.isEmpty) {
      return false;
    }

    return p.isAbsolute(path);
  }

  /// Gets the file extension from a path
  ///
  /// Example:
  /// - getExtension('file.dart') returns '.dart'
  /// - getExtension('file.graphql.dart') returns '.dart'
  static String getExtension(String path) {
    if (path.isEmpty) {
      return '';
    }

    return p.extension(path);
  }
}
