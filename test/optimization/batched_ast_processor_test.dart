import 'package:dartpollo/optimization/batched_ast_processor.dart';
import 'package:dartpollo/transformer/add_typename_transformer.dart';
import 'package:gql/ast.dart';
import 'package:test/test.dart';

/// Mock transformer for testing mixed transformer scenarios
class MockTransformer extends TransformingVisitor {
  MockTransformer(this.fieldToAdd);
  final String fieldToAdd;

  @override
  OperationDefinitionNode visitOperationDefinitionNode(
    OperationDefinitionNode node,
  ) {
    return OperationDefinitionNode(
      type: node.type,
      name: node.name,
      variableDefinitions: node.variableDefinitions,
      directives: node.directives,
      span: node.span,
      selectionSet: SelectionSetNode(
        selections: <SelectionNode>[
          ...node.selectionSet.selections,
          FieldNode(name: NameNode(value: fieldToAdd)),
        ],
      ),
    );
  }
}

void main() {
  group('BatchedASTProcessor AppendTypename Support', () {
    late BatchedASTProcessor processor;

    setUp(() {
      processor = BatchedASTProcessor();
    });

    tearDown(() {
      processor.clearCaches();
    });

    group('AppendTypename Transformation in Isolation', () {
      test('should detect AppendTypename transformer in transformer list', () {
        final transformers = [AppendTypename('__typename')];
        final documents = [_createSimpleQuery()];

        // This should not throw and should use the AppendTypename processing path
        expect(
          () => processor.processBatch(documents, transformers),
          returnsNormally,
        );
      });

      test(
        'should process single document with AppendTypename transformer',
        () async {
          final transformers = [AppendTypename('__typename')];
          final documents = [_createSimpleQuery()];

          final results = await processor.processBatch(documents, transformers);

          expect(results, hasLength(1));
          expect(results.first.definitions, hasLength(1));

          final operation =
              results.first.definitions.first as OperationDefinitionNode;
          final selections = operation.selectionSet.selections;

          // Should have the original field plus the __typename field
          expect(selections, hasLength(2));

          // Check that __typename field was added
          final typenameField = selections.whereType<FieldNode>().firstWhere(
            (field) => field.name.value == '__typename',
          );
          expect(typenameField.name.value, equals('__typename'));
        },
      );

      test(
        'should process multiple documents with AppendTypename transformer',
        () async {
          final transformers = [AppendTypename('__typename')];
          final documents = [
            _createSimpleQuery('Query1'),
            _createSimpleQuery('Query2'),
            _createSimpleQuery('Query3'),
          ];

          final results = await processor.processBatch(documents, transformers);

          expect(results, hasLength(3));

          for (var i = 0; i < results.length; i++) {
            final operation =
                results[i].definitions.first as OperationDefinitionNode;
            final selections = operation.selectionSet.selections;

            // Each should have the original field plus the __typename field
            expect(selections, hasLength(2));

            // Check that __typename field was added to each
            final typenameField = selections.whereType<FieldNode>().firstWhere(
              (field) => field.name.value == '__typename',
            );
            expect(typenameField.name.value, equals('__typename'));
          }
        },
      );

      test('should handle nested selections with AppendTypename', () async {
        final transformers = [AppendTypename('__typename')];
        final documents = [_createNestedQuery()];

        final results = await processor.processBatch(documents, transformers);

        expect(results, hasLength(1));

        final operation =
            results.first.definitions.first as OperationDefinitionNode;
        final selections = operation.selectionSet.selections;

        // Should have user field and __typename field
        expect(selections, hasLength(2));

        // Check that __typename field was added at root level
        final typenameField = selections.whereType<FieldNode>().firstWhere(
          (field) => field.name.value == '__typename',
        );
        expect(typenameField.name.value, equals('__typename'));

        // Check nested field also has __typename
        final userField = selections.whereType<FieldNode>().firstWhere(
          (field) => field.name.value == 'user',
        );
        expect(userField.selectionSet, isNotNull);

        final nestedSelections = userField.selectionSet!.selections;
        expect(nestedSelections, hasLength(3)); // id, name, __typename

        final nestedTypenameField = nestedSelections
            .whereType<FieldNode>()
            .firstWhere((field) => field.name.value == '__typename');
        expect(nestedTypenameField.name.value, equals('__typename'));
      });

      test('should handle custom typename field name', () async {
        final transformers = [AppendTypename('customTypename')];
        final documents = [_createSimpleQuery()];

        final results = await processor.processBatch(documents, transformers);

        final operation =
            results.first.definitions.first as OperationDefinitionNode;
        final selections = operation.selectionSet.selections;

        // Check that custom typename field was added
        final typenameField = selections.whereType<FieldNode>().firstWhere(
          (field) => field.name.value == 'customTypename',
        );
        expect(typenameField.name.value, equals('customTypename'));
      });

      test('should deduplicate existing typename fields', () async {
        final transformers = [AppendTypename('__typename')];
        final documents = [_createQueryWithExistingTypename()];

        final results = await processor.processBatch(documents, transformers);

        final operation =
            results.first.definitions.first as OperationDefinitionNode;
        final selections = operation.selectionSet.selections;

        // Should still have only 2 fields (test and __typename), not 3
        expect(selections, hasLength(2));

        // Should have exactly one __typename field
        final typenameFields = selections
            .whereType<FieldNode>()
            .where((field) => field.name.value == '__typename')
            .toList();
        expect(typenameFields, hasLength(1));
      });
    });

    group('AppendTypename Combined with Other Transformers', () {
      test('should apply AppendTypename after other transformers', () async {
        final transformers = [
          MockTransformer('mockField'),
          AppendTypename('__typename'),
        ];
        final documents = [_createSimpleQuery()];

        final results = await processor.processBatch(documents, transformers);

        final operation =
            results.first.definitions.first as OperationDefinitionNode;
        final selections = operation.selectionSet.selections;

        // Should have test, mockField, and __typename fields
        expect(selections, hasLength(3));

        // Verify all fields are present
        final fieldNames = selections
            .whereType<FieldNode>()
            .map((field) => field.name.value)
            .toSet();
        expect(fieldNames, containsAll(['test', 'mockField', '__typename']));
      });

      test('should handle multiple transformers with AppendTypename', () async {
        final transformers = [
          MockTransformer('field1'),
          MockTransformer('field2'),
          AppendTypename('__typename'),
        ];
        final documents = [_createSimpleQuery()];

        final results = await processor.processBatch(documents, transformers);

        final operation =
            results.first.definitions.first as OperationDefinitionNode;
        final selections = operation.selectionSet.selections;

        // Should have test, field1, field2, and __typename fields
        expect(selections, hasLength(4));

        // Verify all fields are present
        final fieldNames = selections
            .whereType<FieldNode>()
            .map((field) => field.name.value)
            .toSet();
        expect(
          fieldNames,
          containsAll(['test', 'field1', 'field2', '__typename']),
        );
      });

      test('should handle AppendTypename before other transformers', () async {
        final transformers = [
          AppendTypename('__typename'),
          MockTransformer('mockField'),
        ];
        final documents = [_createSimpleQuery()];

        final results = await processor.processBatch(documents, transformers);

        final operation =
            results.first.definitions.first as OperationDefinitionNode;
        final selections = operation.selectionSet.selections;

        // Should have test, __typename, and mockField fields
        expect(selections, hasLength(3));

        // Verify all fields are present
        final fieldNames = selections
            .whereType<FieldNode>()
            .map((field) => field.name.value)
            .toSet();
        expect(fieldNames, containsAll(['test', '__typename', 'mockField']));
      });

      test('should handle multiple AppendTypename transformers', () {
        final transformers = [
          AppendTypename('__typename'),
          AppendTypename('customType'),
        ];
        final documents = [_createSimpleQuery()];

        // With validation enabled, multiple AppendTypename transformers should throw an error
        expect(
          () => processor.processBatch(documents, transformers),
          throwsA(isA<BatchValidationError>()),
        );
      });
    });

    group('Fragment Processing with AppendTypename', () {
      test(
        'should process fragments with AppendTypename transformer',
        () async {
          final transformers = [AppendTypename('__typename')];
          final fragments = [_createSimpleFragment()];

          final results = await processor.processFragmentsBatch(
            fragments,
            transformers,
          );

          expect(results, hasLength(1));

          final fragment = results.first;
          final selections = fragment.selectionSet.selections;

          // Should have the original field plus the __typename field
          expect(selections, hasLength(2));

          // Check that __typename field was added
          final typenameField = selections.whereType<FieldNode>().firstWhere(
            (field) => field.name.value == '__typename',
          );
          expect(typenameField.name.value, equals('__typename'));
        },
      );

      test('should process multiple fragments with AppendTypename', () async {
        final transformers = [AppendTypename('__typename')];
        final fragments = [
          _createSimpleFragment('Fragment1'),
          _createSimpleFragment('Fragment2', 'Post'),
          _createSimpleFragment('Fragment3', 'Comment'),
        ];

        final results = await processor.processFragmentsBatch(
          fragments,
          transformers,
        );

        expect(results, hasLength(3));

        for (var i = 0; i < results.length; i++) {
          final fragment = results[i];
          final selections = fragment.selectionSet.selections;

          // Each should have the original field plus the __typename field
          expect(selections, hasLength(2));

          // Check that __typename field was added to each
          final typenameField = selections.whereType<FieldNode>().firstWhere(
            (field) => field.name.value == '__typename',
          );
          expect(typenameField.name.value, equals('__typename'));
        }
      });

      test('should preserve fragment name and type condition', () async {
        final transformers = [AppendTypename('__typename')];
        final originalFragment = _createSimpleFragment();
        final fragments = [originalFragment];

        final results = await processor.processFragmentsBatch(
          fragments,
          transformers,
        );

        final transformedFragment = results.first;

        // Fragment name should be preserved
        expect(transformedFragment.name.value, equals('TestFragment'));

        // Type condition should be preserved
        expect(transformedFragment.typeCondition.on.name.value, equals('User'));
      });

      test('should handle nested fragments with AppendTypename', () async {
        final transformers = [AppendTypename('__typename')];
        final fragments = [_createNestedFragment()];

        final results = await processor.processFragmentsBatch(
          fragments,
          transformers,
        );

        final fragment = results.first;
        final selections = fragment.selectionSet.selections;

        // Should have id, profile, and __typename fields
        expect(selections, hasLength(3));

        // Check that __typename field was added at fragment level
        final typenameField = selections.whereType<FieldNode>().firstWhere(
          (field) => field.name.value == '__typename',
        );
        expect(typenameField.name.value, equals('__typename'));

        // Check nested field also has __typename
        final profileField = selections.whereType<FieldNode>().firstWhere(
          (field) => field.name.value == 'profile',
        );
        expect(profileField.selectionSet, isNotNull);

        final nestedSelections = profileField.selectionSet!.selections;
        expect(nestedSelections, hasLength(3)); // name, email, __typename

        final nestedTypenameField = nestedSelections
            .whereType<FieldNode>()
            .firstWhere((field) => field.name.value == '__typename');
        expect(nestedTypenameField.name.value, equals('__typename'));
      });

      test('should handle fragments with mixed transformers', () async {
        final transformers = [
          AppendTypename('__typename'),
        ];
        final fragments = [_createSimpleFragment()];

        final results = await processor.processFragmentsBatch(
          fragments,
          transformers,
        );

        final fragment = results.first;
        final selections = fragment.selectionSet.selections;

        // Should have id and __typename fields
        expect(selections, hasLength(2));

        final fieldNames = selections
            .whereType<FieldNode>()
            .map((field) => field.name.value)
            .toSet();
        expect(fieldNames, containsAll(['id', '__typename']));
      });
    });

    group('Caching Behavior with AppendTypename', () {
      test('should cache AppendTypename transformation results', () async {
        final transformers = [AppendTypename('__typename')];
        final documents = [_createSimpleQuery()];

        // Process twice
        await processor.processBatch(documents, transformers);
        await processor.processBatch(documents, transformers);

        final stats = processor.getCacheStats();

        // Should have cache entries
        expect(stats['appendTypenameCacheSize'], greaterThan(0));
      });

      test(
        'should cache fragment AppendTypename transformation results',
        () async {
          final transformers = [AppendTypename('__typename')];
          final fragments = [_createSimpleFragment()];

          // Process twice
          await processor.processFragmentsBatch(fragments, transformers);
          await processor.processFragmentsBatch(fragments, transformers);

          final stats = processor.getCacheStats();

          // Should have fragment cache entries
          expect(stats['fragmentAppendTypenameCacheSize'], greaterThan(0));
        },
      );

      test('should cache AppendTypename transformation results', () async {
        final documents = [_createSimpleQuery()];

        // Clear cache first
        processor.clearCaches();

        // Process with AppendTypename configuration
        await processor.processBatch(documents, [AppendTypename('__typename')]);

        var stats = processor.getCacheStats();
        expect(stats['appendTypenameCacheSize'], equals(1));

        // Process same document with same transformer again (should use cache)
        await processor.processBatch(documents, [AppendTypename('__typename')]);

        stats = processor.getCacheStats();
        expect(
          stats['appendTypenameCacheSize'],
          equals(1),
        ); // Should still be 1
      });

      test('should cache mixed transformer results separately', () async {
        final documents = [_createSimpleQuery()];

        // Process with different transformer combinations
        await processor.processBatch(documents, [AppendTypename('__typename')]);
        await processor.processBatch(documents, [
          MockTransformer('mock'),
          AppendTypename('__typename'),
        ]);

        final stats = processor.getCacheStats();

        // Should have separate cache entries for different combinations
        expect(stats['appendTypenameCacheSize'], equals(2));
      });

      test(
        'should reuse cached results for identical transformations',
        () async {
          final transformers = [AppendTypename('__typename')];
          final documents = [_createSimpleQuery()];

          // Process first time
          final results1 = await processor.processBatch(
            documents,
            transformers,
          );

          // Process second time (should use cache)
          final results2 = await processor.processBatch(
            documents,
            transformers,
          );

          // Results should be identical
          expect(results1.length, equals(results2.length));

          final op1 =
              results1.first.definitions.first as OperationDefinitionNode;
          final op2 =
              results2.first.definitions.first as OperationDefinitionNode;

          expect(
            op1.selectionSet.selections.length,
            equals(op2.selectionSet.selections.length),
          );
        },
      );

      test(
        'should clear AppendTypename caches when clearCaches is called',
        () async {
          final transformers = [AppendTypename('__typename')];
          final documents = [_createSimpleQuery()];
          final fragments = [_createSimpleFragment()];

          // Process to populate caches
          await processor.processBatch(documents, transformers);
          await processor.processFragmentsBatch(fragments, transformers);

          // Verify caches are populated
          var stats = processor.getCacheStats();
          expect(stats['appendTypenameCacheSize'], greaterThan(0));
          expect(stats['fragmentAppendTypenameCacheSize'], greaterThan(0));

          // Clear caches
          processor.clearCaches();

          // Verify caches are cleared
          stats = processor.getCacheStats();
          expect(stats['appendTypenameCacheSize'], equals(0));
          expect(stats['fragmentAppendTypenameCacheSize'], equals(0));
        },
      );
    });

    group('Error Handling and Validation', () {
      test(
        'should handle empty fragments with AppendTypename gracefully',
        () async {
          final transformers = [AppendTypename('__typename')];
          final fragments = [_createEmptyFragment()];

          final results = await processor.processFragmentsBatch(
            fragments,
            transformers,
          );

          expect(results, hasLength(1));
          final fragment = results.first;
          expect(fragment.name.value, 'EmptyFragment');

          // Should have added the typename field
          final hasTypename = fragment.selectionSet.selections
              .whereType<FieldNode>()
              .any((field) => field.name.value == '__typename');
          expect(hasTypename, isTrue);
        },
      );

      test('should validate transformation results', () {
        final transformers = [AppendTypename('__typename')];
        final documents = [_createSimpleQuery()];

        // This should not throw - validation should pass
        expect(
          () => processor.processBatch(documents, transformers),
          returnsNormally,
        );
      });

      test('should handle empty document list gracefully', () {
        final transformers = [AppendTypename('__typename')];
        final documents = <DocumentNode>[];

        // With validation enabled, empty documents should throw an error
        expect(
          () => processor.processBatch(documents, transformers),
          throwsA(isA<BatchValidationError>()),
        );
      });

      test('should handle empty fragment list gracefully', () async {
        final transformers = [AppendTypename('__typename')];
        final fragments = <FragmentDefinitionNode>[];

        final results = await processor.processFragmentsBatch(
          fragments,
          transformers,
        );

        expect(results, isEmpty);
      });

      test('should handle empty transformer list gracefully', () {
        final transformers = <TransformingVisitor>[];
        final documents = [_createSimpleQuery()];

        // With validation enabled, empty transformers should throw an error
        expect(
          () => processor.processBatch(documents, transformers),
          throwsA(isA<BatchValidationError>()),
        );
      });
    });
  });
}

// Helper functions to create test data

DocumentNode _createSimpleQuery([String name = 'TestQuery']) {
  return DocumentNode(
    definitions: [
      OperationDefinitionNode(
        type: OperationType.query,
        name: NameNode(value: name),
        selectionSet: const SelectionSetNode(
          selections: [
            FieldNode(name: NameNode(value: 'test')),
          ],
        ),
      ),
    ],
  );
}

DocumentNode _createNestedQuery() {
  return const DocumentNode(
    definitions: [
      OperationDefinitionNode(
        type: OperationType.query,
        name: NameNode(value: 'NestedQuery'),
        selectionSet: SelectionSetNode(
          selections: [
            FieldNode(
              name: NameNode(value: 'user'),
              selectionSet: SelectionSetNode(
                selections: [
                  FieldNode(name: NameNode(value: 'id')),
                  FieldNode(name: NameNode(value: 'name')),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

DocumentNode _createQueryWithExistingTypename() {
  return const DocumentNode(
    definitions: [
      OperationDefinitionNode(
        type: OperationType.query,
        name: NameNode(value: 'QueryWithTypename'),
        selectionSet: SelectionSetNode(
          selections: [
            FieldNode(name: NameNode(value: 'test')),
            FieldNode(name: NameNode(value: '__typename')),
          ],
        ),
      ),
    ],
  );
}

FragmentDefinitionNode _createSimpleFragment([
  String name = 'TestFragment',
  String type = 'User',
]) {
  return FragmentDefinitionNode(
    name: NameNode(value: name),
    typeCondition: TypeConditionNode(
      on: NamedTypeNode(name: NameNode(value: type)),
    ),
    selectionSet: const SelectionSetNode(
      selections: [
        FieldNode(name: NameNode(value: 'id')),
      ],
    ),
  );
}

FragmentDefinitionNode _createNestedFragment() {
  return const FragmentDefinitionNode(
    name: NameNode(value: 'NestedFragment'),
    typeCondition: TypeConditionNode(
      on: NamedTypeNode(name: NameNode(value: 'User')),
    ),
    selectionSet: SelectionSetNode(
      selections: [
        FieldNode(name: NameNode(value: 'id')),
        FieldNode(
          name: NameNode(value: 'profile'),
          selectionSet: SelectionSetNode(
            selections: [
              FieldNode(name: NameNode(value: 'name')),
              FieldNode(name: NameNode(value: 'email')),
            ],
          ),
        ),
      ],
    ),
  );
}

FragmentDefinitionNode _createEmptyFragment() {
  return const FragmentDefinitionNode(
    name: NameNode(value: 'EmptyFragment'),
    typeCondition: TypeConditionNode(
      on: NamedTypeNode(name: NameNode(value: 'User')),
    ),
    selectionSet: SelectionSetNode(),
  );
}
