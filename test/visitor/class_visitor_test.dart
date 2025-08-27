import 'package:test/test.dart';
import 'package:gql/ast.dart';
import 'package:dartpollo/visitor/class_visitor.dart';
import 'package:dartpollo/generator/data/class_definition.dart';

void main() {
  group('ClassVisitor', () {
    late ClassVisitor visitor;

    setUp(() {
      visitor = ClassVisitor();
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
  });
}
