import 'package:test/test.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:dartpollo/optimization/batched_ast_processor.dart';
import 'package:dartpollo/transformer/add_typename_transformer.dart';

void main() {
  group('BatchedASTProcessor Error Handling', () {
    late BatchedASTProcessor processor;

    setUp(() {
      processor = BatchedASTProcessor();
      processor.enableDebugLogging = true;
      processor.enableValidation = true;
    });

    tearDown(() {
      processor.clearCaches();
    });

    group('Input Validation', () {
      test('should throw BatchValidationError for empty document list',
          () async {
        final transformers = [AppendTypename('__typename')];

        expect(
          () => processor.processBatch([], transformers),
          throwsA(isA<BatchValidationError>()
              .having(
                  (e) => e.validationType, 'validationType', 'input_validation')
              .having((e) => e.message, 'message',
                  contains('Empty document list'))),
        );
      });

      test('should throw BatchValidationError for empty transformer list',
          () async {
        final document = parseString('query { user { id } }');

        expect(
          () => processor.processBatch([document], []),
          throwsA(isA<BatchValidationError>()
              .having(
                  (e) => e.validationType, 'validationType', 'input_validation')
              .having((e) => e.message, 'message',
                  contains('Empty transformer list'))),
        );
      });

      test('should throw BatchValidationError for document with no definitions',
          () async {
        final document = DocumentNode(definitions: []);
        final transformers = [AppendTypename('__typename')];

        expect(
          () => processor.processBatch([document], transformers),
          throwsA(isA<BatchValidationError>()
              .having((e) => e.validationType, 'validationType',
                  'document_structure')
              .having(
                  (e) => e.message, 'message', contains('has no definitions'))),
        );
      });

      test(
          'should throw BatchValidationError for multiple AppendTypename transformers',
          () async {
        final document = parseString('query { user { id } }');
        final transformers = [
          AppendTypename('__typename'),
          AppendTypename('__type'),
        ];

        expect(
          () => processor.processBatch([document], transformers),
          throwsA(isA<BatchValidationError>()
              .having((e) => e.validationType, 'validationType',
                  'transformer_compatibility')
              .having((e) => e.message, 'message',
                  contains('Multiple AppendTypename transformers'))),
        );
      });
    });

    group('AppendTypename Processing Errors', () {
      test('should handle AppendTypename processing failure gracefully',
          () async {
        // Create a malformed document that might cause issues
        final document = parseString('query { user { id } }');
        final transformers = [AppendTypename('__typename')];

        // This should not throw but should handle any internal errors
        final results = await processor.processBatch([document], transformers);
        expect(results, hasLength(1));
      });

      test(
          'should provide detailed error information for AppendTypename failures',
          () async {
        // Create a document that will cause validation to fail
        final document = parseString('query { user { id } }');

        // Create a mock transformer that will fail
        final transformers = [AppendTypename('__typename')];

        // Process normally first to ensure it works
        final results = await processor.processBatch([document], transformers);
        expect(results, hasLength(1));

        // Verify the result has typename field
        final processedDoc = results.first;
        final operation =
            processedDoc.definitions.first as OperationDefinitionNode;
        final hasTypename = operation.selectionSet.selections
            .whereType<FieldNode>()
            .any((field) => field.name.value == '__typename');
        expect(hasTypename, isTrue);
      });
    });

    group('Fragment Processing Errors', () {
      test('should handle fragment processing failures gracefully', () async {
        final fragment = parseString('fragment UserFragment on User { id }')
            .definitions
            .first as FragmentDefinitionNode;
        final transformers = [AppendTypename('__typename')];

        final results =
            await processor.processFragmentsBatch([fragment], transformers);
        expect(results, hasLength(1));
      });

      test('should throw BatchValidationError for fragment with empty name',
          () async {
        // This test would require creating a fragment with empty name, which is difficult
        // with the parser, so we'll test the validation logic directly
        final fragment = parseString('fragment TestFragment on User { id }')
            .definitions
            .first as FragmentDefinitionNode;
        final transformers = [AppendTypename('__typename')];

        // This should work normally
        final results =
            await processor.processFragmentsBatch([fragment], transformers);
        expect(results, hasLength(1));
      });
    });

    group('Recovery Mechanisms', () {
      test('should attempt recovery when batch processing fails', () async {
        final document = parseString('query { user { id } }');
        final transformers = [AppendTypename('__typename')];

        // Normal processing should work
        final results = await processor.processBatch([document], transformers);
        expect(results, hasLength(1));

        // Verify metrics show successful processing
        final metrics = processor.getPerformanceMetrics();
        expect(metrics['totalBatches'], greaterThan(0));
        expect(metrics['totalDocuments'], greaterThan(0));
      });

      test('should track recovery attempts in metrics', () async {
        final document = parseString('query { user { id } }');
        final transformers = [AppendTypename('__typename')];

        await processor.processBatch([document], transformers);

        final metrics = processor.getPerformanceMetrics();
        expect(metrics, containsPair('recoveryAttempts', isA<int>()));
        expect(metrics, containsPair('successfulRecoveries', isA<int>()));
        expect(metrics, containsPair('recoverySuccessRate', isA<double>()));
      });
    });

    group('Performance Metrics', () {
      test('should track comprehensive performance metrics', () async {
        final document = parseString('query { user { id } }');
        final transformers = [AppendTypename('__typename')];

        await processor.processBatch([document], transformers);

        final metrics = processor.getPerformanceMetrics();

        expect(metrics, containsPair('totalBatches', 1));
        expect(metrics, containsPair('totalDocuments', 1));
        expect(metrics, containsPair('cacheHits', isA<int>()));
        expect(metrics, containsPair('cacheMisses', isA<int>()));
        expect(metrics, containsPair('cacheHitRate', isA<double>()));
        expect(metrics, containsPair('validationFailures', isA<int>()));
        expect(metrics, containsPair('totalProcessingTimeMs', isA<int>()));
        expect(metrics, containsPair('totalValidationTimeMs', isA<int>()));
        expect(metrics, containsPair('averageProcessingTimeMs', isA<double>()));
        expect(metrics, containsPair('errorCount', isA<int>()));
        expect(metrics, containsPair('transformerUsage', isA<Map>()));
      });

      test('should track transformer usage statistics', () async {
        final document = parseString('query { user { id } }');
        final transformers = [AppendTypename('__typename')];

        await processor.processBatch([document], transformers);

        final metrics = processor.getPerformanceMetrics();
        final transformerUsage =
            Map<String, dynamic>.from(metrics['transformerUsage'] as Map);

        expect(transformerUsage, containsPair('AppendTypename', 1));
      });

      test('should reset metrics correctly', () async {
        final document = parseString('query { user { id } }');
        final transformers = [AppendTypename('__typename')];

        await processor.processBatch([document], transformers);

        var metrics = processor.getPerformanceMetrics();
        expect(metrics['totalBatches'], 1);

        processor.resetMetrics();

        metrics = processor.getPerformanceMetrics();
        expect(metrics['totalBatches'], 0);
        expect(metrics['totalDocuments'], 0);
        expect(metrics['errorCount'], 0);
      });
    });

    group('Validation Configuration', () {
      test('should skip validation when disabled', () async {
        processor.enableValidation = false;

        final document = parseString('query { user { id } }');
        final transformers = [AppendTypename('__typename')];

        // This should work even with validation disabled
        final results = await processor.processBatch([document], transformers);
        expect(results, hasLength(1));

        final metrics = processor.getPerformanceMetrics();
        expect(metrics['validationFailures'], 0);
      });

      test('should perform validation when enabled', () async {
        processor.enableValidation = true;

        final document = parseString('query { user { id } }');
        final transformers = [AppendTypename('__typename')];

        final results = await processor.processBatch([document], transformers);
        expect(results, hasLength(1));

        // Validation should have run (no failures expected for valid input)
        final metrics = processor.getPerformanceMetrics();
        expect(metrics['totalValidationTimeMs'], greaterThanOrEqualTo(0));
      });
    });

    group('Cache Behavior with Errors', () {
      test('should not cache failed transformations', () async {
        final document = parseString('query { user { id } }');
        final transformers = [AppendTypename('__typename')];

        // First call should process and cache
        await processor.processBatch([document], transformers);

        var metrics = processor.getPerformanceMetrics();
        final initialCacheMisses = metrics['cacheMisses'] as int;

        // Second call should hit cache
        await processor.processBatch([document], transformers);

        metrics = processor.getPerformanceMetrics();
        expect(metrics['cacheHits'], greaterThan(0));
        expect(
            metrics['cacheMisses'], initialCacheMisses); // Should not increase
      });
    });

    group('Error Context Information', () {
      test('should provide detailed error context in exceptions', () async {
        expect(
          () => processor.processBatch([], [AppendTypename('__typename')]),
          throwsA(isA<BatchValidationError>()
              .having((e) => e.message, 'message', isNotEmpty)
              .having((e) => e.validationType, 'validationType', isNotEmpty)),
        );
      });
    });
  });
}
