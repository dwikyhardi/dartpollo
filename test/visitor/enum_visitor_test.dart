import 'package:test/test.dart';
import 'package:gql/ast.dart';
import 'package:dartpollo/visitor/enum_visitor.dart';
import 'package:dartpollo/generator/data/enum_definition.dart';

void main() {
  group('EnumVisitor', () {
    late EnumVisitor visitor;

    setUp(() {
      visitor = EnumVisitor();
    });

    test('should implement BaseVisitor interface', () {
      expect(visitor.result, isA<List<EnumDefinition>>());
      expect(visitor.result, isEmpty);
    });

    test('should reset properly', () {
      visitor.reset();
      expect(visitor.result, isEmpty);
    });

    test('should handle enum type definition nodes', () {
      final enumNode = EnumTypeDefinitionNode(
        name: NameNode(value: 'TestEnum'),
        values: [],
      );
      final documentNode = DocumentNode(definitions: []);

      expect(visitor.canHandle(enumNode), isTrue);
      expect(visitor.canHandle(documentNode), isTrue);
      expect(visitor.canHandle(NameNode(value: 'test')), isFalse);
    });

    test('should visit enum type definition nodes', () {
      final enumNode = EnumTypeDefinitionNode(
        name: NameNode(value: 'TestEnum'),
        values: [
          EnumValueDefinitionNode(name: NameNode(value: 'VALUE1')),
          EnumValueDefinitionNode(name: NameNode(value: 'VALUE2')),
        ],
      );

      // Should not throw when visiting
      expect(
          () => visitor.visitEnumTypeDefinitionNode(enumNode), returnsNormally);
    });

    test('should maintain immutable result', () {
      final result1 = visitor.result;
      final result2 = visitor.result;

      expect(identical(result1, result2), isFalse);
      expect(result1, equals(result2));
    });

    test('should handle document nodes', () {
      final document = DocumentNode(definitions: [
        EnumTypeDefinitionNode(
          name: NameNode(value: 'TestEnum'),
          values: [],
        ),
      ]);

      expect(visitor.canHandle(document), isTrue);
      expect(() => document.accept(visitor), returnsNormally);
    });
  });
}
