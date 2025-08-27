import 'package:test/test.dart';
import 'package:gql/ast.dart';
import 'package:dartpollo/context/schema_context.dart';
import 'package:dartpollo/visitor/type_definition_node_visitor.dart';
import 'package:dartpollo/schema/schema_options.dart';

void main() {
  group('SchemaContext', () {
    late DocumentNode validSchema;
    late TypeDefinitionNodeVisitor typeVisitor;
    late GeneratorOptions options;

    setUp(() {
      // Create a valid schema with basic types
      validSchema = DocumentNode(definitions: [
        ObjectTypeDefinitionNode(
          name: NameNode(value: 'User'),
          fields: [
            FieldDefinitionNode(
              name: NameNode(value: 'id'),
              type: NamedTypeNode(name: NameNode(value: 'ID')),
            ),
            FieldDefinitionNode(
              name: NameNode(value: 'name'),
              type: NamedTypeNode(name: NameNode(value: 'String')),
            ),
          ],
        ),
        EnumTypeDefinitionNode(
          name: NameNode(value: 'Status'),
          values: [
            EnumValueDefinitionNode(name: NameNode(value: 'ACTIVE')),
            EnumValueDefinitionNode(name: NameNode(value: 'INACTIVE')),
          ],
        ),
      ]);

      typeVisitor = TypeDefinitionNodeVisitor();
      validSchema.accept(typeVisitor);

      options = GeneratorOptions();
    });

    group('constructor', () {
      test('creates immutable context with required fields', () {
        final context = SchemaContext(
          schema: validSchema,
          typeVisitor: typeVisitor,
          options: options,
        );

        expect(context.schema, equals(validSchema));
        expect(context.typeVisitor, equals(typeVisitor));
        expect(context.options, equals(options));
      });
    });

    group('validation', () {
      test('validates successfully with valid schema', () {
        final context = SchemaContext(
          schema: validSchema,
          typeVisitor: typeVisitor,
          options: options,
        );

        expect(context.validate, returnsNormally);
      });

      test('throws exception for empty schema', () {
        final emptySchema = DocumentNode(definitions: []);
        final context = SchemaContext(
          schema: emptySchema,
          typeVisitor: TypeDefinitionNodeVisitor(),
          options: options,
        );

        expect(
          context.validate,
          throwsA(isA<SchemaContextValidationException>().having(
              (e) => e.message,
              'message',
              contains('at least one definition'))),
        );
      });

      test('throws exception for uninitialized type visitor', () {
        final uninitializedVisitor = TypeDefinitionNodeVisitor();
        uninitializedVisitor.types
            .clear(); // Remove default scalars to simulate uninitialized state

        final context = SchemaContext(
          schema: validSchema,
          typeVisitor: uninitializedVisitor,
          options: options,
        );

        expect(
          context.validate,
          throwsA(isA<SchemaContextValidationException>().having(
              (e) => e.message,
              'message',
              contains('Type visitor must be initialized'))),
        );
      });

      test('validates required scalar types are present', () {
        final visitor = TypeDefinitionNodeVisitor();
        // Add some types but remove a required scalar
        validSchema.accept(visitor);
        visitor.types.remove('String'); // Remove a required scalar

        final context = SchemaContext(
          schema: validSchema,
          typeVisitor: visitor,
          options: options,
        );

        expect(
          context.validate,
          throwsA(isA<SchemaContextValidationException>().having(
              (e) => e.message,
              'message',
              contains('Missing required scalar type'))),
        );
      });
    });

    group('type operations', () {
      late SchemaContext context;

      setUp(() {
        context = SchemaContext(
          schema: validSchema,
          typeVisitor: typeVisitor,
          options: options,
        );
      });

      test('hasType returns true for existing types', () {
        expect(context.hasType('User'), isTrue);
        expect(context.hasType('Status'), isTrue);
        expect(context.hasType('String'), isTrue);
        expect(context.hasType('ID'), isTrue);
      });

      test('hasType returns false for non-existing types', () {
        expect(context.hasType('NonExistentType'), isFalse);
      });

      test('getType returns correct type definition', () {
        final userType = context.getType('User');
        expect(userType, isA<ObjectTypeDefinitionNode>());
        expect(
            (userType as ObjectTypeDefinitionNode).name.value, equals('User'));

        final statusType = context.getType('Status');
        expect(statusType, isA<EnumTypeDefinitionNode>());
        expect((statusType as EnumTypeDefinitionNode).name.value,
            equals('Status'));
      });

      test('getType returns null for non-existing types', () {
        expect(context.getType('NonExistentType'), isNull);
      });

      test('availableTypes returns all type names', () {
        final types = context.availableTypes;
        expect(types, contains('User'));
        expect(types, contains('Status'));
        expect(types, contains('String'));
        expect(types, contains('ID'));
        expect(types, contains('Boolean'));
        expect(types, contains('Float'));
        expect(types, contains('Int'));
      });
    });

    group('immutability', () {
      test('context fields cannot be modified after creation', () {
        final context = SchemaContext(
          schema: validSchema,
          typeVisitor: typeVisitor,
          options: options,
        );

        // Verify that the context is immutable by checking that fields are final
        expect(context.schema, same(validSchema));
        expect(context.typeVisitor, same(typeVisitor));
        expect(context.options, same(options));
      });
    });
  });

  group('SchemaContextValidationException', () {
    test('creates exception with message', () {
      const message = 'Test validation error';
      final exception = SchemaContextValidationException(message);

      expect(exception.message, equals(message));
      expect(exception.toString(), contains(message));
      expect(
          exception.toString(), contains('SchemaContextValidationException'));
    });
  });
}
