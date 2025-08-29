import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';

import './generator.dart';
import './generator/print_helpers.dart';
import './schema/schema_options.dart';
import 'generator/data/library_definition.dart';
import 'generator/errors.dart';
import 'transformer/add_typename_transformer.dart';
import 'optimization/batched_ast_processor.dart';
import 'optimization/streaming_file_processor.dart';

/// [GraphQLQueryBuilder] instance, to be used by `build_runner`.
GraphQLQueryBuilder graphQLQueryBuilder(BuilderOptions options) =>
    GraphQLQueryBuilder(options);

String _addGqlExtensionToPathIfNeeded(String path) {
  if (!path.endsWith('.gql.dart')) {
    return path.replaceAll(RegExp(r'\.dart$'), '.gql.dart');
  }
  return path;
}

/// Cached output with input hash for validation
class _CachedOutput {
  final String inputHash;
  final _SchemaProcessingResult result;

  _CachedOutput({
    required this.inputHash,
    required this.result,
  });
}

/// Result of processing a single schema mapping
class _SchemaProcessingResult {
  final AssetId outputFileId;
  final String content;
  final AssetId? forwarderOutputFileId;
  final String? forwarderContent;
  final LibraryDefinition libDefinition;

  _SchemaProcessingResult({
    required this.outputFileId,
    required this.content,
    this.forwarderOutputFileId,
    this.forwarderContent,
    required this.libDefinition,
  });
}

/// Detects the GraphQL operation type from a file path
/// Returns 'query', 'mutation', 'subscription', or 'model'
String _getOperationTypeFromFile(String filePath) {
  try {
    final content = File(filePath).readAsStringSync();

    // Simple regex to find operation type
    final queryMatch =
        RegExp(r'^\s*query\s+', multiLine: true).hasMatch(content);
    final mutationMatch =
        RegExp(r'^\s*mutation\s+', multiLine: true).hasMatch(content);
    final subscriptionMatch =
        RegExp(r'^\s*subscription\s+', multiLine: true).hasMatch(content);

    if (queryMatch) return 'query';
    if (mutationMatch) return 'mutation';
    if (subscriptionMatch) return 'subscription';

    return 'model';
  } catch (e) {
    return 'model';
  }
}

/// Replaces the operation pattern in filename with detected operation type
/// Example: 'file.query.graphql' with detected 'mutation' becomes 'file.mutation.graphql'
/// If no operation pattern exists, injects the operation type before the file extension
/// Example: 'file.graphql' with detected 'query' becomes 'file.query.graphql'
String _replaceOperationPatternInFilename(
    String filename, String detectedOperationType) {
  // Pattern to match .query., .mutation., .subscription., or .model. in filename
  // Also match optional .graphql extension after the operation type
  final operationPattern =
      RegExp(r'\.(query|mutation|subscription|model)(\.(graphql))?');

  if (operationPattern.hasMatch(filename)) {
    // Replace the entire matched pattern with just the operation type
    final result =
        filename.replaceAll(operationPattern, '.$detectedOperationType');
    return result;
  }

  // If no pattern found, inject operation type before the file extension
  // Handle .graphql extension specifically - remove .graphql and add operation type
  if (filename.endsWith('.graphql')) {
    return filename.replaceAll('.graphql', '.$detectedOperationType');
  }

  // For other extensions, inject before the last dot
  final lastDotIndex = filename.lastIndexOf('.');
  if (lastDotIndex != -1) {
    return '${filename.substring(0, lastDotIndex)}.$detectedOperationType${filename.substring(lastDotIndex)}';
  }

  // If no extension, just append the operation type
  return '$filename.$detectedOperationType';
}

/// Generate automatic output path when output is null
/// Takes queries_glob path, detects operation type, and creates output in __generated__ folder
String _generateAutoOutputPath(
    String queriesGlob, String detectedOperationType) {
  final uri = Uri.parse(queriesGlob);
  final pathSegments = uri.pathSegments.toList();

  // Remove the last segment (filename) and go up one level
  if (pathSegments.isNotEmpty) {
    pathSegments.removeLast(); // Remove filename
    if (pathSegments.isNotEmpty) {
      pathSegments.removeLast(); // Go up one directory level
    }
  }

  // Add __generated__ folder (lib/ prefix is added automatically by build system)
  final outputSegments = ['__generated__'];

  // Extract filename from original queries_glob
  final originalFilename = uri.pathSegments.last;

  // Replace operation pattern in filename with detected type
  final updatedFilename = _replaceOperationPatternInFilename(
      originalFilename, detectedOperationType);

  // Add .dart extension
  final outputFilename = '$updatedFilename.dart';
  outputSegments.add(outputFilename);
  pathSegments.removeAt(0);
  outputSegments.insertAll(0, pathSegments);
  return outputSegments.join('/');
}

List<String> _builderOptionsToExpectedOutputs(BuilderOptions builderOptions) {
  final schemaMapping =
      GeneratorOptions.fromJson(builderOptions.config).schemaMapping;

  if (schemaMapping.isEmpty) {
    throw MissingBuildConfigurationException('schema_mapping');
  }

  return schemaMapping
      .map((s) {
        if (s.queriesGlob == null) {
          throw MissingBuildConfigurationException(
              'schema_mapping => queries_glob required');
        }

        // Generate paths for all possible operation types since we detect at build time
        final operationTypes = ['query', 'mutation', 'subscription', 'model'];
        return operationTypes.map((operationType) {
          final outputPath =
              _generateAutoOutputPath(s.queriesGlob!, operationType);
          // Don't remove lib/ prefix since _generateAutoOutputPath doesn't include it
          return _addGqlExtensionToPathIfNeeded(outputPath);
        }).toList();
      })
      .expand((e) => e)
      .toSet() // Remove duplicates
      .toList();
}

/// Main Dartpollo builder.
class GraphQLQueryBuilder implements Builder {
  /// Creates a builder from [BuilderOptions].
  GraphQLQueryBuilder(BuilderOptions builderOptions)
      : options = GeneratorOptions.fromJson(builderOptions.config),
        expectedOutputs = _builderOptionsToExpectedOutputs(builderOptions);

  /// This generator options, gathered from `build.yaml` file.
  final GeneratorOptions options;

  /// List FragmentDefinitionNode in fragments_glob.
  // List<FragmentDefinitionNode> fragmentsCommon = [];

  /// The generated output file.
  final List<String> expectedOutputs;

  /// Callback fired when the generator processes a [QueryDefinition].
  OnBuildQuery? onBuild;

  /// Cache for file contents to avoid redundant reads
  final Map<String, List<DocumentNode>> _fileCache = {};

  /// Cache for content hashes to track file changes
  final Map<String, String> _contentHashCache = {};

  /// Cache for generated outputs to avoid regeneration
  final Map<String, _CachedOutput> _outputCache = {};

  /// Batched AST processor for optimized transformations
  final BatchedASTProcessor _astProcessor = BatchedASTProcessor();

  /// Streaming file processor for large file handling
  final StreamingFileProcessor _streamingProcessor = StreamingFileProcessor();

  @override
  Map<String, List<String>> get buildExtensions => {
        r'$lib$': expectedOutputs,
      };

  /// Get comprehensive performance statistics from all optimization components
  Map<String, dynamic> getPerformanceStats() {
    return {
      'astProcessor': _astProcessor.getCacheStats(),
      'streamingProcessor': _streamingProcessor.getMemoryStats(),
      'cacheStats': {
        'fileCacheSize': _fileCache.length,
        'contentHashCacheSize': _contentHashCache.length,
        'outputCacheSize': _outputCache.length,
      },
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Clear all caches and reset performance statistics
  void clearAllCaches() {
    _fileCache.clear();
    _contentHashCache.clear();
    _outputCache.clear();
    _astProcessor.clearCaches();
    _streamingProcessor.reset();
  }

  /// read asset files
  Future<List<DocumentNode>> readGraphQlFiles(
    BuildStep buildStep,
    String schema,
  ) async {
    final schemaAssetStream = buildStep.findAssets(Glob(schema));

    return await schemaAssetStream
        .asyncMap(
          (asset) async => parseString(
            await buildStep.readAsString(asset),
            url: asset.path,
          ),
        )
        .toList();
  }

  /// Compute content hash for a set of files matching a glob pattern
  Future<String> _computeContentHash(
      BuildStep buildStep, String globPattern) async {
    final assets = await buildStep.findAssets(Glob(globPattern)).toList();
    final contents = <String>[];

    for (final asset in assets) {
      final content = await buildStep.readAsString(asset);
      contents.add('${asset.path}:$content');
    }

    // Sort to ensure consistent hash regardless of file order
    contents.sort();
    final combinedContent = contents.join('|');
    final bytes = utf8.encode(combinedContent);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }

  /// read asset files with caching and hash-based validation
  /// Uses streaming processing for large files automatically
  Future<List<DocumentNode>> readGraphQlFilesWithCache(
    BuildStep buildStep,
    String schema,
  ) async {
    // Compute current content hash
    final currentHash = await _computeContentHash(buildStep, schema);

    // Check if we have cached content and if hash matches
    if (_fileCache.containsKey(schema) &&
        _contentHashCache.containsKey(schema) &&
        _contentHashCache[schema] == currentHash) {
      return _fileCache[schema]!;
    }

    // Get asset IDs for the schema pattern
    final assetIds = await buildStep.findAssets(Glob(schema)).toList();

    // Use streaming processor for multiple files or potentially large files
    List<DocumentNode> documents;
    if (assetIds.length > 1) {
      // Process multiple files with streaming optimization
      documents = await _streamingProcessor.processMultipleFiles(
        buildStep,
        assetIds,
        enableMemoryMonitoring: true,
      );
    } else if (assetIds.isNotEmpty) {
      // Process single file with streaming if large
      documents = await _streamingProcessor.processLargeFile(
        buildStep,
        assetIds.first,
        enableMemoryMonitoring: true,
      );
    } else {
      // Fallback to regular processing if no assets found
      documents = await readGraphQlFiles(buildStep, schema);
    }

    // Cache the results and hash
    _fileCache[schema] = documents;
    _contentHashCache[schema] = currentHash;

    return documents;
  }

  /// Process a single schema mapping
  Future<_SchemaProcessingResult> _processSchemaMapping(
    BuildStep buildStep,
    SchemaMap schemaMap,
    List<FragmentDefinitionNode> fragmentsCommon,
    GeneratorOptions copyOptions,
  ) async {
    // Compute combined input hash for output caching
    final inputHashes = <String>[];

    // Add schema hash
    if (schemaMap.schema != null) {
      inputHashes.add(await _computeContentHash(buildStep, schemaMap.schema!));
    }

    // Add queries hash
    if (schemaMap.queriesGlob != null) {
      inputHashes
          .add(await _computeContentHash(buildStep, schemaMap.queriesGlob!));
    }

    // Add schema fragments hash
    if (schemaMap.fragmentsGlob != null) {
      inputHashes
          .add(await _computeContentHash(buildStep, schemaMap.fragmentsGlob!));
    }

    // Add common fragments hash (convert to string representation)
    final commonFragmentsStr =
        fragmentsCommon.map((f) => f.toString()).join('|');
    final commonFragmentsHash =
        sha256.convert(utf8.encode(commonFragmentsStr)).toString();
    inputHashes.add(commonFragmentsHash);

    // Add options hash
    final optionsStr = '${copyOptions.toString()}|${schemaMap.toString()}';
    final optionsHash = sha256.convert(utf8.encode(optionsStr)).toString();
    inputHashes.add(optionsHash);

    // Combine all hashes
    final combinedHash =
        sha256.convert(utf8.encode(inputHashes.join('|'))).toString();
    final cacheKey = schemaMap.queriesGlob ?? 'unknown';

    // Check if we have cached output with same hash
    if (_outputCache.containsKey(cacheKey) &&
        _outputCache[cacheKey]!.inputHash == combinedHash) {
      return _outputCache[cacheKey]!.result;
    }
    List<FragmentDefinitionNode> schemaCommonFragments = [
      ...fragmentsCommon,
    ];
    final schemaFragmentsGlob = schemaMap.fragmentsGlob;
    if (schemaFragmentsGlob != null) {
      final schemaFragments =
          (await readGraphQlFilesWithCache(buildStep, schemaFragmentsGlob))
              .map((e) => e.definitions.whereType<FragmentDefinitionNode>())
              .expand((e) => e)
              .toList();

      if (schemaFragments.isEmpty) {
        throw MissingFilesException(schemaFragmentsGlob);
      }

      schemaCommonFragments.addAll(schemaFragments);
    }

    final queriesGlob = schemaMap.queriesGlob;
    final schema = schemaMap.schema;

    if (schema == null) {
      throw MissingBuildConfigurationException('schema_map => schema');
    }

    // Loop through all files in glob
    if (queriesGlob == null) {
      throw MissingBuildConfigurationException('schema_map => queries_glob');
    } else if (Glob(queriesGlob).matches(schema)) {
      throw QueryGlobsSchemaException();
    }

    final gqlSchema = await readGraphQlFilesWithCache(buildStep, schema);

    if (gqlSchema.isEmpty) {
      throw MissingFilesException(schema);
    }

    // Read GraphQL documents once and reuse for both operation detection and processing
    var gqlDocs = await readGraphQlFilesWithCache(buildStep, queriesGlob);

    if (gqlDocs.isEmpty) {
      throw MissingFilesException(queriesGlob);
    }

    // Always auto-generate output path with operation type detection
    final firstAsset = await buildStep.findAssets(Glob(queriesGlob)).first;
    final detectedOperationType = _getOperationTypeFromFile(firstAsset.path);
    final output = _generateAutoOutputPath(queriesGlob, detectedOperationType);

    // Apply transformations using BatchedASTProcessor for optimal performance
    final transformers = <TransformingVisitor>[];
    if (schemaMap.appendTypeName) {
      transformers.add(AppendTypename(schemaMap.typeNameField));
    }

    if (transformers.isNotEmpty) {
      // Use BatchedASTProcessor for all transformations including AppendTypename
      gqlDocs = await _astProcessor.processBatch(gqlDocs, transformers);
      schemaCommonFragments = await _astProcessor.processFragmentsBatch(
          schemaCommonFragments, transformers);
    }

    final libDefinition = generateLibrary(
      _addGqlExtensionToPathIfNeeded(output),
      gqlDocs,
      copyOptions,
      schemaMap,
      schemaCommonFragments,
      gqlSchema.first,
    );

    final buffer = StringBuffer();

    final finalOutputPath = _addGqlExtensionToPathIfNeeded(output);
    final outputFileId = AssetId(
      buildStep.inputId.package,
      'lib/$finalOutputPath', // Add lib/ prefix for build system
    );

    writeLibraryDefinitionToBuffer(
      buffer,
      copyOptions.ignoreForFile,
      libDefinition,
      copyOptions,
    );

    // No forwarder logic needed - all files use .gql.dart extension

    final result = _SchemaProcessingResult(
      outputFileId: outputFileId,
      content: buffer.toString(),
      forwarderOutputFileId: null,
      forwarderContent: null,
      libDefinition: libDefinition,
    );

    // Cache the result for future use
    _outputCache[cacheKey] = _CachedOutput(
      inputHash: combinedHash,
      result: result,
    );

    return result;
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    List<FragmentDefinitionNode> fragmentsCommon = [];

    GeneratorOptions copyOptions = options;
    if (copyOptions.convertEnumToString) {
      final copyMapping = copyOptions.schemaMapping
          .map(
            (e) => e.copyWith(
                convertEnumToString: copyOptions.convertEnumToString),
          )
          .toList();

      copyOptions = copyOptions.copyWith(
        schemaMapping: copyMapping,
      );
    }

    final fragmentsGlob = copyOptions.fragmentsGlob;
    if (fragmentsGlob != null) {
      final commonFragments =
          (await readGraphQlFilesWithCache(buildStep, fragmentsGlob))
              .map((e) => e.definitions.whereType<FragmentDefinitionNode>())
              .expand((e) => e)
              .toList();

      if (commonFragments.isEmpty) {
        throw MissingFilesException(fragmentsGlob);
      }

      fragmentsCommon.addAll(commonFragments);
    }

    // Process all schema mappings in parallel
    final futures = copyOptions.schemaMapping.map((schemaMap) async {
      return await _processSchemaMapping(
          buildStep, schemaMap, fragmentsCommon, copyOptions);
    });

    final results = await Future.wait(futures);

    // Write all outputs
    for (final result in results) {
      if (onBuild != null) {
        onBuild!(result.libDefinition);
      }

      await buildStep.writeAsString(result.outputFileId, result.content);
      // No forwarder files to write
    }
  }
}
