import 'package:test/test.dart';
import 'package:gql/ast.dart';
import 'package:dartpollo/visitor/class_visitor.dart';
import 'package:dartpollo/generator/data/class_definition.dart';
import 'package:dartpollo/visitor/type_definition_node_visitor.dart';
import 'package:dartpollo/schema/schema_options.dart';

void main() {
  group('ClassVisitor', () {
    late ClassVisitor visitor;
    late TypeDefinitionNodeVisitor typeDefinitionVisitor;
    late GeneratorOptions options;

    setUp(() {
      typeDefinitionVisitor = TypeDefinitionNodeVisitor();
      options = GeneratorOptions();
      visitor = ClassVisitor(
        typeDefinitionVisitor: typeDefinitionVisitor,
        options: options,
      );
    });

    test('should implement BaseVisitor interface', () {
      expect(visitor.result, isA<List<ClassDefinition>>());
      expect(visitor.result, isEmpty);
    });

    test('should reset properly', () {
      visitor.reset();
      expect(visitor.result, isEmpty);
    });

    test('should handle object type definition nodes', () {
      final objectNode = ObjectTypeDefinitionNode(
        name: NameNode(value: 'TestObject'),
        fields: [],
      );
      final documentNode = DocumentNode(definitions: []);

      expect(visitor.canHandle(objectNode), isTrue);
      expect(visitor.canHandle(documentNode), isTrue);
      expect(visitor.canHandle(NameNode(value: 'test')), isFalse);
    });

    test('should visit object type definition nodes', () {
      final objectNode = ObjectTypeDefinitionNode(
        name: NameNode(value: 'TestObject'),
        fields: [
          FieldDefinitionNode(
            name: NameNode(value: 'field1'),
            type: NamedTypeNode(name: NameNode(value: 'String')),
          ),
        ],
      );

      // Should not throw when visiting
      expect(() => visitor.visitObjectTypeDefinitionNode(objectNode),
          returnsNormally);
    });

    test('should maintain immutable result', () {
      final result1 = visitor.result;
      final result2 = visitor.result;

      expect(identical(result1, result2), isFalse);
      expect(result1, equals(result2));
    });

    test('should handle document nodes', () {
      final document = DocumentNode(definitions: [
        ObjectTypeDefinitionNode(
          name: NameNode(value: 'TestObject'),
          fields: [],
        ),
      ]);

      expect(visitor.canHandle(document), isTrue);
      expect(() => document.accept(visitor), returnsNormally);
    });

    test('should create class definition from object type definition', () {
      final objectNode = ObjectTypeDefinitionNode(
        name: NameNode(value: 'User'),
        fields: [
          FieldDefinitionNode(
            name: NameNode(value: 'id'),
            type: NamedTypeNode(
              name: NameNode(value: 'ID'),
              isNonNull: true,
            ),
          ),
          FieldDefinitionNode(
            name: NameNode(value: 'name'),
            type: NamedTypeNode(
              name: NameNode(value: 'String'),
              isNonNull: false,
            ),
          ),
        ],
      );

      visitor.visitObjectTypeDefinitionNode(objectNode);

      expect(visitor.result, hasLength(1));
      final classDefinition = visitor.result.first;
      expect(classDefinition.name.name, equals('User'));
      expect(classDefinition.properties, hasLength(2));

      final idProperty = classDefinition.properties.first;
      expect(idProperty.name.name, equals('id'));
      expect(idProperty.type.name,
          equals('String')); // ID maps to String by default
      expect(idProperty.type.isNonNull, isTrue);

      final nameProperty = classDefinition.properties.last;
      expect(nameProperty.name.name, equals('name'));
      expect(nameProperty.type.name, equals('String'));
      expect(nameProperty.type.isNonNull, isFalse);
    });

    test('should handle multiple object type definitions', () {
      final userNode = ObjectTypeDefinitionNode(
        name: NameNode(value: 'User'),
        fields: [
          FieldDefinitionNode(
            name: NameNode(value: 'id'),
            type: NamedTypeNode(name: NameNode(value: 'ID')),
          ),
        ],
      );

      final postNode = ObjectTypeDefinitionNode(
        name: NameNode(value: 'Post'),
        fields: [
          FieldDefinitionNode(
            name: NameNode(value: 'title'),
            type: NamedTypeNode(name: NameNode(value: 'String')),
          ),
        ],
      );

      visitor.visitObjectTypeDefinitionNode(userNode);
      visitor.visitObjectTypeDefinitionNode(postNode);

      expect(visitor.result, hasLength(2));
      expect(visitor.result.map((c) => c.name.name),
          containsAll(['User', 'Post']));
    });
  });
}
