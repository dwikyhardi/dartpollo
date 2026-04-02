import 'package:dartpollo_annotation/schema/schema_options.dart';
import 'package:dartpollo_generator/generator/data/fragment_class_definition.dart';
import 'package:dartpollo_generator/visitor/fragment_visitor.dart';
import 'package:dartpollo_generator/visitor/type_definition_node_visitor.dart';
import 'package:gql/ast.dart';
import 'package:test/test.dart';

void main() {
  group('FragmentVisitor', () {
    late FragmentVisitor visitor;
    late TypeDefinitionNodeVisitor typeDefinitionVisitor;
    late GeneratorOptions options;

    setUp(() {
      typeDefinitionVisitor = TypeDefinitionNodeVisitor();
      options = GeneratorOptions();
      visitor = FragmentVisitor(
        typeDefinitionVisitor: typeDefinitionVisitor,
        options: options,
      );
    });

    test('should implement BaseVisitor interface', () {
      expect(visitor.result, isA<List<FragmentClassDefinition>>());
      expect(visitor.result, isEmpty);
    });

    test('should reset properly', () {
      visitor.reset();
      expect(visitor.result, isEmpty);
    });

    test('should handle fragment definition nodes', () {
      const fragmentNode = FragmentDefinitionNode(
        name: NameNode(value: 'TestFragment'),
        typeCondition: TypeConditionNode(
          on: NamedTypeNode(name: NameNode(value: 'TestType')),
        ),
        selectionSet: SelectionSetNode(),
      );
      const documentNode = DocumentNode();

      expect(visitor.canHandle(fragmentNode), isTrue);
      expect(visitor.canHandle(documentNode), isTrue);
      expect(visitor.canHandle(const NameNode(value: 'test')), isFalse);
    });

    test('should visit fragment definition nodes', () {
      // Add a test type to the type definition visitor
      const testType = ObjectTypeDefinitionNode(
        name: NameNode(value: 'TestType'),
        fields: [
          FieldDefinitionNode(
            name: NameNode(value: 'field1'),
            type: NamedTypeNode(name: NameNode(value: 'String')),
          ),
        ],
      );
      typeDefinitionVisitor.types['TestType'] = testType;

      const fragmentNode = FragmentDefinitionNode(
        name: NameNode(value: 'TestFragment'),
        typeCondition: TypeConditionNode(
          on: NamedTypeNode(name: NameNode(value: 'TestType')),
        ),
        selectionSet: SelectionSetNode(
          selections: [
            FieldNode(name: NameNode(value: 'field1')),
          ],
        ),
      );

      // Should not throw when visiting
      expect(
        () => visitor.visitFragmentDefinitionNode(fragmentNode),
        returnsNormally,
      );

      // Should have created a fragment definition
      expect(visitor.result, hasLength(1));
      expect(
        visitor.result.first.name.namePrintable,
        equals('TestFragmentMixin'),
      );
    });

    test('should maintain immutable result', () {
      final result1 = visitor.result;
      final result2 = visitor.result;

      expect(identical(result1, result2), isFalse);
      expect(result1, equals(result2));
    });

    test('should handle document nodes', () {
      // Add a test type to the type definition visitor
      const testType = ObjectTypeDefinitionNode(
        name: NameNode(value: 'TestType'),
      );
      typeDefinitionVisitor.types['TestType'] = testType;

      const document = DocumentNode(
        definitions: [
          FragmentDefinitionNode(
            name: NameNode(value: 'TestFragment'),
            typeCondition: TypeConditionNode(
              on: NamedTypeNode(name: NameNode(value: 'TestType')),
            ),
            selectionSet: SelectionSetNode(),
          ),
        ],
      );

      expect(visitor.canHandle(document), isTrue);
      expect(() => document.accept(visitor), returnsNormally);
    });
  });
}
