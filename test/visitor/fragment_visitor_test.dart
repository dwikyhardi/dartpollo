import 'package:test/test.dart';
import 'package:gql/ast.dart';
import 'package:dartpollo/visitor/fragment_visitor.dart';
import 'package:dartpollo/generator/data/fragment_class_definition.dart';

void main() {
  group('FragmentVisitor', () {
    late FragmentVisitor visitor;

    setUp(() {
      visitor = FragmentVisitor();
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
      final fragmentNode = FragmentDefinitionNode(
        name: NameNode(value: 'TestFragment'),
        typeCondition: TypeConditionNode(
            on: NamedTypeNode(name: NameNode(value: 'TestType'))),
        selectionSet: SelectionSetNode(selections: []),
      );
      final documentNode = DocumentNode(definitions: []);

      expect(visitor.canHandle(fragmentNode), isTrue);
      expect(visitor.canHandle(documentNode), isTrue);
      expect(visitor.canHandle(NameNode(value: 'test')), isFalse);
    });

    test('should visit fragment definition nodes', () {
      final fragmentNode = FragmentDefinitionNode(
        name: NameNode(value: 'TestFragment'),
        typeCondition: TypeConditionNode(
            on: NamedTypeNode(name: NameNode(value: 'TestType'))),
        selectionSet: SelectionSetNode(selections: [
          FieldNode(name: NameNode(value: 'field1')),
        ]),
      );

      // Should not throw when visiting
      expect(() => visitor.visitFragmentDefinitionNode(fragmentNode),
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
        FragmentDefinitionNode(
          name: NameNode(value: 'TestFragment'),
          typeCondition: TypeConditionNode(
              on: NamedTypeNode(name: NameNode(value: 'TestType'))),
          selectionSet: SelectionSetNode(selections: []),
        ),
      ]);

      expect(visitor.canHandle(document), isTrue);
      expect(() => document.accept(visitor), returnsNormally);
    });
  });
}
