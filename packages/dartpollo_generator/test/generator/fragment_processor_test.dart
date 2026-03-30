import 'package:dartpollo_annotation/schema/schema_options.dart';
import 'package:dartpollo_generator/generator/data/data.dart';
import 'package:dartpollo_generator/generator/ephemeral_data.dart';
import 'package:dartpollo_generator/generator/fragment_processor.dart';
import 'package:dartpollo_generator/visitor/type_definition_node_visitor.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:test/test.dart';

void main() {
  group('FragmentProcessor', () {
    group('extractFragments', () {
      test('should return empty set when selectionSet is null', () {
        final result = FragmentProcessor.extractFragments(null, []);
        expect(result, isEmpty);
      });

      test('should return empty set when selectionSet has no fragments', () {
        final selectionSet =
            parseString('''
          {
            field1
            field2
          }
        ''').definitions.first
                as OperationDefinitionNode;

        final result = FragmentProcessor.extractFragments(
          selectionSet.selectionSet,
          [],
        );
        expect(result, isEmpty);
      });

      test('should extract fragment spreads from selection set', () {
        final document = parseString('''
          fragment TestFragment on User {
            id
            name
          }
          
          query {
            user {
              ...TestFragment
            }
          }
        ''');

        final fragment = document.definitions
            .whereType<FragmentDefinitionNode>()
            .first;
        final operation = document.definitions
            .whereType<OperationDefinitionNode>()
            .first;

        final result = FragmentProcessor.extractFragments(
          operation.selectionSet,
          [fragment],
        );

        expect(result, hasLength(1));
        expect(result.first.name.value, equals('TestFragment'));
      });

      test('should extract nested fragments recursively', () {
        final document = parseString('''
          fragment UserDetails on User {
            id
            name
          }
          
          fragment UserWithDetails on User {
            email
            ...UserDetails
          }
          
          query {
            user {
              ...UserWithDetails
            }
          }
        ''');

        final fragments = document.definitions
            .whereType<FragmentDefinitionNode>()
            .toList();
        final operation = document.definitions
            .whereType<OperationDefinitionNode>()
            .first;

        final result = FragmentProcessor.extractFragments(
          operation.selectionSet,
          fragments,
        );

        expect(result, hasLength(2));
        final fragmentNames = result.map((f) => f.name.value).toSet();
        expect(fragmentNames, containsAll(['UserDetails', 'UserWithDetails']));
      });

      test('should handle inline fragments', () {
        final document = parseString('''
          fragment TestFragment on User {
            id
          }
          
          query {
            node {
              ... on User {
                name
                ...TestFragment
              }
            }
          }
        ''');

        final fragment = document.definitions
            .whereType<FragmentDefinitionNode>()
            .first;
        final operation = document.definitions
            .whereType<OperationDefinitionNode>()
            .first;

        final result = FragmentProcessor.extractFragments(
          operation.selectionSet,
          [fragment],
        );

        expect(result, hasLength(1));
        expect(result.first.name.value, equals('TestFragment'));
      });

      test('should handle deeply nested field selections with fragments', () {
        final document = parseString('''
          fragment UserFragment on User {
            id
            name
          }
          
          query {
            posts {
              author {
                ...UserFragment
              }
            }
          }
        ''');

        final fragment = document.definitions
            .whereType<FragmentDefinitionNode>()
            .first;
        final operation = document.definitions
            .whereType<OperationDefinitionNode>()
            .first;

        final result = FragmentProcessor.extractFragments(
          operation.selectionSet,
          [fragment],
        );

        expect(result, hasLength(1));
        expect(result.first.name.value, equals('UserFragment'));
      });

      test('should handle multiple fragment spreads', () {
        final document = parseString('''
          fragment UserBasics on User {
            id
            name
          }
          
          fragment UserDetails on User {
            email
            phone
          }
          
          query {
            user {
              ...UserBasics
              ...UserDetails
            }
          }
        ''');

        final fragments = document.definitions
            .whereType<FragmentDefinitionNode>()
            .toList();
        final operation = document.definitions
            .whereType<OperationDefinitionNode>()
            .first;

        final result = FragmentProcessor.extractFragments(
          operation.selectionSet,
          fragments,
        );

        expect(result, hasLength(2));
        final fragmentNames = result.map((f) => f.name.value).toSet();
        expect(fragmentNames, containsAll(['UserBasics', 'UserDetails']));
      });

      test(
        'should handle fragments that reference non-existent fragments gracefully',
        () {
          final document = parseString('''
          query {
            user {
              ...NonExistentFragment
            }
          }
        ''');

          final operation = document.definitions
              .whereType<OperationDefinitionNode>()
              .first;

          final result = FragmentProcessor.extractFragments(
            operation.selectionSet,
            [], // No fragments available
          );

          expect(result, isEmpty);
        },
      );
    });

    group('processFragments', () {
      late Context context;

      setUp(() {
        final schema = parseString('''
          type User {
            id: ID!
            name: String
            email: String
          }
        ''');

        final typeVisitor = TypeDefinitionNodeVisitor();
        schema.accept(typeVisitor);

        context = Context(
          schema: schema,
          typeDefinitionNodeVisitor: typeVisitor,
          options: GeneratorOptions(),
          schemaMap: SchemaMap(),
          path: [],
          currentType: null,
          currentFieldName: null,
          currentClassName: null,
          generatedClasses: [],
          inputsClasses: [],
          fragments: [],
          usedEnums: {},
          usedInputObjects: {},
        );
      });

      test('should return empty list when no fragments provided', () {
        final result = FragmentProcessor.processFragments([], context);
        expect(result, isEmpty);
      });

      test('should process single fragment into FragmentClassDefinition', () {
        final document = parseString('''
          fragment UserFragment on User {
            id
            name
          }
        ''');

        final fragment = document.definitions
            .whereType<FragmentDefinitionNode>()
            .first;

        final result = FragmentProcessor.processFragments([fragment], context);

        expect(result, hasLength(1));
        expect(result.first.name.namePrintable, equals('UserFragmentMixin'));
        expect(result.first, isA<FragmentClassDefinition>());
      });

      test('should process multiple fragments', () {
        final document = parseString('''
          fragment UserBasics on User {
            id
            name
          }
          
          fragment UserDetails on User {
            email
          }
        ''');

        final fragments = document.definitions
            .whereType<FragmentDefinitionNode>()
            .toList();

        final result = FragmentProcessor.processFragments(fragments, context);

        expect(result, hasLength(2));
        expect(result[0].name.namePrintable, equals('UserBasicsMixin'));
        expect(result[1].name.namePrintable, equals('UserDetailsMixin'));
      });

      test('should handle fragments with complex names', () {
        final document = parseString('''
          fragment user_profile_data on User {
            id
            name
          }
        ''');

        final fragment = document.definitions
            .whereType<FragmentDefinitionNode>()
            .first;

        final result = FragmentProcessor.processFragments([fragment], context);

        expect(result, hasLength(1));
        expect(result.first.name.namePrintable, equals('UserProfileDataMixin'));
      });
    });
  });
}
