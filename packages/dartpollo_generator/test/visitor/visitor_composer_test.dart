import 'package:dartpollo_annotation/schema/schema_options.dart';
import 'package:dartpollo_generator/generator/data/class_definition.dart';
import 'package:dartpollo_generator/generator/data/enum_definition.dart';
import 'package:dartpollo_generator/generator/data/fragment_class_definition.dart';
import 'package:dartpollo_generator/visitor/class_visitor.dart';
import 'package:dartpollo_generator/visitor/enum_visitor.dart';
import 'package:dartpollo_generator/visitor/fragment_visitor.dart';
import 'package:dartpollo_generator/visitor/input_visitor.dart';
import 'package:dartpollo_generator/visitor/type_definition_node_visitor.dart';
import 'package:dartpollo_generator/visitor/visitor_composer.dart';
import 'package:gql/ast.dart';
import 'package:test/test.dart';

void main() {
  group('VisitorComposer', () {
    late VisitorComposer composer;
    late EnumVisitor enumVisitor;
    late ClassVisitor classVisitor;
    late InputVisitor inputVisitor;
    late FragmentVisitor fragmentVisitor;

    setUp(() {
      final typeDefinitionVisitor = TypeDefinitionNodeVisitor();
      final options = GeneratorOptions();

      // Add test type for fragment visitor
      const testType = ObjectTypeDefinitionNode(
        name: NameNode(value: 'TestType'),
      );
      typeDefinitionVisitor.types['TestType'] = testType;

      enumVisitor = EnumVisitor();
      classVisitor = ClassVisitor(
        typeDefinitionVisitor: typeDefinitionVisitor,
        options: options,
      );
      inputVisitor = InputVisitor(
        typeDefinitionVisitor: typeDefinitionVisitor,
        options: options,
      );
      fragmentVisitor = FragmentVisitor(
        typeDefinitionVisitor: typeDefinitionVisitor,
        options: options,
      );

      composer = VisitorComposer([
        enumVisitor,
        classVisitor,
        inputVisitor,
        fragmentVisitor,
      ]);
    });

    test('should initialize with visitors', () {
      expect(composer.visitors, hasLength(4));
      expect(composer.visitors, contains(enumVisitor));
      expect(composer.visitors, contains(classVisitor));
      expect(composer.visitors, contains(inputVisitor));
      expect(composer.visitors, contains(fragmentVisitor));
    });

    test('should visit document with all applicable visitors', () {
      const document = DocumentNode(
        definitions: [
          EnumTypeDefinitionNode(
            name: NameNode(value: 'TestEnum'),
            values: [
              EnumValueDefinitionNode(name: NameNode(value: 'VALUE1')),
            ],
          ),
          ObjectTypeDefinitionNode(
            name: NameNode(value: 'TestObject'),
          ),
          InputObjectTypeDefinitionNode(
            name: NameNode(value: 'TestInput'),
          ),
          FragmentDefinitionNode(
            name: NameNode(value: 'TestFragment'),
            typeCondition: TypeConditionNode(
              on: NamedTypeNode(name: NameNode(value: 'TestType')),
            ),
            selectionSet: SelectionSetNode(),
          ),
        ],
      );

      // Should not throw when visiting
      expect(() => composer.visitDocument(document), returnsNormally);
    });

    test('should get result from specific visitor type', () {
      final enumResult = composer.getResult<List<EnumDefinition>>(EnumVisitor);
      final classResult = composer.getResult<List<ClassDefinition>>(
        ClassVisitor,
      );
      final inputResult = composer.getResult<List<ClassDefinition>>(
        InputVisitor,
      );
      final fragmentResult = composer.getResult<List<FragmentClassDefinition>>(
        FragmentVisitor,
      );

      expect(enumResult, isA<List<EnumDefinition>>());
      expect(classResult, isA<List<ClassDefinition>>());
      expect(inputResult, isA<List<ClassDefinition>>());
      expect(fragmentResult, isA<List<FragmentClassDefinition>>());
    });

    test('should throw when visitor type not found', () {
      final emptyComposer = VisitorComposer([]);

      expect(
        () => emptyComposer.getResult<List<EnumDefinition>>(EnumVisitor),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Visitor of type EnumVisitor not found'),
          ),
        ),
      );
    });

    test('should throw when result type is incorrect', () {
      expect(
        () => composer.getResult<String>(EnumVisitor),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Visitor result is not of expected type String'),
          ),
        ),
      );
    });

    test('should only visit with visitors that can handle the document', () {
      const document = DocumentNode();

      // All visitors should be able to handle DocumentNode
      expect(() => composer.visitDocument(document), returnsNormally);
    });

    test('should handle empty visitor list', () {
      final emptyComposer = VisitorComposer([]);
      const document = DocumentNode();

      expect(() => emptyComposer.visitDocument(document), returnsNormally);
    });

    test('should handle visitors that cannot handle the document', () {
      // Create a document with a node type that none of our visitors handle
      const document = DocumentNode(
        definitions: [
          SchemaDefinitionNode(),
        ],
      );

      // Should still work, just won't visit with any visitors
      expect(() => composer.visitDocument(document), returnsNormally);
    });
  });
}
