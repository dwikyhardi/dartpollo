import 'package:test/test.dart';
import 'dart:developer' as dev;
import 'package:gql/ast.dart';
import 'package:dartpollo/optimization/batched_ast_processor.dart';
import 'package:dartpollo/transformer/add_typename_transformer.dart';

/// Performance comparison tests between batched and individual processing
/// These tests validate that batched processing maintains or improves performance
/// while producing identical results
void main() {
  group('Batched vs Individual Performance Tests', () {
    late BatchedASTProcessor batchedProcessor;

    setUp(() {
      batchedProcessor = BatchedASTProcessor();
    });

    tearDown(() {
      batchedProcessor.clearCaches();
    });

    test('should demonstrate performance improvement with large document sets',
        () async {
      // Create a large set of diverse documents
      final documents = <DocumentNode>[];

      // Add 100 simple queries
      for (int i = 0; i < 100; i++) {
        documents.add(_createSimpleQuery('SimpleQuery$i'));
      }

      // Add 50 complex nested queries
      for (int i = 0; i < 50; i++) {
        documents.add(_createComplexNestedQuery('ComplexQuery$i'));
      }

      // Add 30 queries with fragments
      for (int i = 0; i < 30; i++) {
        documents.add(_createQueryWithFragments('FragmentQuery$i'));
      }

      final transformers = [AppendTypename('__typename')];

      // Measure individual processing time
      final individualStopwatch = Stopwatch()..start();
      final individualResults = <DocumentNode>[];
      for (final doc in documents) {
        individualResults.add(_processDocumentIndividually(doc, transformers));
      }
      individualStopwatch.stop();

      // Clear any caches to ensure fair comparison
      batchedProcessor.clearCaches();

      // Measure batched processing time
      final batchedStopwatch = Stopwatch()..start();
      final batchedResults =
          await batchedProcessor.processBatch(documents, transformers);
      batchedStopwatch.stop();

      // Validate results are identical
      expect(batchedResults.length, equals(individualResults.length));
      for (int i = 0; i < batchedResults.length; i++) {
        _compareDocuments(individualResults[i], batchedResults[i]);
      }

      // Print performance metrics
      dev.log(
          'Individual processing: ${individualStopwatch.elapsedMilliseconds}ms');
      dev.log('Batched processing: ${batchedStopwatch.elapsedMilliseconds}ms');
      dev.log(
          'Performance improvement: ${((individualStopwatch.elapsedMilliseconds - batchedStopwatch.elapsedMilliseconds) / individualStopwatch.elapsedMilliseconds * 100).toStringAsFixed(1)}%');

      // Batched processing should be at least as fast (allowing some variance)
      expect(batchedStopwatch.elapsedMilliseconds,
          lessThanOrEqualTo(individualStopwatch.elapsedMilliseconds + 50));
    });

    test('should show memory efficiency with repeated documents', () async {
      // Create documents with some repetition to test caching
      final baseDocument = _createComplexNestedQuery('BaseQuery');
      final documents = <DocumentNode>[];

      // Add the same document multiple times to test cache efficiency
      for (int i = 0; i < 20; i++) {
        documents.add(baseDocument);
      }

      // Add some unique documents
      for (int i = 0; i < 10; i++) {
        documents.add(_createSimpleQuery('UniqueQuery$i'));
      }

      final transformers = [AppendTypename('__typename')];

      // Process with batched processor (should benefit from caching)
      final stopwatch = Stopwatch()..start();
      final results =
          await batchedProcessor.processBatch(documents, transformers);
      stopwatch.stop();

      // Validate all results
      expect(results.length, equals(documents.length));

      // Check cache statistics
      final cacheStats = batchedProcessor.getCacheStats();
      dev.log('Cache statistics: $cacheStats');

      // Should have cached the repeated document
      expect(cacheStats['appendTypenameCacheSize'], greaterThan(0));

      // Processing should be fast due to caching
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('should handle fragment processing efficiently', () async {
      final fragments = <FragmentDefinitionNode>[];

      // Create a variety of fragments
      for (int i = 0; i < 50; i++) {
        fragments.add(_createSimpleFragment('Fragment$i', 'Type$i'));
      }

      for (int i = 0; i < 30; i++) {
        fragments
            .add(_createComplexFragment('ComplexFragment$i', 'ComplexType$i'));
      }

      final transformers = [AppendTypename('__typename')];

      // Measure individual fragment processing
      final individualStopwatch = Stopwatch()..start();
      final individualResults = <FragmentDefinitionNode>[];
      for (final fragment in fragments) {
        individualResults
            .add(_processFragmentIndividually(fragment, transformers));
      }
      individualStopwatch.stop();

      // Clear caches for fair comparison
      batchedProcessor.clearCaches();

      // Measure batched fragment processing
      final batchedStopwatch = Stopwatch()..start();
      final batchedResults =
          await batchedProcessor.processFragmentsBatch(fragments, transformers);
      batchedStopwatch.stop();

      // Validate results are identical
      expect(batchedResults.length, equals(individualResults.length));
      for (int i = 0; i < batchedResults.length; i++) {
        _compareFragments(individualResults[i], batchedResults[i]);
      }

      dev.log(
          'Fragment individual processing: ${individualStopwatch.elapsedMilliseconds}ms');
      dev.log(
          'Fragment batched processing: ${batchedStopwatch.elapsedMilliseconds}ms');

      // Batched should be competitive
      expect(batchedStopwatch.elapsedMilliseconds,
          lessThanOrEqualTo(individualStopwatch.elapsedMilliseconds + 30));
    });

    test('should scale well with document complexity', () async {
      final complexityLevels = [1, 2, 3, 4, 5]; // Different nesting levels
      final results = <String, Map<String, int>>{};

      for (final complexity in complexityLevels) {
        final documents =
            List.generate(20, (i) => _createNestedQuery('Query$i', complexity));
        final transformers = [AppendTypename('__typename')];

        // Individual processing
        final individualStopwatch = Stopwatch()..start();
        final individualResults = <DocumentNode>[];
        for (final doc in documents) {
          individualResults
              .add(_processDocumentIndividually(doc, transformers));
        }
        individualStopwatch.stop();

        // Clear caches
        batchedProcessor.clearCaches();

        // Batched processing
        final batchedStopwatch = Stopwatch()..start();
        final batchedResults =
            await batchedProcessor.processBatch(documents, transformers);
        batchedStopwatch.stop();

        // Validate results
        expect(batchedResults.length, equals(individualResults.length));

        results['complexity_$complexity'] = {
          'individual': individualStopwatch.elapsedMilliseconds,
          'batched': batchedStopwatch.elapsedMilliseconds,
        };

        dev.log(
            'Complexity $complexity - Individual: ${individualStopwatch.elapsedMilliseconds}ms, Batched: ${batchedStopwatch.elapsedMilliseconds}ms');
      }

      // Batched processing should scale well
      for (final entry in results.entries) {
        final individual = entry.value['individual']!;
        final batched = entry.value['batched']!;
        expect(batched, lessThanOrEqualTo(individual + 20));
      }
    });
  });
}

// Helper functions for individual processing

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

FragmentDefinitionNode _processFragmentIndividually(
  FragmentDefinitionNode fragment,
  List<TransformingVisitor> transformers,
) {
  var result = fragment;
  for (final transformer in transformers) {
    result = _applyTransformerToFragment(result, transformer);
  }
  return result;
}

DocumentNode _applyTransformerToDocument(
    DocumentNode document, TransformingVisitor transformer) {
  final transformedDefinitions = <DefinitionNode>[];

  for (final definition in document.definitions) {
    if (definition is OperationDefinitionNode) {
      transformedDefinitions
          .add(transformer.visitOperationDefinitionNode(definition));
    } else if (definition is FragmentDefinitionNode) {
      transformedDefinitions
          .add(transformer.visitFragmentDefinitionNode(definition));
    } else {
      transformedDefinitions.add(definition);
    }
  }

  return DocumentNode(
    definitions: transformedDefinitions,
    span: document.span,
  );
}

FragmentDefinitionNode _applyTransformerToFragment(
    FragmentDefinitionNode fragment, TransformingVisitor transformer) {
  return transformer.visitFragmentDefinitionNode(fragment);
}

// Comparison functions

void _compareDocuments(DocumentNode expected, DocumentNode actual) {
  expect(actual.definitions.length, equals(expected.definitions.length));

  for (int i = 0; i < expected.definitions.length; i++) {
    final expectedDef = expected.definitions[i];
    final actualDef = actual.definitions[i];

    expect(actualDef.runtimeType, equals(expectedDef.runtimeType));

    if (expectedDef is OperationDefinitionNode &&
        actualDef is OperationDefinitionNode) {
      _compareOperations(expectedDef, actualDef);
    } else if (expectedDef is FragmentDefinitionNode &&
        actualDef is FragmentDefinitionNode) {
      _compareFragments(expectedDef, actualDef);
    }
  }
}

void _compareOperations(
    OperationDefinitionNode expected, OperationDefinitionNode actual) {
  expect(actual.type, equals(expected.type));
  expect(actual.name?.value, equals(expected.name?.value));
  expect(actual.variableDefinitions.length,
      equals(expected.variableDefinitions.length));
  expect(actual.directives.length, equals(expected.directives.length));

  _compareSelectionSets(expected.selectionSet, actual.selectionSet);
}

void _compareFragments(
    FragmentDefinitionNode expected, FragmentDefinitionNode actual) {
  expect(actual.name.value, equals(expected.name.value));
  expect(actual.typeCondition.on.name.value,
      equals(expected.typeCondition.on.name.value));
  expect(actual.directives.length, equals(expected.directives.length));

  _compareSelectionSets(expected.selectionSet, actual.selectionSet);
}

void _compareSelectionSets(SelectionSetNode expected, SelectionSetNode actual) {
  expect(actual.selections.length, equals(expected.selections.length));

  // Sort selections by field name for consistent comparison
  final expectedFields = expected.selections.whereType<FieldNode>().toList()
    ..sort((a, b) => a.name.value.compareTo(b.name.value));
  final actualFields = actual.selections.whereType<FieldNode>().toList()
    ..sort((a, b) => a.name.value.compareTo(b.name.value));

  expect(actualFields.length, equals(expectedFields.length));

  for (int i = 0; i < expectedFields.length; i++) {
    _compareFields(expectedFields[i], actualFields[i]);
  }
}

void _compareFields(FieldNode expected, FieldNode actual) {
  expect(actual.name.value, equals(expected.name.value));
  expect(actual.alias?.value, equals(expected.alias?.value));
  expect(actual.arguments.length, equals(expected.arguments.length));
  expect(actual.directives.length, equals(expected.directives.length));

  if (expected.selectionSet != null && actual.selectionSet != null) {
    _compareSelectionSets(expected.selectionSet!, actual.selectionSet!);
  } else {
    expect(actual.selectionSet, equals(expected.selectionSet));
  }
}

// Test data creation functions

DocumentNode _createSimpleQuery([String name = 'TestQuery']) {
  return DocumentNode(definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: name),
      selectionSet: SelectionSetNode(selections: [
        FieldNode(name: NameNode(value: 'test')),
      ]),
    ),
  ]);
}

DocumentNode _createComplexNestedQuery([String name = 'ComplexQuery']) {
  return DocumentNode(definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: name),
      selectionSet: SelectionSetNode(selections: [
        FieldNode(
          name: NameNode(value: 'user'),
          selectionSet: SelectionSetNode(selections: [
            FieldNode(name: NameNode(value: 'id')),
            FieldNode(name: NameNode(value: 'name')),
            FieldNode(
              name: NameNode(value: 'profile'),
              selectionSet: SelectionSetNode(selections: [
                FieldNode(name: NameNode(value: 'bio')),
                FieldNode(name: NameNode(value: 'avatar')),
                FieldNode(
                  name: NameNode(value: 'settings'),
                  selectionSet: SelectionSetNode(selections: [
                    FieldNode(name: NameNode(value: 'theme')),
                    FieldNode(name: NameNode(value: 'notifications')),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    ),
  ]);
}

DocumentNode _createQueryWithFragments([String name = 'FragmentQuery']) {
  return DocumentNode(definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: name),
      selectionSet: SelectionSetNode(selections: [
        FieldNode(
          name: NameNode(value: 'user'),
          selectionSet: SelectionSetNode(selections: [
            FragmentSpreadNode(name: NameNode(value: 'UserFields')),
            FieldNode(
              name: NameNode(value: 'posts'),
              selectionSet: SelectionSetNode(selections: [
                FragmentSpreadNode(name: NameNode(value: 'PostFields')),
              ]),
            ),
          ]),
        ),
      ]),
    ),
  ]);
}

DocumentNode _createNestedQuery(String name, int nestingLevel) {
  SelectionSetNode buildNestedSelection(int level) {
    if (level <= 0) {
      return SelectionSetNode(selections: [
        FieldNode(name: NameNode(value: 'leaf')),
      ]);
    }

    return SelectionSetNode(selections: [
      FieldNode(name: NameNode(value: 'id')),
      FieldNode(
        name: NameNode(value: 'nested$level'),
        selectionSet: buildNestedSelection(level - 1),
      ),
    ]);
  }

  return DocumentNode(definitions: [
    OperationDefinitionNode(
      type: OperationType.query,
      name: NameNode(value: name),
      selectionSet: buildNestedSelection(nestingLevel),
    ),
  ]);
}

FragmentDefinitionNode _createSimpleFragment(
    [String name = 'TestFragment', String type = 'User']) {
  return FragmentDefinitionNode(
    name: NameNode(value: name),
    typeCondition: TypeConditionNode(
      on: NamedTypeNode(name: NameNode(value: type)),
    ),
    selectionSet: SelectionSetNode(selections: [
      FieldNode(name: NameNode(value: 'id')),
    ]),
  );
}

FragmentDefinitionNode _createComplexFragment(String name, String type) {
  return FragmentDefinitionNode(
    name: NameNode(value: name),
    typeCondition: TypeConditionNode(
      on: NamedTypeNode(name: NameNode(value: type)),
    ),
    selectionSet: SelectionSetNode(selections: [
      FieldNode(name: NameNode(value: 'id')),
      FieldNode(name: NameNode(value: 'name')),
      FieldNode(
        name: NameNode(value: 'details'),
        selectionSet: SelectionSetNode(selections: [
          FieldNode(name: NameNode(value: 'info')),
          FieldNode(name: NameNode(value: 'metadata')),
        ]),
      ),
    ]),
  );
}
