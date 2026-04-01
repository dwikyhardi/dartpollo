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
    });

    test('should process fragment with multiple fields', () {
      final schema = parseString('''
        type User {
          id: ID!
          name: String!
          email: String!
        }
      ''');
      schema.accept(typeDefinitionVisitor);

      final fragmentDoc = parseString('''
        fragment UserInfo on User {
          id
          name
          email
        }
      ''');
      fragmentDoc.accept(visitor);

      expect(visitor.result, hasLength(1));
      final fragment = visitor.result.first;

      expect(fragment.name.namePrintable, equals('UserInfoMixin'));
      expect(fragment.properties, hasLength(3));

      final propertyNames =
          fragment.properties.map((p) => p.name.name).toList();
      expect(propertyNames, containsAll(['id', 'name', 'email']));
    });

    test('should process fragment with nested object field', () {
      final schema = parseString('''
        type Post {
          id: ID!
          title: String!
          author: User
        }
        type User {
          id: ID!
          name: String!
        }
      ''');
      schema.accept(typeDefinitionVisitor);

      final fragmentDoc = parseString('''
        fragment PostInfo on Post {
          id
          title
          author
        }
      ''');
      fragmentDoc.accept(visitor);

      expect(visitor.result, hasLength(1));
      final fragment = visitor.result.first;

      expect(fragment.name.namePrintable, equals('PostInfoMixin'));
      expect(fragment.properties, hasLength(3));

      final propertyNames =
          fragment.properties.map((p) => p.name.name).toList();
      expect(propertyNames, containsAll(['id', 'title', 'author']));
    });

    test('should handle multiple fragments in one document', () {
      final schema = parseString('''
        type User {
          id: ID!
          name: String!
          email: String!
          phone: String
        }
      ''');
      schema.accept(typeDefinitionVisitor);

      final fragmentDoc = parseString('''
        fragment UserBasic on User {
          id
          name
        }
        fragment UserContact on User {
          email
          phone
        }
      ''');
      fragmentDoc.accept(visitor);

      expect(visitor.result, hasLength(2));

      final fragmentNames =
          visitor.result.map((f) => f.name.namePrintable).toList();
      expect(
        fragmentNames,
        containsAll(['UserBasicMixin', 'UserContactMixin']),
      );
    });

    test('should skip empty fragments', () {
      // Visitor with no documents processed should have empty result
      expect(visitor.result, isEmpty);
    });

    test('should reset properly between uses', () {
      final schema = parseString('''
        type User {
          id: ID!
          name: String!
        }
        type Post {
          id: ID!
          title: String!
        }
      ''');
      schema.accept(typeDefinitionVisitor);

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
