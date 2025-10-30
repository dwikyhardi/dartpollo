import 'dart:async';
import 'dart:developer' as developer;
import 'package:gql/ast.dart';
import '../transformer/add_typename_transformer.dart';

/// Exception thrown when AppendTypename processing fails
class AppendTypenameProcessingError extends Error {
  AppendTypenameProcessingError(
    this.message, {
    this.documentName,
    this.fragmentName,
    this.originalError,
  });

  final String message;
  final String? documentName;
  final String? fragmentName;
  final Object? originalError;

  @override
  String toString() {
    final buffer = StringBuffer('AppendTypenameProcessingError: $message');
    if (documentName != null) {
      buffer.write(' (Document: $documentName)');
    }
    if (fragmentName != null) {
      buffer.write(' (Fragment: $fragmentName)');
    }
    if (originalError != null) {
      buffer.write(' (Caused by: $originalError)');
    }
    return buffer.toString();
  }
}

/// Exception thrown when transformation results are inconsistent
class TransformationInconsistencyError extends Error {
  TransformationInconsistencyError(
    this.message, {
    this.expectedResult,
    this.actualResult,
    this.documentName,
  });

  final String message;
  final String? expectedResult;
  final String? actualResult;
  final String? documentName;

  @override
  String toString() {
    final buffer = StringBuffer('TransformationInconsistencyError: $message');
    if (documentName != null) {
      buffer.write(' (Document: $documentName)');
    }
    if (expectedResult != null && actualResult != null) {
      buffer.write('\nExpected: $expectedResult\nActual: $actualResult');
    }
    return buffer.toString();
  }
}

/// Exception thrown when batch processing fails
class BatchProcessingError extends Error {
  BatchProcessingError(
    this.message, {
    this.batchSize,
    this.failedDocuments,
    this.originalError,
  });

  final String message;
  final int? batchSize;
  final List<String>? failedDocuments;
  final Object? originalError;

  @override
  String toString() {
    final buffer = StringBuffer('BatchProcessingError: $message');
    if (batchSize != null) {
      buffer.write(' (Batch size: $batchSize)');
    }
    if (failedDocuments != null && failedDocuments!.isNotEmpty) {
      buffer.write(' (Failed documents: ${failedDocuments!.join(', ')})');
    }
    if (originalError != null) {
      buffer.write(' (Caused by: $originalError)');
    }
    return buffer.toString();
  }
}

/// Exception thrown when validation fails during batch processing
class BatchValidationError extends Error {
  BatchValidationError(
    this.message,
    this.validationType, {
    this.validationDetails,
  });

  final String message;
  final String validationType;
  final Map<String, dynamic>? validationDetails;

  @override
  String toString() {
    final buffer = StringBuffer('BatchValidationError: $message')
      ..write(' (Validation type: $validationType)');
    if (validationDetails != null && validationDetails!.isNotEmpty) {
      buffer.write(' (Details: $validationDetails)');
    }
    return buffer.toString();
  }
}

/// Performance metrics for monitoring batch processing
class _PerformanceMetrics {
  int totalBatches = 0;
  int totalDocuments = 0;
  int totalFragments = 0;
  int cacheHits = 0;
  int cacheMisses = 0;
  int validationFailures = 0;
  int recoveryAttempts = 0;
  int successfulRecoveries = 0;
  Duration totalProcessingTime = Duration.zero;
  Duration totalValidationTime = Duration.zero;
  final List<String> errorLog = [];
  final Map<String, int> transformerUsage = {};

  void reset() {
    totalBatches = 0;
    totalDocuments = 0;
    totalFragments = 0;
    cacheHits = 0;
    cacheMisses = 0;
    validationFailures = 0;
    recoveryAttempts = 0;
    successfulRecoveries = 0;
    totalProcessingTime = Duration.zero;
    totalValidationTime = Duration.zero;
    errorLog.clear();
    transformerUsage.clear();
  }

  Map<String, dynamic> toMap() {
    return {
      'totalBatches': totalBatches,
      'totalDocuments': totalDocuments,
      'totalFragments': totalFragments,
      'cacheHits': cacheHits,
      'cacheMisses': cacheMisses,
      'cacheHitRate': totalDocuments > 0 ? cacheHits / totalDocuments : 0.0,
      'validationFailures': validationFailures,
      'recoveryAttempts': recoveryAttempts,
      'successfulRecoveries': successfulRecoveries,
      'recoverySuccessRate': recoveryAttempts > 0
          ? successfulRecoveries / recoveryAttempts
          : 0.0,
      'totalProcessingTimeMs': totalProcessingTime.inMilliseconds,
      'totalValidationTimeMs': totalValidationTime.inMilliseconds,
      'averageProcessingTimeMs': totalBatches > 0
          ? totalProcessingTime.inMilliseconds / totalBatches
          : 0.0,
      'errorCount': errorLog.length,
      'transformerUsage': Map<String, int>.from(transformerUsage),
    };
  }
}

/// Advanced AST processor that implements batching and lazy evaluation
/// for improved performance when processing multiple GraphQL documents.
class BatchedASTProcessor {
  /// Cache for transformed documents to avoid redundant processing
  final Map<String, DocumentNode> _transformCache = {};

  /// Cache for transformation results by document hash
  final Map<String, List<DocumentNode>> _batchCache = {};

  /// Lazy evaluation queue for deferred transformations
  final List<_DeferredTransformation> _deferredQueue = [];

  /// Cache for AppendTypename transformation results
  final Map<String, DocumentNode> _appendTypenameCache = {};

  /// Cache for fragment transformation results with AppendTypename
  final Map<String, FragmentDefinitionNode> _fragmentAppendTypenameCache = {};

  /// Performance metrics for monitoring and debugging
  final _PerformanceMetrics _metrics = _PerformanceMetrics();

  /// Enable debug logging for troubleshooting
  bool enableDebugLogging = false;

  /// Enable validation checks (can be disabled in production for performance)
  bool enableValidation = true;

  /// Process multiple documents in a single batch operation
  /// This reduces the overhead of individual AST traversals
  Future<List<DocumentNode>> processBatch(
    List<DocumentNode> documents,
    List<TransformingVisitor> transformers, {
    bool enableLazyEvaluation = true,
  }) async {
    final processingStart = DateTime.now();

    try {
      _logDebug(
        'Starting processBatch',
        context: {
          'documentCount': documents.length,
          'transformerCount': transformers.length,
        },
      );

      // Validate input parameters first, before early returns
      _validateBatchInput(documents, transformers);

      if (documents.isEmpty) return [];

      // Update metrics
      _metrics.totalBatches++;
      _metrics.totalDocuments += documents.length;

      // Update transformer usage statistics
      for (final transformer in transformers) {
        final transformerName = transformer.runtimeType.toString();
        _metrics.transformerUsage[transformerName] =
            (_metrics.transformerUsage[transformerName] ?? 0) + 1;
      }

      // Generate batch key for caching
      final batchKey = _generateBatchKey(documents, transformers);

      // Check if we have cached results for this batch
      if (_batchCache.containsKey(batchKey)) {
        _metrics.cacheHits++;
        _logDebug(
          'Cache hit for batch',
          context: {
            'batchKey': batchKey,
            'documentCount': documents.length,
          },
        );
        return _batchCache[batchKey]!;
      }

      _metrics.cacheMisses++;
      _logDebug(
        'Cache miss for batch, processing...',
        context: {
          'batchKey': batchKey,
          'documentCount': documents.length,
          'transformerCount': transformers.length,
        },
      );

      List<DocumentNode> results;

      // Detect AppendTypename transformers in the transformer list
      final hasAppendTypename = _hasAppendTypenameTransformer(transformers);

      if (hasAppendTypename) {
        // Use specialized processing path when AppendTypename is present
        // Ensure proper sequencing when AppendTypename is combined with other transformers
        results = await _processBatchWithAppendTypename(
          documents,
          transformers,
        );
      } else if (enableLazyEvaluation &&
          _shouldDeferTransformation(transformers)) {
        // Queue for lazy evaluation
        results = _queueForLazyEvaluation(documents, transformers);
      } else {
        // Process immediately with batched optimization
        results = await _processBatchImmediate(documents, transformers);
      }

      // Cache the results
      _batchCache[batchKey] = results;

      _logDebug(
        'Batch processing completed successfully',
        context: {
          'processedDocuments': results.length,
          'processingTimeMs': DateTime.now()
              .difference(processingStart)
              .inMilliseconds,
        },
      );

      return results;
    } catch (error) {
      _logError(
        'Batch processing failed',
        error,
        context: {
          'documentCount': documents.length,
          'transformerCount': transformers.length,
        },
      );

      // Re-throw validation errors immediately - they should not be recovered from
      if (error is BatchValidationError) {
        rethrow;
      }

      // Attempt recovery for other types of errors
      try {
        return await _attemptBatchRecovery(documents, transformers, error);
      } on Exception catch (recoveryError) {
        _logError('Batch recovery failed', recoveryError);

        // Re-throw original error with additional context
        if (error is BatchProcessingError) {
          throw error;
        } else {
          throw BatchProcessingError(
            'Batch processing failed and recovery unsuccessful',
            batchSize: documents.length,
            originalError: error,
          );
        }
      }
    } finally {
      _metrics.totalProcessingTime += DateTime.now().difference(
        processingStart,
      );
    }
  }

  /// Process fragments in batch with optimized traversal
  Future<List<FragmentDefinitionNode>> processFragmentsBatch(
    List<FragmentDefinitionNode> fragments,
    List<TransformingVisitor> transformers,
  ) async {
    final processingStart = DateTime.now();

    try {
      if (fragments.isEmpty) return [];

      // Update metrics
      _metrics.totalFragments += fragments.length;

      _logDebug(
        'Starting fragment batch processing',
        context: {
          'fragmentCount': fragments.length,
          'transformerCount': transformers.length,
        },
      );

      // Validate fragments
      if (enableValidation) {
        for (var i = 0; i < fragments.length; i++) {
          final fragment = fragments[i];
          if (fragment.name.value.isEmpty) {
            throw BatchValidationError(
              'Fragment at index $i has empty name',
              'fragment_validation',
              validationDetails: {'fragmentIndex': i},
            );
          }
        }
      }

      // Check if AppendTypename transformer is present
      final hasAppendTypename = _hasAppendTypenameTransformer(transformers);

      if (hasAppendTypename) {
        // Use specialized fragment processing for AppendTypename
        return await _processFragmentsBatchWithAppendTypename(
          fragments,
          transformers,
        );
      }

      // Convert fragments to documents for batch processing
      final fragmentDocs = fragments
          .map((fragment) => DocumentNode(definitions: [fragment]))
          .toList();

      final processedDocs = await processBatch(fragmentDocs, transformers);

      // Extract fragments from processed documents
      final results = processedDocs
          .expand((doc) => doc.definitions.whereType<FragmentDefinitionNode>())
          .toList();

      _logDebug(
        'Fragment batch processing completed successfully',
        context: {
          'processedFragments': results.length,
          'processingTimeMs': DateTime.now()
              .difference(processingStart)
              .inMilliseconds,
        },
      );

      return results;
    } catch (error) {
      _logError(
        'Fragment batch processing failed',
        error,
        context: {
          'fragmentCount': fragments.length,
          'transformerCount': transformers.length,
        },
      );

      // Re-throw validation errors immediately - they should not be recovered from
      if (error is BatchValidationError) {
        rethrow;
      }

      // Attempt recovery for other types of errors
      try {
        return await _attemptFragmentRecovery(fragments, transformers, error);
      } on Exception catch (recoveryError) {
        _logError('Fragment recovery failed', recoveryError);

        // Re-throw original error with additional context
        if (error is BatchProcessingError) {
          throw error;
        } else {
          throw BatchProcessingError(
            'Fragment batch processing failed and recovery unsuccessful',
            batchSize: fragments.length,
            originalError: error,
          );
        }
      }
    } finally {
      _metrics.totalProcessingTime += DateTime.now().difference(
        processingStart,
      );
    }
  }

  /// Execute all deferred transformations
  /// Should be called when lazy evaluation results are actually needed
  Future<void> executeDeferredTransformations() async {
    if (_deferredQueue.isEmpty) return;

    // Group deferred transformations by transformer type for efficiency
    final groupedTransformations = <String, List<_DeferredTransformation>>{};

    for (final deferred in _deferredQueue) {
      final key = deferred.transformers
          .map((t) => t.runtimeType.toString())
          .join(',');
      groupedTransformations.putIfAbsent(key, () => []).add(deferred);
    }

    // Process each group in batch
    for (final group in groupedTransformations.values) {
      await _processTransformationGroup(group);
    }

    _deferredQueue.clear();
  }

  /// Clear all caches to free memory
  void clearCaches() {
    _transformCache.clear();
    _batchCache.clear();
    _deferredQueue.clear();
    _appendTypenameCache.clear();
    _fragmentAppendTypenameCache.clear();

    _logDebug('All caches cleared');
  }

  /// Get cache statistics for monitoring
  Map<String, int> getCacheStats() {
    return {
      'transformCacheSize': _transformCache.length,
      'batchCacheSize': _batchCache.length,
      'deferredQueueSize': _deferredQueue.length,
      'appendTypenameCacheSize': _appendTypenameCache.length,
      'fragmentAppendTypenameCacheSize': _fragmentAppendTypenameCache.length,
    };
  }

  /// Get comprehensive performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return _metrics.toMap();
  }

  /// Reset performance metrics
  void resetMetrics() {
    _metrics.reset();
  }

  /// Log debug information if debug logging is enabled
  void _logDebug(String message, {Map<String, dynamic>? context}) {
    if (enableDebugLogging) {
      final timestamp = DateTime.now().toIso8601String();
      final contextStr = context != null ? ' Context: $context' : '';
      final logMessage =
          '[$timestamp] BatchedASTProcessor: $message$contextStr';
      developer.log(logMessage, name: 'BatchedASTProcessor');
    }
  }

  /// Log error information and update metrics
  void _logError(
    String message,
    Object? error, {
    Map<String, dynamic>? context,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' Context: $context' : '';
    final errorStr = error != null ? ' Error: $error' : '';
    final logMessage = '[$timestamp] ERROR: $message$contextStr$errorStr';

    _metrics.errorLog.add(logMessage);
    developer.log(
      logMessage,
      name: 'BatchedASTProcessor',
      level: 1000,
    ); // Error level
  }

  /// Validate batch processing input parameters
  void _validateBatchInput(
    List<DocumentNode> documents,
    List<TransformingVisitor> transformers,
  ) {
    if (!enableValidation) {
      _logDebug('Validation disabled, skipping input validation');
      return;
    }

    final validationStart = DateTime.now();
    _logDebug(
      'Starting batch input validation',
      context: {
        'documentCount': documents.length,
        'transformerCount': transformers.length,
      },
    );

    try {
      if (documents.isEmpty) {
        _logDebug('Throwing BatchValidationError for empty document list');
        throw BatchValidationError(
          'Empty document list provided to batch processor',
          'input_validation',
        );
      }

      if (transformers.isEmpty) {
        throw BatchValidationError(
          'Empty transformer list provided to batch processor',
          'input_validation',
        );
      }

      // Validate document structure
      for (var i = 0; i < documents.length; i++) {
        final doc = documents[i];
        if (doc.definitions.isEmpty) {
          throw BatchValidationError(
            'Document at index $i has no definitions',
            'document_structure',
            validationDetails: {'documentIndex': i},
          );
        }

        // Check for valid operation types
        final hasValidOperations = doc.definitions.any(
          (def) =>
              def is OperationDefinitionNode || def is FragmentDefinitionNode,
        );

        if (!hasValidOperations) {
          throw BatchValidationError(
            'Document at index $i contains no valid operations or fragments',
            'document_content',
            validationDetails: {'documentIndex': i},
          );
        }
      }

      // Validate transformer compatibility
      final appendTypenameCount = transformers
          .whereType<AppendTypename>()
          .length;
      if (appendTypenameCount > 1) {
        throw BatchValidationError(
          'Multiple AppendTypename transformers detected ($appendTypenameCount)',
          'transformer_compatibility',
          validationDetails: {'appendTypenameCount': appendTypenameCount},
        );
      }

      _logDebug(
        'Batch input validation passed',
        context: {
          'documentCount': documents.length,
          'transformerCount': transformers.length,
          'hasAppendTypename': appendTypenameCount > 0,
        },
      );
    } catch (e) {
      _metrics.validationFailures++;
      _logError('Batch input validation failed', e);
      rethrow;
    } finally {
      _metrics.totalValidationTime += DateTime.now().difference(
        validationStart,
      );
    }
  }

  /// Validate transformation correctness by comparing with expected results
  void _validateTransformationCorrectness(
    DocumentNode original,
    DocumentNode transformed,
    List<TransformingVisitor> transformers,
    String documentName,
  ) {
    if (!enableValidation) return;

    final validationStart = DateTime.now();

    try {
      // Basic structural validation
      if (transformed.definitions.isEmpty && original.definitions.isNotEmpty) {
        throw TransformationInconsistencyError(
          'Transformation resulted in empty definitions',
          documentName: documentName,
        );
      }

      // Validate definition count consistency for non-modifying transformers
      final modifyingTransformers = transformers.whereType<AppendTypename>();
      if (modifyingTransformers.isEmpty) {
        if (transformed.definitions.length != original.definitions.length) {
          throw TransformationInconsistencyError(
            'Definition count changed without modifying transformers',
            documentName: documentName,
            expectedResult: 'Definition count: ${original.definitions.length}',
            actualResult: 'Definition count: ${transformed.definitions.length}',
          );
        }
      }

      // AppendTypename-specific validation
      final appendTypename = _getAppendTypenameTransformer(transformers);
      if (appendTypename != null) {
        _validateAppendTypenameTransformation(
          original,
          transformed,
          appendTypename,
          documentName,
        );
      }

      _logDebug(
        'Transformation correctness validation passed',
        context: {
          'documentName': documentName,
          'originalDefinitions': original.definitions.length,
          'transformedDefinitions': transformed.definitions.length,
        },
      );
    } catch (e) {
      _metrics.validationFailures++;
      _logError(
        'Transformation correctness validation failed',
        e,
        context: {
          'documentName': documentName,
        },
      );
      rethrow;
    } finally {
      _metrics.totalValidationTime += DateTime.now().difference(
        validationStart,
      );
    }
  }

  /// Validate AppendTypename transformation specifically
  void _validateAppendTypenameTransformation(
    DocumentNode original,
    DocumentNode transformed,
    AppendTypename transformer,
    String documentName,
  ) {
    final typeNameField = transformer.typeName;

    // Check each operation definition for typename field
    for (var i = 0; i < transformed.definitions.length; i++) {
      final definition = transformed.definitions[i];

      if (definition is OperationDefinitionNode) {
        final hasTypenameField = _hasTypenameFieldInSelectionSet(
          definition.selectionSet,
          typeNameField,
        );

        if (!hasTypenameField) {
          throw AppendTypenameProcessingError(
            'Expected typename field "$typeNameField" not found in operation',
            documentName: documentName,
          );
        }
      } else if (definition is FragmentDefinitionNode) {
        final hasTypenameField = _hasTypenameFieldInSelectionSet(
          definition.selectionSet,
          typeNameField,
        );

        if (!hasTypenameField) {
          throw AppendTypenameProcessingError(
            'Expected typename field "$typeNameField" not found in fragment "${definition.name.value}"',
            documentName: documentName,
            fragmentName: definition.name.value,
          );
        }
      }
    }
  }

  /// Check if a selection set contains the typename field
  bool _hasTypenameFieldInSelectionSet(
    SelectionSetNode selectionSet,
    String typeNameField,
  ) {
    return selectionSet.selections.any((selection) {
      if (selection is FieldNode) {
        return selection.name.value == typeNameField;
      }
      return false;
    });
  }

  /// Attempt to recover from batch processing failures
  Future<List<DocumentNode>> _attemptBatchRecovery(
    List<DocumentNode> documents,
    List<TransformingVisitor> transformers,
    Object error,
  ) async {
    _metrics.recoveryAttempts++;

    _logError(
      'Attempting batch recovery',
      error,
      context: {
        'documentCount': documents.length,
        'transformerCount': transformers.length,
      },
    );

    try {
      // Strategy 1: Process documents individually as fallback
      final results = <DocumentNode>[];

      for (var i = 0; i < documents.length; i++) {
        try {
          final doc = documents[i];
          var transformed = doc;

          for (final transformer in transformers) {
            transformed = _applyTransformerToDocument(transformed, transformer);
          }

          results.add(transformed);
        } on Exception catch (individualError) {
          _logError(
            'Individual document processing failed during recovery',
            individualError,
            context: {
              'documentIndex': i,
            },
          );

          // Use original document as fallback
          results.add(documents[i]);
        }
      }

      _metrics.successfulRecoveries++;
      _logDebug(
        'Batch recovery successful',
        context: {
          'recoveredDocuments': results.length,
        },
      );

      return results;
    } on Exception catch (recoveryError) {
      _logError('Batch recovery failed', recoveryError);

      // Final fallback: return original documents
      _logDebug('Using original documents as final fallback');
      return documents;
    }
  }

  /// Attempt to recover from fragment processing failures
  Future<List<FragmentDefinitionNode>> _attemptFragmentRecovery(
    List<FragmentDefinitionNode> fragments,
    List<TransformingVisitor> transformers,
    Object error,
  ) async {
    _metrics.recoveryAttempts++;

    _logError(
      'Attempting fragment recovery',
      error,
      context: {
        'fragmentCount': fragments.length,
        'transformerCount': transformers.length,
      },
    );

    try {
      // Strategy 1: Process fragments individually as fallback
      final results = <FragmentDefinitionNode>[];

      for (var i = 0; i < fragments.length; i++) {
        try {
          final fragment = fragments[i];
          var transformed = fragment;

          for (final transformer in transformers) {
            if (_canTransformerHandleFragment(transformer)) {
              transformed = _applyTransformerToFragment(
                transformed,
                transformer,
              );
            }
          }

          results.add(transformed);
        } on Exception catch (individualError) {
          _logError(
            'Individual fragment processing failed during recovery',
            individualError,
            context: {
              'fragmentIndex': i,
              'fragmentName': fragments[i].name.value,
            },
          );

          // Use original fragment as fallback
          results.add(fragments[i]);
        }
      }

      _metrics.successfulRecoveries++;
      _logDebug(
        'Fragment recovery successful',
        context: {
          'recoveredFragments': results.length,
        },
      );

      return results;
    } on Exception catch (recoveryError) {
      _logError('Fragment recovery failed', recoveryError);

      // Final fallback: return original fragments
      _logDebug('Using original fragments as final fallback');
      return fragments;
    }
  }

  // AppendTypename-specific methods

  /// Check if any transformer in the list is an AppendTypename transformer
  bool _hasAppendTypenameTransformer(List<TransformingVisitor> transformers) {
    return transformers.any((transformer) => transformer is AppendTypename);
  }

  /// Get the AppendTypename transformer from the list
  AppendTypename? _getAppendTypenameTransformer(
    List<TransformingVisitor> transformers,
  ) {
    return transformers.whereType<AppendTypename>().firstOrNull;
  }

  /// Process documents batch with AppendTypename transformation
  /// Implements specialized processing path when AppendTypename is present
  /// Ensures proper sequencing when AppendTypename is combined with other transformers
  Future<List<DocumentNode>> _processBatchWithAppendTypename(
    List<DocumentNode> documents,
    List<TransformingVisitor> transformers,
  ) async {
    _logDebug(
      'Processing batch with AppendTypename',
      context: {
        'documentCount': documents.length,
        'transformerCount': transformers.length,
      },
    );

    final results = <DocumentNode>[];
    final failedDocuments = <String>[];

    // Separate AppendTypename transformers from others for proper sequencing
    final appendTypenameTransformers = transformers
        .whereType<AppendTypename>()
        .toList();
    final otherTransformers = transformers
        .where((t) => t is! AppendTypename)
        .toList();

    for (var i = 0; i < documents.length; i++) {
      final doc = documents[i];
      final documentName = 'document_$i';

      try {
        final docKey = _generateDocumentKey(doc);
        final cacheKey = '$docKey|${_generateTransformersKey(transformers)}';

        // Check AppendTypename-specific cache
        if (_appendTypenameCache.containsKey(cacheKey)) {
          _metrics.cacheHits++;
          results.add(_appendTypenameCache[cacheKey]!);
          continue;
        }

        _metrics.cacheMisses++;

        // Apply transformations with proper sequencing:
        // 1. Apply other transformers first
        // 2. Apply AppendTypename transformers last to ensure they work on the final structure
        var transformed = doc;

        // Apply non-AppendTypename transformers first
        for (final transformer in otherTransformers) {
          try {
            transformed = _applyTransformerToDocument(transformed, transformer);
          } catch (e) {
            throw AppendTypenameProcessingError(
              'Failed to apply transformer ${transformer.runtimeType}',
              documentName: documentName,
              originalError: e,
            );
          }
        }

        // Apply AppendTypename transformers last
        for (final transformer in appendTypenameTransformers) {
          try {
            transformed = _applyTransformerToDocument(transformed, transformer);
          } catch (e) {
            throw AppendTypenameProcessingError(
              'Failed to apply AppendTypename transformer',
              documentName: documentName,
              originalError: e,
            );
          }
        }

        // Validate transformation result
        _validateTransformationCorrectness(
          doc,
          transformed,
          transformers,
          documentName,
        );

        _appendTypenameCache[cacheKey] = transformed;
        results.add(transformed);
      } on Exception catch (e) {
        failedDocuments.add(documentName);
        _logError(
          'Failed to process document with AppendTypename',
          e,
          context: {
            'documentName': documentName,
            'documentIndex': i,
          },
        );

        // For individual document failures, add original document and continue
        // This allows partial batch success
        results.add(doc);
      }
    }

    if (failedDocuments.isNotEmpty) {
      _logError(
        'Some documents failed AppendTypename processing',
        null,
        context: {
          'failedDocuments': failedDocuments,
          'totalDocuments': documents.length,
        },
      );
    }

    return results;
  }

  /// Process fragments batch with AppendTypename transformation
  /// Ensures fragment processing maintains consistency with document processing
  /// Adds proper error handling for fragment transformation failures
  Future<List<FragmentDefinitionNode>> _processFragmentsBatchWithAppendTypename(
    List<FragmentDefinitionNode> fragments,
    List<TransformingVisitor> transformers,
  ) async {
    _logDebug(
      'Processing fragments batch with AppendTypename',
      context: {
        'fragmentCount': fragments.length,
        'transformerCount': transformers.length,
      },
    );

    final results = <FragmentDefinitionNode>[];
    final failedFragments = <String>[];

    // Separate AppendTypename transformers from others for proper sequencing
    final appendTypenameTransformers = transformers
        .whereType<AppendTypename>()
        .toList();
    final otherTransformers = transformers
        .where((t) => t is! AppendTypename)
        .toList();

    for (var i = 0; i < fragments.length; i++) {
      final fragment = fragments[i];
      final fragmentName = fragment.name.value;

      try {
        final fragmentKey = _generateFragmentKey(fragment);
        final cacheKey =
            '$fragmentKey|${_generateTransformersKey(transformers)}';

        // Check fragment AppendTypename-specific cache
        if (_fragmentAppendTypenameCache.containsKey(cacheKey)) {
          _metrics.cacheHits++;
          results.add(_fragmentAppendTypenameCache[cacheKey]!);
          continue;
        }

        _metrics.cacheMisses++;

        // Apply transformations with proper sequencing to maintain consistency with document processing
        var transformed = fragment;

        // Apply non-AppendTypename transformers first
        for (final transformer in otherTransformers) {
          // Only apply transformers that can handle fragments
          if (_canTransformerHandleFragment(transformer)) {
            try {
              transformed = _applyTransformerToFragment(
                transformed,
                transformer,
              );
            } catch (e) {
              throw AppendTypenameProcessingError(
                'Failed to apply transformer ${transformer.runtimeType} to fragment',
                fragmentName: fragmentName,
                originalError: e,
              );
            }
          }
        }

        // Apply AppendTypename transformers last to ensure they work on the final structure
        for (final transformer in appendTypenameTransformers) {
          try {
            transformed = _applyTransformerToFragment(transformed, transformer);
          } catch (e) {
            throw AppendTypenameProcessingError(
              'Failed to apply AppendTypename transformer to fragment',
              fragmentName: fragmentName,
              originalError: e,
            );
          }
        }

        // Validate fragment transformation result
        if (enableValidation) {
          _validateFragmentTransformationResult(
            fragment,
            transformed,
            transformers,
          );
        }

        _fragmentAppendTypenameCache[cacheKey] = transformed;
        results.add(transformed);
      } on Exception catch (e) {
        failedFragments.add(fragmentName);
        _logError(
          'Failed to process fragment with AppendTypename',
          e,
          context: {
            'fragmentName': fragmentName,
            'fragmentIndex': i,
          },
        );

        // For individual fragment failures, add original fragment and continue
        // This allows partial batch success
        results.add(fragment);
      }
    }

    if (failedFragments.isNotEmpty) {
      _logError(
        'Some fragments failed AppendTypename processing',
        null,
        context: {
          'failedFragments': failedFragments,
          'totalFragments': fragments.length,
        },
      );
    }

    return results;
  }

  /// Generate a cache key for a fragment
  String _generateFragmentKey(FragmentDefinitionNode fragment) {
    final buffer = StringBuffer()
      ..write(
        'frag:${fragment.name.value}:${fragment.typeCondition.on.name.value}:',
      );
    _appendSelectionSetToBuffer(buffer, fragment.selectionSet);
    return buffer.toString().hashCode.toString();
  }

  /// Generate a cache key for transformers
  String _generateTransformersKey(List<TransformingVisitor> transformers) {
    return transformers
        .map((t) => '${t.runtimeType}${_getTransformerParams(t)}')
        .join(',');
  }

  /// Get transformer-specific parameters for cache key generation
  String _getTransformerParams(TransformingVisitor transformer) {
    if (transformer is AppendTypename) {
      return ':${transformer.typeName}';
    }
    return '';
  }

  /// Check if a transformer can handle fragment nodes
  /// Most transformers work on documents, but some like AppendTypename work on fragments too
  bool _canTransformerHandleFragment(TransformingVisitor transformer) {
    // AppendTypename specifically handles fragments
    if (transformer is AppendTypename) {
      return true;
    }

    // For other transformers, we need to check if they have fragment-specific methods
    // This is a conservative approach - only allow known fragment-compatible transformers
    return false;
  }

  /// Apply a transformer to a fragment node
  /// Handles the actual transformation with proper error handling
  FragmentDefinitionNode _applyTransformerToFragment(
    FragmentDefinitionNode fragment,
    TransformingVisitor transformer,
  ) {
    try {
      // Create a temporary document containing just the fragment for transformation
      final tempDoc = DocumentNode(definitions: [fragment]);
      final transformedDoc = _applyTransformerToDocument(tempDoc, transformer);

      // Extract the transformed fragment from the document
      final transformedFragments = transformedDoc.definitions
          .whereType<FragmentDefinitionNode>()
          .toList();

      if (transformedFragments.isEmpty) {
        throw AppendTypenameProcessingError(
          'Transformer ${transformer.runtimeType} removed fragment during transformation',
        );
      }

      if (transformedFragments.length > 1) {
        throw AppendTypenameProcessingError(
          'Transformer ${transformer.runtimeType} created multiple fragments from single fragment',
        );
      }

      return transformedFragments.first;
    } catch (e) {
      throw AppendTypenameProcessingError(
        'Failed to apply transformer ${transformer.runtimeType} to fragment: $e',
      );
    }
  }

  /// Validate fragment transformation result
  /// Ensures the transformation maintains fragment integrity
  void _validateFragmentTransformationResult(
    FragmentDefinitionNode original,
    FragmentDefinitionNode transformed,
    List<TransformingVisitor> transformers,
  ) {
    // Ensure fragment name is preserved
    if (original.name.value != transformed.name.value) {
      throw TransformationInconsistencyError(
        'Fragment name changed during transformation: ${original.name.value} -> ${transformed.name.value}',
      );
    }

    // Ensure type condition is preserved
    if (original.typeCondition.on.name.value !=
        transformed.typeCondition.on.name.value) {
      throw TransformationInconsistencyError(
        'Fragment type condition changed during transformation: ${original.typeCondition.on.name.value} -> ${transformed.typeCondition.on.name.value}',
      );
    }

    // Validate AppendTypename-specific changes
    final appendTypename = _getAppendTypenameTransformer(transformers);
    if (appendTypename != null) {
      _validateFragmentTypenameFieldsAdded(
        transformed,
        appendTypename.typeName,
      );
    }
  }

  /// Validate that typename fields were properly added to fragment
  void _validateFragmentTypenameFieldsAdded(
    FragmentDefinitionNode fragment,
    String typeNameField,
  ) {
    // Check if the fragment has the typename field in its selection set
    final hasTypenameField = fragment.selectionSet.selections
        .whereType<FieldNode>()
        .any((field) => field.name.value == typeNameField);

    if (!hasTypenameField) {
      throw AppendTypenameProcessingError(
        'Expected typename field "$typeNameField" not found in fragment "${fragment.name.value}"',
      );
    }
  }

  // Private methods

  Future<List<DocumentNode>> _processBatchImmediate(
    List<DocumentNode> documents,
    List<TransformingVisitor> transformers,
  ) async {
    // Optimized batch processing: apply all transformers in a single traversal
    final results = <DocumentNode>[];

    for (final doc in documents) {
      final docKey = _generateDocumentKey(doc);

      // Check individual document cache
      if (_transformCache.containsKey(docKey)) {
        results.add(_transformCache[docKey]!);
        continue;
      }

      // Apply all transformations in sequence
      var transformed = doc;
      for (final transformer in transformers) {
        transformed = _applyTransformerToDocument(transformed, transformer);
      }

      // Recreate document to ensure growable definitions
      final finalDoc = DocumentNode(
        definitions: List.from(transformed.definitions),
        span: transformed.span,
      );

      _transformCache[docKey] = finalDoc;
      results.add(finalDoc);
    }

    return results;
  }

  List<DocumentNode> _queueForLazyEvaluation(
    List<DocumentNode> documents,
    List<TransformingVisitor> transformers,
  ) {
    // Create placeholder results and queue for later processing
    final placeholders = <DocumentNode>[];

    for (final doc in documents) {
      final deferred = _DeferredTransformation(
        document: doc,
        transformers: transformers,
        placeholder: doc, // Use original as placeholder
      );

      _deferredQueue.add(deferred);
      placeholders.add(doc);
    }

    return placeholders;
  }

  bool _shouldDeferTransformation(List<TransformingVisitor> transformers) {
    // Defer transformation for complex operations or when queue is not full
    return transformers.length > 1 || _deferredQueue.length < 10;
  }

  Future<void> _processTransformationGroup(
    List<_DeferredTransformation> group,
  ) async {
    for (final deferred in group) {
      final docKey = _generateDocumentKey(deferred.document);

      if (!_transformCache.containsKey(docKey)) {
        var transformed = deferred.document;
        for (final transformer in deferred.transformers) {
          transformed = _applyTransformerToDocument(transformed, transformer);
        }

        final finalDoc = DocumentNode(
          definitions: List.from(transformed.definitions),
          span: transformed.span,
        );

        _transformCache[docKey] = finalDoc;
      }
    }
  }

  String _generateBatchKey(
    List<DocumentNode> documents,
    List<TransformingVisitor> transformers,
  ) {
    final docHashes = documents.map(_generateDocumentKey).join(',');
    final transformerTypes = transformers
        .map((t) => t.runtimeType.toString())
        .join(',');
    return '$docHashes|$transformerTypes';
  }

  String _generateDocumentKey(DocumentNode document) {
    // Generate a unique hash based on document structure and content
    final buffer = StringBuffer();

    for (final definition in document.definitions) {
      if (definition is OperationDefinitionNode) {
        buffer.write(
          'op:${definition.type}:${definition.name?.value ?? 'unnamed'}:',
        );
        _appendSelectionSetToBuffer(buffer, definition.selectionSet);
      } else if (definition is FragmentDefinitionNode) {
        buffer.write(
          'frag:${definition.name.value}:${definition.typeCondition.on.name.value}:',
        );
        _appendSelectionSetToBuffer(buffer, definition.selectionSet);
      } else {
        buffer.write('def:${definition.runtimeType}:');
      }
    }

    return buffer.toString().hashCode.toString();
  }

  /// Helper method to append selection set content to buffer for key generation
  void _appendSelectionSetToBuffer(
    StringBuffer buffer,
    SelectionSetNode selectionSet,
  ) {
    for (final selection in selectionSet.selections) {
      if (selection is FieldNode) {
        buffer.write('field:${selection.name.value}');
        if (selection.alias != null) {
          buffer.write(':alias:${selection.alias!.value}');
        }
        if (selection.selectionSet != null) {
          buffer.write(':nested:');
          _appendSelectionSetToBuffer(buffer, selection.selectionSet!);
        }
        buffer.write(';');
      } else if (selection is FragmentSpreadNode) {
        buffer.write('spread:${selection.name.value};');
      } else if (selection is InlineFragmentNode) {
        buffer.write(
          'inline:${selection.typeCondition?.on.name.value ?? 'any'}:',
        );
        _appendSelectionSetToBuffer(buffer, selection.selectionSet);
        buffer.write(';');
      }
    }
  }

  /// Apply a transformer to a document using the visitor pattern
  DocumentNode _applyTransformerToDocument(
    DocumentNode document,
    TransformingVisitor transformer,
  ) {
    // Create a new document with transformed definitions
    final transformedDefinitions = <DefinitionNode>[];

    for (final definition in document.definitions) {
      if (definition is OperationDefinitionNode) {
        transformedDefinitions.add(
          transformer.visitOperationDefinitionNode(definition),
        );
      } else if (definition is FragmentDefinitionNode) {
        transformedDefinitions.add(
          transformer.visitFragmentDefinitionNode(definition),
        );
      } else {
        transformedDefinitions.add(definition);
      }
    }

    return DocumentNode(
      definitions: transformedDefinitions,
      span: document.span,
    );
  }
}

/// Represents a transformation that has been deferred for lazy evaluation
class _DeferredTransformation {
  _DeferredTransformation({
    required this.document,
    required this.transformers,
    required this.placeholder,
  });

  final DocumentNode document;
  final List<TransformingVisitor> transformers;
  final DocumentNode placeholder;
}
