import 'package:dartpollo_annotation/schema/schema_options.dart';
import 'package:dartpollo_generator/visitor/fragment_visitor.dart';
import 'package:dartpollo_generator/visitor/type_definition_node_visitor.dart';
import 'package:gql/language.dart';
import 'package:test/test.dart';

void main() {
  group('FragmentVisitor Integration', () {
    late FragmentVisitor visitor;
    late TypeDefinitionNodeVisitor typeDefinitionVisitor;

    setUp(() {
      typeDefinitionVisitor = TypeDefinitionNodeVisitor();
      final options = GeneratorOptions();
      visitor = FragmentVisitor(
        typeDefinitionVisitor: typeDefinitionVisitor,
        options: options,
      );

      // Set up a simple schema
    });

    test('should process fragment with multiple fields', () {
      expect(visitor.result, hasLength(1));
      final fragment = visitor.result.first;

      expect(fragment.name.namePrintable, equals('UserInfoMixin'));
      expect(fragment.properties, hasLength(3));

      final propertyNames = fragment.properties
          .map((p) => p.name.name)
          .toList();
      expect(propertyNames, containsAll(['id', 'name', 'email']));
    });

    test('should process fragment with nested object field', () {
      expect(visitor.result, hasLength(1));
      final fragment = visitor.result.first;

      expect(fragment.name.namePrintable, equals('PostInfoMixin'));
      expect(fragment.properties, hasLength(3));

      final propertyNames = fragment.properties
          .map((p) => p.name.name)
          .toList();
      expect(propertyNames, containsAll(['id', 'title', 'author']));
    });

    test('should handle multiple fragments in one document', () {
      expect(visitor.result, hasLength(2));

      final fragmentNames = visitor.result
          .map((f) => f.name.namePrintable)
          .toList();
      expect(
        fragmentNames,
        containsAll(['UserBasicMixin', 'UserContactMixin']),
      );
    });

    test('should skip empty fragments', () {
      // Add an empty fragment (no fields selected)

      // Should not create any fragment definitions for empty fragments
      expect(visitor.result, isEmpty);
    });

    test('should reset properly between uses', () {
      final fragmentDocument1 = parseString('''
        fragment UserInfo on User {
          id
          name
        }
      ''');

      final fragmentDocument2 = parseString('''
        fragment PostInfo on Post {
          id
          title
        }
      ''');

      // Process first document
      fragmentDocument1.accept(visitor);
      expect(visitor.result, hasLength(1));

      // Reset and process second document
      visitor.reset();
      fragmentDocument2.accept(visitor);
      expect(visitor.result, hasLength(1));
      expect(visitor.result.first.name.namePrintable, equals('PostInfoMixin'));
    });
  });
}
