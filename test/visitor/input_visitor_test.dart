import 'package:dartpollo/generator/data/class_definition.dart';
import 'package:dartpollo/schema/schema_options.dart';
import 'package:dartpollo/visitor/input_visitor.dart';
import 'package:dartpollo/visitor/type_definition_node_visitor.dart';
import 'package:gql/ast.dart';
import 'package:test/test.dart';

void main() {
  group('InputVisitor', () {
    late InputVisitor visitor;
    late TypeDefinitionNodeVisitor typeDefinitionVisitor;
    late GeneratorOptions options;

    setUp(() {
      typeDefinitionVisitor = TypeDefinitionNodeVisitor();
      options = GeneratorOptions();
      visitor = InputVisitor(
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

    test('should handle input object type definition nodes', () {
      const inputNode = InputObjectTypeDefinitionNode(
        name: NameNode(value: 'TestInput'),
      );
      const documentNode = DocumentNode();

      expect(visitor.canHandle(inputNode), isTrue);
      expect(visitor.canHandle(documentNode), isTrue);
      expect(visitor.canHandle(const NameNode(value: 'test')), isFalse);
    });

    test('should visit input object type definition nodes', () {
      const inputNode = InputObjectTypeDefinitionNode(
        name: NameNode(value: 'TestInput'),
        fields: [
          InputValueDefinitionNode(
            name: NameNode(value: 'field1'),
            type: NamedTypeNode(name: NameNode(value: 'String')),
          ),
        ],
      );

      // Should not throw when visiting
      expect(
        () => visitor.visitInputObjectTypeDefinitionNode(inputNode),
        returnsNormally,
      );
    });

    test('should maintain immutable result', () {
      final result1 = visitor.result;
      final result2 = visitor.result;

      expect(identical(result1, result2), isFalse);
      expect(result1, equals(result2));
    });

    test('should handle document nodes', () {
      const document = DocumentNode(
        definitions: [
          InputObjectTypeDefinitionNode(
            name: NameNode(value: 'TestInput'),
          ),
        ],
      );

      expect(visitor.canHandle(document), isTrue);
      expect(() => document.accept(visitor), returnsNormally);
    });
  });
}
