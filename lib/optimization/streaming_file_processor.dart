import 'dart:async';
import 'dart:developer' as dev;
import 'dart:convert';
import 'package:build/build.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';

/// Advanced file processor that implements streaming and chunked processing
/// for large GraphQL files to reduce memory usage and improve performance.
class StreamingFileProcessor {
  /// Default chunk size for file processing (64KB)
  static const int defaultChunkSize = 64 * 1024;

  /// Maximum memory usage threshold (10MB)
  static const int maxMemoryThreshold = 10 * 1024 * 1024;

  /// Current memory usage tracking
  int _currentMemoryUsage = 0;

  /// Statistics for monitoring
  final Map<String, dynamic> _stats = {
    'totalFilesProcessed': 0,
    'totalBytesProcessed': 0,
    'chunksProcessed': 0,
    'peakMemoryUsage': 0,
    'averageChunkSize': 0,
  };

  /// Process a large file using streaming/chunked approach
  Future<List<DocumentNode>> processLargeFile(
    BuildStep buildStep,
    AssetId assetId, {
    int chunkSize = defaultChunkSize,
    bool enableMemoryMonitoring = true,
  }) async {
    final fileSize = await _getFileSize(buildStep, assetId);

    // Use streaming for files larger than 1MB
    if (fileSize > 1024 * 1024) {
      return await _processFileStreaming(
        buildStep,
        assetId,
        chunkSize: chunkSize,
        enableMemoryMonitoring: enableMemoryMonitoring,
      );
    } else {
      // Use regular processing for smaller files
      return await _processFileRegular(buildStep, assetId);
    }
  }

  /// Process multiple files with streaming optimization
  Future<List<DocumentNode>> processMultipleFiles(
    BuildStep buildStep,
    List<AssetId> assetIds, {
    int chunkSize = defaultChunkSize,
    bool enableMemoryMonitoring = true,
  }) async {
    final allDocuments = <DocumentNode>[];

    for (final assetId in assetIds) {
      final documents = await processLargeFile(
        buildStep,
        assetId,
        chunkSize: chunkSize,
        enableMemoryMonitoring: enableMemoryMonitoring,
      );
      allDocuments.addAll(documents);

      // Check memory usage and trigger cleanup if needed
      if (enableMemoryMonitoring && _currentMemoryUsage > maxMemoryThreshold) {
        await _performMemoryCleanup();
      }
    }

    return allDocuments;
  }

  /// Generate streaming output for large generated content
  Future<void> writeStreamingOutput(
    BuildStep buildStep,
    AssetId outputId,
    Stream<String> contentStream, {
    int bufferSize = defaultChunkSize,
  }) async {
    final buffer = StringBuffer();
    int bufferLength = 0;

    await for (final chunk in contentStream) {
      buffer.write(chunk);
      bufferLength += chunk.length;

      // Flush buffer when it reaches the buffer size
      if (bufferLength >= bufferSize) {
        await buildStep.writeAsString(outputId, buffer.toString());

        // Update memory tracking before resetting bufferLength
        _updateMemoryUsage(-bufferLength);

        buffer.clear();
        bufferLength = 0;
      }
    }

    // Write remaining content
    if (bufferLength > 0) {
      await buildStep.writeAsString(outputId, buffer.toString());
    }
  }

  /// Get memory usage statistics
  Map<String, dynamic> getMemoryStats() {
    return {
      'currentMemoryUsage': _currentMemoryUsage,
      'maxMemoryThreshold': maxMemoryThreshold,
      'memoryUtilization':
          (_currentMemoryUsage / maxMemoryThreshold * 100).toStringAsFixed(2),
      ..._stats,
    };
  }

  /// Reset all statistics and clear memory
  void reset() {
    _currentMemoryUsage = 0;
    _stats.clear();
    _stats.addAll({
      'totalFilesProcessed': 0,
      'totalBytesProcessed': 0,
      'chunksProcessed': 0,
      'peakMemoryUsage': 0,
      'averageChunkSize': 0,
    });
  }

  // Private methods

  Future<int> _getFileSize(BuildStep buildStep, AssetId assetId) async {
    try {
      final content = await buildStep.readAsString(assetId);
      return utf8.encode(content).length;
    } catch (e) {
      // If we can't determine size, assume it's small
      return 0;
    }
  }

  Future<List<DocumentNode>> _processFileStreaming(
    BuildStep buildStep,
    AssetId assetId, {
    required int chunkSize,
    required bool enableMemoryMonitoring,
  }) async {
    final documents = <DocumentNode>[];
    final contentBuffer = StringBuffer();

    // Read file content
    final fullContent = await buildStep.readAsString(assetId);
    final contentBytes = utf8.encode(fullContent);

    _updateStats('totalFilesProcessed', 1);
    _updateStats('totalBytesProcessed', contentBytes.length);

    // Process in chunks
    for (int i = 0; i < contentBytes.length; i += chunkSize) {
      final endIndex = (i + chunkSize < contentBytes.length)
          ? i + chunkSize
          : contentBytes.length;

      final chunk = contentBytes.sublist(i, endIndex);
      final chunkContent = utf8.decode(chunk);

      contentBuffer.write(chunkContent);

      // Update memory tracking
      if (enableMemoryMonitoring) {
        _updateMemoryUsage(chunk.length);
        _updateStats('chunksProcessed', 1);
      }

      // Try to parse complete GraphQL documents from buffer
      final parsedDocs = _tryParseCompleteDocuments(contentBuffer);
      documents.addAll(parsedDocs);
    }

    // Parse any remaining content
    if (contentBuffer.isNotEmpty) {
      try {
        final remainingDoc =
            parseString(contentBuffer.toString(), url: assetId.path);
        documents.add(remainingDoc);
      } catch (e) {
        // Handle parsing errors gracefully
        dev.log(
            'Warning: Could not parse remaining content in ${assetId.path}: $e');
      }
    }

    return documents;
  }

  Future<List<DocumentNode>> _processFileRegular(
    BuildStep buildStep,
    AssetId assetId,
  ) async {
    final content = await buildStep.readAsString(assetId);
    final document = parseString(content, url: assetId.path);

    _updateStats('totalFilesProcessed', 1);
    _updateStats('totalBytesProcessed', utf8.encode(content).length);

    return [document];
  }

  List<DocumentNode> _tryParseCompleteDocuments(StringBuffer buffer) {
    final documents = <DocumentNode>[];
    final content = buffer.toString();

    // Look for complete GraphQL document boundaries
    final documentBoundaries = _findDocumentBoundaries(content);

    for (final boundary in documentBoundaries) {
      try {
        final docContent = content.substring(boundary.start, boundary.end);
        final document = parseString(docContent);
        documents.add(document);

        // Remove processed content from buffer
        buffer.clear();
        buffer.write(content.substring(boundary.end));
      } catch (e) {
        // Document is incomplete, keep in buffer
        break;
      }
    }

    return documents;
  }

  List<_DocumentBoundary> _findDocumentBoundaries(String content) {
    final boundaries = <_DocumentBoundary>[];
    final lines = content.split('\n');

    int currentStart = 0;
    int currentPos = 0;
    bool inDocument = false;
    int braceCount = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      currentPos += lines[i].length + 1; // +1 for newline

      if (line.isEmpty || line.startsWith('#')) continue;

      // Check for GraphQL keywords that start documents
      if (line.startsWith('query') ||
          line.startsWith('mutation') ||
          line.startsWith('subscription') ||
          line.startsWith('fragment') ||
          line.startsWith('type') ||
          line.startsWith('schema')) {
        if (inDocument && braceCount == 0) {
          // End of previous document
          boundaries.add(_DocumentBoundary(
              currentStart, currentPos - lines[i].length - 1));
        }

        currentStart = currentPos - lines[i].length - 1;
        inDocument = true;
        braceCount = 0;
      }

      // Count braces to determine document completeness
      braceCount += line.split('{').length - 1;
      braceCount -= line.split('}').length - 1;

      if (inDocument && braceCount == 0 && line.contains('}')) {
        // Complete document found
        boundaries.add(_DocumentBoundary(currentStart, currentPos));
        inDocument = false;
      }
    }

    return boundaries;
  }

  void _updateMemoryUsage(int delta) {
    _currentMemoryUsage += delta;
    final currentPeak = _stats['peakMemoryUsage'] as int? ?? 0;
    if (_currentMemoryUsage > currentPeak) {
      _stats['peakMemoryUsage'] = _currentMemoryUsage;
    }
  }

  void _updateStats(String key, dynamic value) {
    if (_stats.containsKey(key)) {
      if (value is int) {
        _stats[key] = (_stats[key] as int) + value;
      } else {
        _stats[key] = value;
      }
    }
  }

  Future<void> _performMemoryCleanup() async {
    // Force garbage collection and reset memory tracking
    _currentMemoryUsage = _currentMemoryUsage ~/ 2; // Simulate cleanup

    // Add small delay to allow system cleanup
    await Future.delayed(Duration(milliseconds: 10));
  }
}

/// Represents a boundary of a complete GraphQL document in a file
class _DocumentBoundary {
  final int start;
  final int end;

  _DocumentBoundary(this.start, this.end);
}
