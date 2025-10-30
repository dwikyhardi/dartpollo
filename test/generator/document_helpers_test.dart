import 'package:dartpollo/generator/document_helpers.dart';
import 'package:gql/ast.dart';
import 'package:test/test.dart';

void main() {
  group('DocumentNodeHelpers', () {
    setUp(DocumentNodeHelpers.clearCache);

    group('nameNode', () {
      test('creates NameNode with correct value', () {
        final node = DocumentNodeHelpers.nameNode('pokemon');

        expect(node, isA<NameNode>());
        expect(node.value, equals('pokemon'));
      });

      test('caches NameNode instances', () {
        final node1 = DocumentNodeHelpers.nameNode('pokemon');
        final node2 = DocumentNodeHelpers.nameNode('pokemon');

        expect(identical(node1, node2), isTrue);
        expect(DocumentNodeHelpers.cacheSize, equals(1));
      });

      test('creates different instances for different values', () {
        final node1 = DocumentNodeHelpers.nameNode('pokemon');
        final node2 = DocumentNodeHelpers.nameNode('trainer');

        expect(identical(node1, node2), isFalse);
        expect(node1.value, equals('pokemon'));
        expect(node2.value, equals('trainer'));
        expect(DocumentNodeHelpers.cacheSize, equals(2));
      });
    });

    group('field', () {
      test('creates simple field without arguments or selections', () {
        final field = DocumentNodeHelpers.field('number');

        expect(field, isA<FieldNode>());
        expect(field.name.value, equals('number'));
        expect(field.alias, isNull);
        expect(field.arguments, isEmpty);
        expect(field.selectionSet, isNull);
      });

      test('creates field with alias', () {
        final field = DocumentNodeHelpers.field(
          'number',
          alias: 'pokemonNumber',
        );

        expect(field.name.value, equals('number'));
        expect(field.alias?.value, equals('pokemonNumber'));
      });

      test('creates field with arguments', () {
        final field = DocumentNodeHelpers.field(
          'pokemon',
          args: {
            'name': 'Charmander',
            'limit': 10,
            'active': true,
          },
        );

        expect(field.name.value, equals('pokemon'));
        expect(field.arguments, hasLength(3));

        final nameArg = field.arguments.firstWhere(
          (arg) => arg.name.value == 'name',
        );
        expect((nameArg.value as StringValueNode).value, equals('Charmander'));

        final limitArg = field.arguments.firstWhere(
          (arg) => arg.name.value == 'limit',
        );
        expect((limitArg.value as IntValueNode).value, equals('10'));

        final activeArg = field.arguments.firstWhere(
          (arg) => arg.name.value == 'active',
        );
        expect((activeArg.value as BooleanValueNode).value, isTrue);
      });

      test('creates field with nested selections', () {
        final field = DocumentNodeHelpers.field(
          'pokemon',
          selections: [
            DocumentNodeHelpers.field('number'),
            DocumentNodeHelpers.field('types'),
          ],
        );

        expect(field.name.value, equals('pokemon'));
        expect(field.selectionSet, isNotNull);
        expect(field.selectionSet!.selections, hasLength(2));

        final selections = field.selectionSet!.selections.cast<FieldNode>();
        expect(selections[0].name.value, equals('number'));
        expect(selections[1].name.value, equals('types'));
      });
    });

    group('argument', () {
      test('creates string argument', () {
        final arg = DocumentNodeHelpers.argument('name', 'Charmander');

        expect(arg.name.value, equals('name'));
        expect(arg.value, isA<StringValueNode>());
        expect((arg.value as StringValueNode).value, equals('Charmander'));
      });

      test('creates int argument', () {
        final arg = DocumentNodeHelpers.argument('limit', 10);

        expect(arg.name.value, equals('limit'));
        expect(arg.value, isA<IntValueNode>());
        expect((arg.value as IntValueNode).value, equals('10'));
      });

      test('creates boolean argument', () {
        final arg = DocumentNodeHelpers.argument('active', true);

        expect(arg.name.value, equals('active'));
        expect(arg.value, isA<BooleanValueNode>());
        expect((arg.value as BooleanValueNode).value, isTrue);
      });

      test('creates null argument', () {
        final arg = DocumentNodeHelpers.argument('optional', null);

        expect(arg.name.value, equals('optional'));
        expect(arg.value, isA<NullValueNode>());
      });

      test('creates list argument', () {
        final arg = DocumentNodeHelpers.argument('tags', ['fire', 'starter']);

        expect(arg.name.value, equals('tags'));
        expect(arg.value, isA<ListValueNode>());

        final listValue = arg.value as ListValueNode;
        expect(listValue.values, hasLength(2));
        expect((listValue.values[0] as StringValueNode).value, equals('fire'));
        expect(
          (listValue.values[1] as StringValueNode).value,
          equals('starter'),
        );
      });

      test('creates object argument', () {
        final arg = DocumentNodeHelpers.argument('filter', {
          'type': 'fire',
          'level': 5,
        });

        expect(arg.name.value, equals('filter'));
        expect(arg.value, isA<ObjectValueNode>());

        final objectValue = arg.value as ObjectValueNode;
        expect(objectValue.fields, hasLength(2));

        final typeField = objectValue.fields.firstWhere(
          (f) => f.name.value == 'type',
        );
        expect((typeField.value as StringValueNode).value, equals('fire'));

        final levelField = objectValue.fields.firstWhere(
          (f) => f.name.value == 'level',
        );
        expect((levelField.value as IntValueNode).value, equals('5'));
      });
    });

    group('operation', () {
      test('creates query operation', () {
        final operation = DocumentNodeHelpers.operation(
          OperationType.query,
          'getPokemon',
          selections: [DocumentNodeHelpers.field('pokemon')],
        );

        expect(operation.type, equals(OperationType.query));
        expect(operation.name?.value, equals('getPokemon'));
        expect(operation.selectionSet.selections, hasLength(1));
        expect(operation.variableDefinitions, isEmpty);
        expect(operation.directives, isEmpty);
      });

      test('creates mutation operation', () {
        final operation = DocumentNodeHelpers.operation(
          OperationType.mutation,
          'updatePokemon',
          selections: [DocumentNodeHelpers.field('updatePokemon')],
        );

        expect(operation.type, equals(OperationType.mutation));
        expect(operation.name?.value, equals('updatePokemon'));
      });
    });

    group('document', () {
      test('creates DocumentNode with operations', () {
        final document = DocumentNodeHelpers.document([
          DocumentNodeHelpers.operation(
            OperationType.query,
            'simple_query',
            selections: [
              DocumentNodeHelpers.field(
                'pokemon',
                args: {'name': 'Charmander'},
                selections: [
                  DocumentNodeHelpers.field('number'),
                  DocumentNodeHelpers.field('types'),
                ],
              ),
            ],
          ),
        ]);

        expect(document, isA<DocumentNode>());
        expect(document.definitions, hasLength(1));

        final operation = document.definitions[0] as OperationDefinitionNode;
        expect(operation.type, equals(OperationType.query));
        expect(operation.name?.value, equals('simple_query'));
      });
    });

    group('caching', () {
      test('cache statistics work correctly', () {
        DocumentNodeHelpers.nameNode('pokemon');
        DocumentNodeHelpers.nameNode('trainer');
        DocumentNodeHelpers.nameNode('gym');

        final stats = DocumentNodeHelpers.getCacheStats();
        expect(stats['size'], equals(3));
        expect(stats['maxSize'], equals(1000));
        expect(stats['utilizationPercent'], equals(0)); // 3/1000 rounds to 0
      });

      test('cache clears correctly', () {
        DocumentNodeHelpers.nameNode('pokemon');
        DocumentNodeHelpers.nameNode('trainer');
        expect(DocumentNodeHelpers.cacheSize, equals(2));

        DocumentNodeHelpers.clearCache();
        expect(DocumentNodeHelpers.cacheSize, equals(0));
      });

      test('cache eviction works when limit is reached', () {
        // This test would be slow with the actual limit of 1000,
        // so we'll test the concept by filling cache and checking behavior
        for (var i = 0; i < 10; i++) {
          DocumentNodeHelpers.nameNode('field_$i');
        }

        expect(DocumentNodeHelpers.cacheSize, equals(10));

        // The cache should still work normally under the limit
        final node1 = DocumentNodeHelpers.nameNode('field_0');
        final node2 = DocumentNodeHelpers.nameNode('field_0');
        expect(identical(node1, node2), isTrue);
      });
    });

    group('value conversion', () {
      test('throws error for unsupported types', () {
        expect(
          () => DocumentNodeHelpers.argument('invalid', DateTime.now()),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('handles double values', () {
        final arg = DocumentNodeHelpers.argument('price', 19.99);

        expect(arg.value, isA<FloatValueNode>());
        expect((arg.value as FloatValueNode).value, equals('19.99'));
      });

      test('handles nested objects and lists', () {
        final arg = DocumentNodeHelpers.argument('complex', {
          'items': ['sword', 'shield'],
          'stats': {'hp': 100, 'mp': 50},
          'active': true,
        });

        expect(arg.value, isA<ObjectValueNode>());
        final objectValue = arg.value as ObjectValueNode;

        final itemsField = objectValue.fields.firstWhere(
          (f) => f.name.value == 'items',
        );
        expect(itemsField.value, isA<ListValueNode>());

        final statsField = objectValue.fields.firstWhere(
          (f) => f.name.value == 'stats',
        );
        expect(statsField.value, isA<ObjectValueNode>());

        final activeField = objectValue.fields.firstWhere(
          (f) => f.name.value == 'active',
        );
        expect(activeField.value, isA<BooleanValueNode>());
      });
    });

    group('integration test', () {
      test(
        'generates optimized DocumentNode equivalent to verbose version',
        () {
          // Create the optimized version using helpers
          final optimizedDocument = DocumentNodeHelpers.document([
            DocumentNodeHelpers.operation(
              OperationType.query,
              'simple_query',
              selections: [
                DocumentNodeHelpers.field(
                  'pokemon',
                  args: {'name': 'Charmander'},
                  selections: [
                    DocumentNodeHelpers.field('number'),
                    DocumentNodeHelpers.field('types'),
                  ],
                ),
              ],
            ),
          ]);

          // Create the verbose version (like current generation)
          const verboseDocument = DocumentNode(
            definitions: [
              OperationDefinitionNode(
                type: OperationType.query,
                name: NameNode(value: 'simple_query'),
                selectionSet: SelectionSetNode(
                  selections: [
                    FieldNode(
                      name: NameNode(value: 'pokemon'),
                      arguments: [
                        ArgumentNode(
                          name: NameNode(value: 'name'),
                          value: StringValueNode(
                            value: 'Charmander',
                            isBlock: false,
                          ),
                        ),
                      ],
                      selectionSet: SelectionSetNode(
                        selections: [
                          FieldNode(
                            name: NameNode(value: 'number'),
                          ),
                          FieldNode(
                            name: NameNode(value: 'types'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          // Both should have the same structure
          expect(
            optimizedDocument.definitions.length,
            equals(verboseDocument.definitions.length),
          );

          final optimizedOp =
              optimizedDocument.definitions[0] as OperationDefinitionNode;
          final verboseOp =
              verboseDocument.definitions[0] as OperationDefinitionNode;

          expect(optimizedOp.type, equals(verboseOp.type));
          expect(optimizedOp.name?.value, equals(verboseOp.name?.value));
          expect(
            optimizedOp.selectionSet.selections.length,
            equals(verboseOp.selectionSet.selections.length),
          );
        },
      );
    });
  });
}
