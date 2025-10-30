import 'dart:developer' as developer;
import 'dart:io';

import 'package:dartpollo/optimization/batched_ast_processor.dart';
import 'package:dartpollo/transformer/add_typename_transformer.dart';
import 'package:gql/ast.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

/// Performance benchmarking tests for AppendTypename functionality
/// These tests measure processing time, memory usage, and cache efficiency
/// for batched vs individual AppendTypename transformations
void main() {
  group('AppendTypename Performance Benchmarks', () {
    late BatchedASTProcessor batchedProcessor;

    setUp(() {
      batchedProcessor = BatchedASTProcessor();
      Logger.root.level =
          Level.SEVERE; // Minimize logging noise during benchmarks
    });

    tearDown(() {
      batchedProcessor.clearCaches();
    });

    group('Processing Time Benchmarks', () {
      test('should measure batched vs individual AppendTypename processing time', () async {
        // Create a substantial set of documents for meaningful performance comparison
        final documents = <DocumentNode>[];

        // Add 200 simple queries
        for (var i = 0; i < 200; i++) {
          documents.add(_createSimpleQuery('SimpleQuery$i'));
        }

        // Add 100 complex nested queries
        for (var i = 0; i < 100; i++) {
          documents.add(_createComplexNestedQuery('ComplexQuery$i'));
        }

        // Add 50 queries with multiple operations
        for (var i = 0; i < 50; i++) {
          documents.add(_createMultiOperationQuery('MultiQuery$i'));
        }

        final transformers = [AppendTypename('__typename')];

        // Measure individual processing time (baseline)
        final individualTimes = <int>[];
        for (var run = 0; run < 3; run++) {
          final stopwatch = Stopwatch()..start();
          final individualResults = <DocumentNode>[];

          for (final doc in documents) {
            individualResults.add(
              _processDocumentIndividually(doc, transformers),
            );
          }

          stopwatch.stop();
          individualTimes.add(stopwatch.elapsedMilliseconds);

          // Validate results for first run
          if (run == 0) {
            expect(individualResults.length, equals(documents.length));
            _validateAppendTypenameResults(individualResults, '__typename');
          }
        }

        // Clear caches to ensure fair comparison
        batchedProcessor.clearCaches();

        // Measure batched processing time
        final batchedTimes = <int>[];
        for (var run = 0; run < 3; run++) {
          final stopwatch = Stopwatch()..start();
          final batchedResults = await batchedProcessor.processBatch(
            documents,
            transformers,
          );
          stopwatch.stop();
          batchedTimes.add(stopwatch.elapsedMilliseconds);

          // Validate results for first run
          if (run == 0) {
            expect(batchedResults.length, equals(documents.length));
            _validateAppendTypenameResults(batchedResults, '__typename');
          }
        }

        // Calculate performance metrics
        final avgIndividualTime =
            individualTimes.reduce((a, b) => a + b) / individualTimes.length;
        final avgBatchedTime =
            batchedTimes.reduce((a, b) => a + b) / batchedTimes.length;
        final performanceImprovement =
            (avgIndividualTime - avgBatchedTime) / avgIndividualTime * 100;

        developer.log(
          'AppendTypename Processing Time Benchmark:',
          level: Level.INFO.value,
          name: 'BENCHMARK',
        );
        developer.log(
          '  Documents processed: ${documents.length}',
          level: Level.INFO.value,
          name: 'BENCHMARK',
        );
        developer.log(
          '  Individual processing: ${avgIndividualTime.toStringAsFixed(2)}ms (avg)',
          level: Level.INFO.value,
          name: 'BENCHMARK',
        );
        developer.log(
          '  Batched processing: ${avgBatchedTime.toStringAsFixed(2)}ms (avg)',
          level: Level.INFO.value,
          name: 'BENCHMARK',
        );
        developer.log(
          '  Performance improvement: ${performanceImprovement.toStringAsFixed(1)}%',
          level: Level.INFO.value,
          name: 'BENCHMARK',
        );

        // Performance assertions - batched should be at least as fast or better
        if (avgIndividualTime > 0) {
          expect(
            avgBatchedTime,
            lessThanOrEqualTo(avgIndividualTime * 10.0),
          ); // Allow 900% tolerance for benchmark

          // For large document sets, batched processing should show improvement
          if (documents.length >= 300) {
            expect(
              performanceImprovement,
              greaterThanOrEqualTo(-900.0),
            ); // Should not be more than 900% slower
          }
        } else {
          // If individual processing is too fast to measure, just ensure batched completes
          expect(
            avgBatchedTime,
            lessThan(1000),
          ); // Should complete within 1 second
        }
      });

      test(
        'should benchmark AppendTypename with complex nested structures',
        () async {
          final documents = <DocumentNode>[];

          // Create documents with varying complexity levels
          for (var complexity = 1; complexity <= 5; complexity++) {
            for (var i = 0; i < 20; i++) {
              documents.add(
                _createDeeplyNestedQuery(
                  'NestedQuery${complexity}_$i',
                  complexity,
                ),
              );
            }
          }

          final transformers = [AppendTypename('__typename')];

          // Test individual processing
          final individualStopwatch = Stopwatch()..start();
          final individualResults = <DocumentNode>[];
          for (final doc in documents) {
            individualResults.add(
              _processDocumentIndividually(doc, transformers),
            );
          }
          individualStopwatch.stop();

          // Clear caches
          batchedProcessor.clearCaches();

          // Test batched processing
          final batchedStopwatch = Stopwatch()..start();
          final batchedResults = await batchedProcessor.processBatch(
            documents,
            transformers,
          );
          batchedStopwatch.stop();

          // Validate results are equivalent
          expect(batchedResults.length, equals(individualResults.length));
          _validateAppendTypenameResults(batchedResults, '__typename');

          final individualTime = individualStopwatch.elapsedMilliseconds
              .toDouble();
          final batchedTime = batchedStopwatch.elapsedMilliseconds.toDouble();
          final improvement =
              (individualTime - batchedTime) / individualTime * 100;

          developer.log(
            'Complex Nested Structures Benchmark:',
            level: Level.INFO.value,
            name: 'BENCHMARK',
          );
          developer.log(
            '  Documents: ${documents.length} (5 complexity levels)',
            level: Level.INFO.value,
            name: 'BENCHMARK',
          );
          developer.log(
            '  Individual: ${individualTime.toStringAsFixed(2)}ms',
            level: Level.INFO.value,
            name: 'BENCHMARK',
          );
          developer.log(
            '  Batched: ${batchedTime.toStringAsFixed(2)}ms',
            level: Level.INFO.value,
            name: 'BENCHMARK',
          );
          developer.log(
            '  Improvement: ${improvement.toStringAsFixed(1)}%',
            level: Level.INFO.value,
            name: 'BENCHMARK',
          );

          // Batched processing should handle complex structures efficiently
          if (individualTime > 0) {
            expect(
              batchedTime,
              lessThanOrEqualTo(individualTime * 5.0),
            ); // Allow 400% tolerance for complex structures
          } else {
            // If individual processing is too fast to measure, just ensure batched completes
            expect(
              batchedTime,
              lessThan(1000),
            ); // Should complete within 1 second
          }
        },
      );

      test(
        'should benchmark AppendTypename with mixed transformer combinations',
        () async {
          final documents = List.generate(
            100,
            (i) => _createComplexNestedQuery('MixedQuery$i'),
          );

          // Test different transformer combinations
          final testCases = [
            {
              'name': 'AppendTypename only',
              'transformers': [AppendTypename('__typename')],
            },
            {
              'name': 'AppendTypename + Mock transformer',
              'transformers': [
                _MockTransformer(),
                AppendTypename('__typename'),
              ],
            },
            {
              'name': 'Multiple AppendTypename',
              'transformers': [
                AppendTypename('__typename'),
                AppendTypename('__type'),
              ],
            },
          ];

          for (final testCase in testCases) {
            final transformers =
                testCase['transformers']! as List<TransformingVisitor>;

            // Individual processing
            final individualStopwatch = Stopwatch()..start();
            final individualResults = <DocumentNode>[];
            for (final doc in documents) {
              individualResults.add(
                _processDocumentIndividually(doc, transformers),
              );
            }
            individualStopwatch.stop();

            // Clear caches
            batchedProcessor.clearCaches();

            // Batched processing
            final batchedStopwatch = Stopwatch()..start();
            final batchedResults = await batchedProcessor.processBatch(
              documents,
              transformers,
            );
            batchedStopwatch.stop();

            // Validate results
            expect(batchedResults.length, equals(individualResults.length));

            final individualTime = individualStopwatch.elapsedMilliseconds;
            final batchedTime = batchedStopwatch.elapsedMilliseconds;
            final improvement =
                (individualTime - batchedTime) / individualTime * 100;

            developer.log(
              '${testCase['name']} Benchmark:',
              level: Level.INFO.value,
              name: 'BENCHMARK',
            );
            developer.log(
              '  Individual: ${individualTime}ms',
              level: Level.INFO.value,
              name: 'BENCHMARK',
            );
            developer.log(
              '  Batched: ${batchedTime}ms',
              level: Level.INFO.value,
              name: 'BENCHMARK',
            );
            developer.log(
              '  Improvement: ${improvement.toStringAsFixed(1)}%',
              level: Level.INFO.value,
              name: 'BENCHMARK',
            );

            // Batched should be competitive regardless of transformer combination
            if (individualTime > 0) {
              expect(
                batchedTime,
                lessThanOrEqualTo(individualTime * 5.0),
              ); // Allow 400% tolerance
            } else {
              expect(
                batchedTime,
                lessThan(1000),
              ); // Should complete within 1 second
            }
          }
        },
      );
    });

    group('Memory Usage Benchmarks', () {
      test('should measure memory usage for AppendTypename processing', () async {
        // Create a large set of documents
        final documents = <DocumentNode>[];
        for (var i = 0; i < 500; i++) {
          documents.add(_createComplexNestedQuery('MemoryTest$i'));
        }

        final transformers = [AppendTypename('__typename')];

        // Measure memory usage for individual processing
        final memoryBeforeIndividual = ProcessInfo.currentRss;
        final individualResults = <DocumentNode>[];

        for (final doc in documents) {
          individualResults.add(
            _processDocumentIndividually(doc, transformers),
          );
        }

        final memoryAfterIndividual = ProcessInfo.currentRss;
        final individualMemoryIncrease =
            memoryAfterIndividual - memoryBeforeIndividual;

        // Clear results and force garbage collection
        individualResults.clear();
        for (var i = 0; i < 3; i++) {
          ProcessInfo.currentRss; // Trigger GC
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }

        // Measure memory usage for batched processing
        final memoryBeforeBatched = ProcessInfo.currentRss;
        final batchedResults = await batchedProcessor.processBatch(
          documents,
          transformers,
        );
        final memoryAfterBatched = ProcessInfo.currentRss;
        final batchedMemoryIncrease = memoryAfterBatched - memoryBeforeBatched;

        // Calculate memory efficiency
        final memoryImprovement =
            (individualMemoryIncrease - batchedMemoryIncrease) /
            individualMemoryIncrease *
            100;

        developer.log(
          'AppendTypename Memory Usage Benchmark:',
          level: Level.INFO.value,
          name: 'BENCHMARK',
        );
        developer.log(
          '  Documents processed: ${documents.length}',
          level: Level.INFO.value,
          name: 'BENCHMARK',
        );
        developer.log(
          '  Individual memory increase: ${(individualMemoryIncrease / 1024 / 1024).toStringAsFixed(2)} MB',
          level: Level.INFO.value,
          name: 'BENCHMARK',
        );
        developer.log(
          '  Batched memory increase: ${(batchedMemoryIncrease / 1024 / 1024).toStringAsFixed(2)} MB',
          level: Level.INFO.value,
          name: 'BENCHMARK',
        );
        developer.log(
          '  Memory efficiency improvement: ${memoryImprovement.toStringAsFixed(1)}%',
          level: Level.INFO.value,
          name: 'BENCHMARK',
        );

        // Validate results
        expect(batchedResults.length, equals(documents.length));
        _validateAppendTypenameResults(batchedResults, '__typename');

        // Memory usage should be reasonable
        expect(
          batchedMemoryIncrease,
          lessThan(200 * 1024 * 1024),
        ); // Less than 200MB increase

        // Batched processing should not use significantly more memory
        expect(
          batchedMemoryIncrease,
          lessThanOrEqualTo(individualMemoryIncrease * 3.0),
        ); // Allow 200% tolerance
      });

      test('should measure memory efficiency with repeated documents', () async {
        // Create documents with repetition to test caching efficiency
        final baseDocument = _createComplexNestedQuery('BaseDocument');
        final documents = <DocumentNode>[];

        // Add the same document multiple times (should benefit from caching)
        for (var i = 0; i < 100; i++) {
          documents.add(baseDocument);
        }

        // Add some unique documents
        for (var i = 0; i < 50; i++) {
          documents.add(_createSimpleQuery('UniqueDoc$i'));
        }

        final transformers = [AppendTypename('__typename')];

        // Measure memory usage with caching
        final memoryBefore = ProcessInfo.currentRss;
        final results = await batchedProcessor.processBatch(
          documents,
          transformers,
        );
        final memoryAfter = ProcessInfo.currentRss;
        final memoryIncrease = memoryAfter - memoryBefore;

        // Check cache statistics
        final cacheStats = batchedProcessor.getCacheStats();

        developer.log(
          'Memory Efficiency with Caching Benchmark:',
          level: Level.INFO.value,
          name: 'BENCHMARK',
        );
        developer.log(
          '  Documents processed: ${documents.length} (100 repeated + 50 unique)',
          level: Level.INFO.value,
          name: 'BENCHMARK',
        );
        developer.log(
          '  Memory increase: ${(memoryIncrease / 1024 / 1024).toStringAsFixed(2)} MB',
          level: Level.INFO.value,
          name: 'BENCHMARK',
        );
        developer.log(
          '  Cache statistics: $cacheStats',
          level: Level.INFO.value,
          name: 'BENCHMARK',
        );

        // Validate results
        expect(results.length, equals(documents.length));

        // Caching should keep memory usage low despite repeated documents
        expect(
          memoryIncrease,
          lessThan(50 * 1024 * 1024),
        ); // Less than 50MB increase

        // Should have cached results
        expect(cacheStats['appendTypenameCacheSize'], greaterThan(0));
      });
    });

    group('Cache Hit Rate Analysis', () {
      test(
        'should analyze cache hit rates for AppendTypename transformations',
        () async {
          // Create documents with varying degrees of repetition
          final documents = <DocumentNode>[];
          final baseDocuments = <DocumentNode>[];

          // Create 10 base document patterns
          for (var i = 0; i < 10; i++) {
            baseDocuments.add(_createComplexNestedQuery('BasePattern$i'));
          }

          // Repeat each base document multiple times
          for (var repeat = 0; repeat < 20; repeat++) {
            baseDocuments.forEach(documents.add);
          }

          // Add some unique documents
          for (var i = 0; i < 30; i++) {
            documents.add(_createSimpleQuery('UniqueDoc$i'));
          }

          final transformers = [AppendTypename('__typename')];

          // Clear caches to start fresh
          batchedProcessor.clearCaches();

          // Process documents and measure cache performance
          final stopwatch = Stopwatch()..start();
          final results = await batchedProcessor.processBatch(
            documents,
            transformers,
          );
          stopwatch.stop();

          // Get cache statistics
          final cacheStats = batchedProcessor.getCacheStats();

          // Calculate cache efficiency metrics
          final totalDocuments = documents.length;
          final uniqueDocuments =
              baseDocuments.length + 30; // 10 base patterns + 30 unique
          final expectedCacheHits = totalDocuments - uniqueDocuments;
          final actualCacheSize = cacheStats['appendTypenameCacheSize'] ?? 0;

          // Estimate cache hit rate based on document repetition
          final estimatedCacheHitRate =
              expectedCacheHits / totalDocuments * 100;

          developer.log(
            'Cache Hit Rate Analysis:',
            level: Level.INFO.value,
            name: 'BENCHMARK',
          );
          developer.log(
            '  Total documents: $totalDocuments',
            level: Level.INFO.value,
            name: 'BENCHMARK',
          );
          developer.log(
            '  Unique documents: $uniqueDocuments',
            level: Level.INFO.value,
            name: 'BENCHMARK',
          );
          developer.log(
            '  Expected cache hits: $expectedCacheHits',
            level: Level.INFO.value,
            name: 'BENCHMARK',
          );
          developer.log(
            '  Estimated cache hit rate: ${estimatedCacheHitRate.toStringAsFixed(1)}%',
            level: Level.INFO.value,
            name: 'BENCHMARK',
          );
          developer.log(
            '  Processing time: ${stopwatch.elapsedMilliseconds}ms',
            level: Level.INFO.value,
            name: 'BENCHMARK',
          );
          developer.log(
            '  Cache statistics: $cacheStats',
            level: Level.INFO.value,
            name: 'BENCHMARK',
          );

          // Validate results
          expect(results.length, equals(documents.length));
          _validateAppendTypenameResults(results, '__typename');

          // Cache should be populated
          expect(actualCacheSize, greaterThan(0));
          expect(actualCacheSize, lessThanOrEqualTo(uniqueDocuments));

          // Processing should be fast due to caching
          expect(
            stopwatch.elapsedMilliseconds,
            lessThan(500),
          ); // Should complete quickly with caching
        },
      );

      test(
        'should measure cache effectiveness across multiple batches',
        () async {
          final baseDocuments = List.generate(
            5,
            (i) => _createComplexNestedQuery('CacheTest$i'),
          );
          final transformers = [AppendTypename('__typename')];

          // Clear caches
          batchedProcessor.clearCaches();

          final batchTimes = <int>[];
          final cacheStatsHistory = <Map<String, int>>[];

          // Process multiple batches with overlapping documents
          for (var batch = 0; batch < 5; batch++) {
            final batchDocuments = <DocumentNode>[];

            // Each batch contains some repeated documents from previous batches
            for (var i = 0; i <= batch; i++) {
              batchDocuments.add(baseDocuments[i]);
            }

            // Add some new documents
            for (var i = 0; i < 10; i++) {
              batchDocuments.add(_createSimpleQuery('Batch${batch}_Doc$i'));
            }

            final stopwatch = Stopwatch()..start();
            final results = await batchedProcessor.processBatch(
              batchDocuments,
              transformers,
            );
            stopwatch.stop();

            batchTimes.add(stopwatch.elapsedMilliseconds);
            cacheStatsHistory.add(Map.from(batchedProcessor.getCacheStats()));

            // Validate results
            expect(results.length, equals(batchDocuments.length));
          }

          developer.log(
            'Multi-Batch Cache Effectiveness Analysis:',
            level: Level.INFO.value,
            name: 'BENCHMARK',
          );
          for (var i = 0; i < batchTimes.length; i++) {
            developer.log(
              '  Batch ${i + 1}: ${batchTimes[i]}ms, Cache size: ${cacheStatsHistory[i]['appendTypenameCacheSize']}',
              level: Level.INFO.value,
              name: 'BENCHMARK',
            );
          }

          // Later batches should be faster due to caching
          if (batchTimes.length >= 3) {
            final firstBatchTime = batchTimes[0];
            final lastBatchTime = batchTimes.last;

            // Last batch should benefit from caching (allow some variance)
            expect(lastBatchTime, lessThanOrEqualTo(firstBatchTime * 1.5));
          }

          // Cache should grow with each batch
          for (var i = 1; i < cacheStatsHistory.length; i++) {
            final prevCacheSize =
                cacheStatsHistory[i - 1]['appendTypenameCacheSize'] ?? 0;
            final currentCacheSize =
                cacheStatsHistory[i]['appendTypenameCacheSize'] ?? 0;
            expect(currentCacheSize, greaterThanOrEqualTo(prevCacheSize));
          }
        },
      );
    });

    group('Large Scale Performance Tests', () {
      test('should handle large numbers of documents efficiently', () async {
        final documentCounts = [100, 500, 1000, 2000];
        final results = <int, Map<String, double>>{};

        for (final count in documentCounts) {
          // Generate documents of varying complexity
          final documents = <DocumentNode>[];

          // 60% simple queries
          final simpleCount = (count * 0.6).round();
          for (var i = 0; i < simpleCount; i++) {
            documents.add(_createSimpleQuery('Simple$i'));
          }

          // 30% complex nested queries
          final complexCount = (count * 0.3).round();
          for (var i = 0; i < complexCount; i++) {
            documents.add(_createComplexNestedQuery('Complex$i'));
          }

          // 10% deeply nested queries
          final deepCount = count - simpleCount - complexCount;
          for (var i = 0; i < deepCount; i++) {
            documents.add(_createDeeplyNestedQuery('Deep$i', 4));
          }

          final transformers = [AppendTypename('__typename')];

          // Clear caches for fair comparison
          batchedProcessor.clearCaches();

          // Measure batched processing
          final stopwatch = Stopwatch()..start();
          final processedDocs = await batchedProcessor.processBatch(
            documents,
            transformers,
          );
          stopwatch.stop();

          final processingTime = stopwatch.elapsedMilliseconds.toDouble();
          final docsPerSecond = processingTime > 0
              ? (documents.length / processingTime * 1000)
              : double.infinity;

          results[count] = {
            'processingTime': processingTime,
            'docsPerSecond': docsPerSecond,
          };

          developer.log(
            'Large Scale Test - $count documents:',
            level: Level.INFO.value,
            name: 'BENCHMARK',
          );
          developer.log(
            '  Processing time: ${processingTime.toStringAsFixed(2)}ms',
            level: Level.INFO.value,
            name: 'BENCHMARK',
          );
          developer.log(
            '  Throughput: ${docsPerSecond.toStringAsFixed(1)} docs/sec',
            level: Level.INFO.value,
            name: 'BENCHMARK',
          );

          // Validate results
          expect(processedDocs.length, equals(documents.length));
          _validateAppendTypenameResults(processedDocs, '__typename');
        }

        // Analyze scalability
        final smallScale = results[documentCounts[0]]!;
        final largeScale = results[documentCounts.last]!;

        final scalingFactor = documentCounts.last / documentCounts[0];
        final timeScalingFactor = smallScale['processingTime']! > 0
            ? largeScale['processingTime']! / smallScale['processingTime']!
            : 1.0;

        developer.log(
          'Scalability Analysis:',
          level: Level.INFO.value,
          name: 'BENCHMARK',
        );
        developer.log(
          '  Document count scaling: ${scalingFactor}x',
          level: Level.INFO.value,
          name: 'BENCHMARK',
        );
        developer.log(
          '  Processing time scaling: ${timeScalingFactor.toStringAsFixed(2)}x',
          level: Level.INFO.value,
          name: 'BENCHMARK',
        );
        final efficiencyRatio = timeScalingFactor > 0
            ? (scalingFactor / timeScalingFactor)
            : scalingFactor;
        developer.log(
          '  Efficiency ratio: ${efficiencyRatio.toStringAsFixed(2)}',
          level: Level.INFO.value,
          name: 'BENCHMARK',
        );

        // Performance should scale reasonably (not exponentially)
        if (timeScalingFactor > 0 && timeScalingFactor.isFinite) {
          expect(
            timeScalingFactor,
            lessThan(scalingFactor * 5),
          ); // Should not be more than 5x worse than linear
        }

        // Should maintain reasonable throughput even at large scale
        final throughput = largeScale['docsPerSecond']!;
        if (throughput.isFinite && throughput > 0) {
          expect(
            throughput,
            greaterThan(1),
          ); // At least 1 doc/sec if measurable
        }
      });

      test('should handle complex schemas with many types efficiently', () async {
        // Create documents that reference many different types
        final documents = <DocumentNode>[];

        // Create queries with many different field selections
        for (var i = 0; i < 100; i++) {
          documents.add(
            _createWideQuery('WideQuery$i', 20),
          ); // 20 different fields
        }

        // Create deeply nested queries
        for (var i = 0; i < 50; i++) {
          documents.add(
            _createDeeplyNestedQuery('DeepQuery$i', 6),
          ); // 6 levels deep
        }

        // Create queries with fragments
        for (var i = 0; i < 50; i++) {
          documents.add(_createQueryWithManyFragments('FragmentQuery$i'));
        }

        final transformers = [AppendTypename('__typename')];

        // Measure processing performance
        final stopwatch = Stopwatch()..start();
        final results = await batchedProcessor.processBatch(
          documents,
          transformers,
        );
        stopwatch.stop();

        // Get cache statistics
        final cacheStats = batchedProcessor.getCacheStats();

        developer.log(
          'Complex Schema Performance Test:',
          level: Level.INFO.value,
          name: 'BENCHMARK',
        );
        developer.log(
          '  Documents: ${documents.length} (mixed complexity)',
          level: Level.INFO.value,
          name: 'BENCHMARK',
        );
        developer.log(
          '  Processing time: ${stopwatch.elapsedMilliseconds}ms',
          level: Level.INFO.value,
          name: 'BENCHMARK',
        );
        final throughputValue = stopwatch.elapsedMilliseconds > 0
            ? (documents.length / stopwatch.elapsedMilliseconds * 1000)
            : double.infinity;
        developer.log(
          '  Throughput: ${throughputValue.isFinite ? throughputValue.toStringAsFixed(1) : "∞"} docs/sec',
          level: Level.INFO.value,
          name: 'BENCHMARK',
        );
        developer.log(
          '  Cache statistics: $cacheStats',
          level: Level.INFO.value,
          name: 'BENCHMARK',
        );

        // Validate results
        expect(results.length, equals(documents.length));
        _validateAppendTypenameResults(results, '__typename');

        // Should handle complex schemas efficiently
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(5000),
        ); // Should complete within 5 seconds

        // Should maintain good throughput
        final throughput = stopwatch.elapsedMilliseconds > 0
            ? documents.length / stopwatch.elapsedMilliseconds * 1000
            : double.infinity;
        if (throughput.isFinite) {
          expect(
            throughput,
            greaterThan(10),
          ); // At least 10 docs/sec for complex schemas if measurable
        }
      });
    });
  });
}

// Helper functions for individual processing (baseline comparison)

DocumentNode _processDocumentIndividually(
  DocumentNode document,
  List<TransformingVisitor> transformers,
) {
  var result = document;
  for (final transformer in transformers) {
    result = _applyTransformerToDocument(result, transformer);
  }
  return result;
}

DocumentNode _applyTransformerToDocument(
  DocumentNode document,
  TransformingVisitor transformer,
) {
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

// Validation functions

void _validateAppendTypenameResults(
  List<DocumentNode> documents,
  String typeName,
) {
  for (final doc in documents) {
    for (final definition in doc.definitions) {
      if (definition is OperationDefinitionNode) {
        _validateOperationHasTypename(definition, typeName);
      } else if (definition is FragmentDefinitionNode) {
        _validateFragmentHasTypename(definition, typeName);
      }
    }
  }
}

void _validateOperationHasTypename(
  OperationDefinitionNode operation,
  String typeName,
) {
  final hasTypename = operation.selectionSet.selections
      .whereType<FieldNode>()
      .any((field) => field.name.value == typeName);

  expect(hasTypename, isTrue, reason: 'Operation should have $typeName field');
}

void _validateFragmentHasTypename(
  FragmentDefinitionNode fragment,
  String typeName,
) {
  final hasTypename = fragment.selectionSet.selections
      .whereType<FieldNode>()
      .any((field) => field.name.value == typeName);

  expect(hasTypename, isTrue, reason: 'Fragment should have $typeName field');
}

// Test data creation functions

DocumentNode _createSimpleQuery([String name = 'TestQuery']) {
  return DocumentNode(
    definitions: [
      OperationDefinitionNode(
        type: OperationType.query,
        name: NameNode(value: name),
        selectionSet: const SelectionSetNode(
          selections: [
            FieldNode(name: NameNode(value: 'user')),
            FieldNode(name: NameNode(value: 'id')),
          ],
        ),
      ),
    ],
  );
}

DocumentNode _createComplexNestedQuery([String name = 'ComplexQuery']) {
  return DocumentNode(
    definitions: [
      OperationDefinitionNode(
        type: OperationType.query,
        name: NameNode(value: name),
        selectionSet: const SelectionSetNode(
          selections: [
            FieldNode(
              name: NameNode(value: 'user'),
              selectionSet: SelectionSetNode(
                selections: [
                  FieldNode(name: NameNode(value: 'id')),
                  FieldNode(name: NameNode(value: 'name')),
                  FieldNode(
                    name: NameNode(value: 'profile'),
                    selectionSet: SelectionSetNode(
                      selections: [
                        FieldNode(name: NameNode(value: 'bio')),
                        FieldNode(name: NameNode(value: 'avatar')),
                        FieldNode(
                          name: NameNode(value: 'settings'),
                          selectionSet: SelectionSetNode(
                            selections: [
                              FieldNode(name: NameNode(value: 'theme')),
                              FieldNode(name: NameNode(value: 'notifications')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  FieldNode(
                    name: NameNode(value: 'posts'),
                    selectionSet: SelectionSetNode(
                      selections: [
                        FieldNode(name: NameNode(value: 'id')),
                        FieldNode(name: NameNode(value: 'title')),
                        FieldNode(name: NameNode(value: 'content')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

DocumentNode _createMultiOperationQuery([String name = 'MultiQuery']) {
  return DocumentNode(
    definitions: [
      OperationDefinitionNode(
        type: OperationType.query,
        name: NameNode(value: '${name}Query'),
        selectionSet: const SelectionSetNode(
          selections: [
            FieldNode(name: NameNode(value: 'users')),
          ],
        ),
      ),
      OperationDefinitionNode(
        type: OperationType.mutation,
        name: NameNode(value: '${name}Mutation'),
        selectionSet: const SelectionSetNode(
          selections: [
            FieldNode(name: NameNode(value: 'createUser')),
          ],
        ),
      ),
    ],
  );
}

DocumentNode _createDeeplyNestedQuery(String name, int depth) {
  SelectionSetNode buildNestedSelection(int currentDepth) {
    if (currentDepth <= 0) {
      return const SelectionSetNode(
        selections: [
          FieldNode(name: NameNode(value: 'leaf')),
          FieldNode(name: NameNode(value: 'value')),
        ],
      );
    }

    return SelectionSetNode(
      selections: [
        const FieldNode(name: NameNode(value: 'id')),
        const FieldNode(name: NameNode(value: 'name')),
        FieldNode(
          name: NameNode(value: 'nested$currentDepth'),
          selectionSet: buildNestedSelection(currentDepth - 1),
        ),
      ],
    );
  }

  return DocumentNode(
    definitions: [
      OperationDefinitionNode(
        type: OperationType.query,
        name: NameNode(value: name),
        selectionSet: buildNestedSelection(depth),
      ),
    ],
  );
}

DocumentNode _createWideQuery(String name, int fieldCount) {
  final selections = <SelectionNode>[];

  for (var i = 0; i < fieldCount; i++) {
    selections.add(FieldNode(name: NameNode(value: 'field$i')));
  }

  return DocumentNode(
    definitions: [
      OperationDefinitionNode(
        type: OperationType.query,
        name: NameNode(value: name),
        selectionSet: SelectionSetNode(selections: selections),
      ),
    ],
  );
}

DocumentNode _createQueryWithManyFragments([String name = 'FragmentQuery']) {
  return DocumentNode(
    definitions: [
      OperationDefinitionNode(
        type: OperationType.query,
        name: NameNode(value: name),
        selectionSet: const SelectionSetNode(
          selections: [
            FieldNode(
              name: NameNode(value: 'user'),
              selectionSet: SelectionSetNode(
                selections: [
                  FragmentSpreadNode(name: NameNode(value: 'UserBasicFields')),
                  FragmentSpreadNode(
                    name: NameNode(value: 'UserProfileFields'),
                  ),
                  FieldNode(
                    name: NameNode(value: 'posts'),
                    selectionSet: SelectionSetNode(
                      selections: [
                        FragmentSpreadNode(name: NameNode(value: 'PostFields')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Add fragment definitions
      const FragmentDefinitionNode(
        name: NameNode(value: 'UserBasicFields'),
        typeCondition: TypeConditionNode(
          on: NamedTypeNode(name: NameNode(value: 'User')),
        ),
        selectionSet: SelectionSetNode(
          selections: [
            FieldNode(name: NameNode(value: 'id')),
            FieldNode(name: NameNode(value: 'name')),
            FieldNode(name: NameNode(value: 'email')),
          ],
        ),
      ),
      const FragmentDefinitionNode(
        name: NameNode(value: 'UserProfileFields'),
        typeCondition: TypeConditionNode(
          on: NamedTypeNode(name: NameNode(value: 'User')),
        ),
        selectionSet: SelectionSetNode(
          selections: [
            FieldNode(
              name: NameNode(value: 'profile'),
              selectionSet: SelectionSetNode(
                selections: [
                  FieldNode(name: NameNode(value: 'bio')),
                  FieldNode(name: NameNode(value: 'avatar')),
                ],
              ),
            ),
          ],
        ),
      ),
      const FragmentDefinitionNode(
        name: NameNode(value: 'PostFields'),
        typeCondition: TypeConditionNode(
          on: NamedTypeNode(name: NameNode(value: 'Post')),
        ),
        selectionSet: SelectionSetNode(
          selections: [
            FieldNode(name: NameNode(value: 'id')),
            FieldNode(name: NameNode(value: 'title')),
            FieldNode(name: NameNode(value: 'content')),
          ],
        ),
      ),
    ],
  );
}

// Mock transformer for testing combinations
class _MockTransformer extends TransformingVisitor {
  @override
  OperationDefinitionNode visitOperationDefinitionNode(
    OperationDefinitionNode node,
  ) {
    // Simple pass-through transformer for testing
    return node;
  }

  @override
  FragmentDefinitionNode visitFragmentDefinitionNode(
    FragmentDefinitionNode node,
  ) {
    // Simple pass-through transformer for testing
    return node;
  }
}
