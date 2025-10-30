import 'package:dartpollo/context/generation_context.dart';
import 'package:dartpollo/generator/data/data.dart';
import 'package:dartpollo/schema/schema_options.dart';
import 'package:gql/ast.dart';
import 'package:test/test.dart';

void main() {
  group('GenerationContext', () {
    late SchemaMap schemaMap;
    late List<TypeName> path;
    late List<Definition> generatedClasses;
    late List<QueryInput> inputsClasses;
    late List<FragmentDefinitionNode> fragments;
    late Set<EnumName> usedEnums;
    late Set<ClassName> usedInputObjects;

    setUp(() {
      schemaMap = SchemaMap(schema: 'test schema');
      path = [TypeName(name: 'Query'), TypeName(name: 'User')];
      generatedClasses = [];
      inputsClasses = [];
      fragments = [];
      usedEnums = <EnumName>{};
      usedInputObjects = <ClassName>{};
    });

    group('constructor', () {
      test('creates immutable context with required fields', () {
        final context = GenerationContext(
          schemaMap: schemaMap,
          path: path,
          generatedClasses: generatedClasses,
          inputsClasses: inputsClasses,
          fragments: fragments,
          usedEnums: usedEnums,
          usedInputObjects: usedInputObjects,
        );

        expect(context.schemaMap, equals(schemaMap));
        expect(context.path, equals(path));
        expect(context.generatedClasses, equals(generatedClasses));
        expect(context.inputsClasses, equals(inputsClasses));
        expect(context.fragments, equals(fragments));
        expect(context.usedEnums, equals(usedEnums));
        expect(context.usedInputObjects, equals(usedInputObjects));
      });

      test('creates context with optional fields', () {
        const currentType = ObjectTypeDefinitionNode(
          name: NameNode(value: 'User'),
        );
        const currentFieldName = ClassPropertyName(name: 'name');
        final currentClassName = ClassName(name: 'UserClass');

        final context = GenerationContext(
          schemaMap: schemaMap,
          path: path,
          currentType: currentType,
          currentFieldName: currentFieldName,
          currentClassName: currentClassName,
          generatedClasses: generatedClasses,
          inputsClasses: inputsClasses,
          fragments: fragments,
          usedEnums: usedEnums,
          usedInputObjects: usedInputObjects,
        );

        expect(context.currentType, equals(currentType));
        expect(context.currentFieldName, equals(currentFieldName));
        expect(context.currentClassName, equals(currentClassName));
      });
    });

    group('copyWith', () {
      late GenerationContext originalContext;

      setUp(() {
        originalContext = GenerationContext(
          schemaMap: schemaMap,
          path: path,
          generatedClasses: generatedClasses,
          inputsClasses: inputsClasses,
          fragments: fragments,
          usedEnums: usedEnums,
          usedInputObjects: usedInputObjects,
        );
      });

      test('creates new context with updated schemaMap', () {
        final newSchemaMap = SchemaMap(schema: 'new schema');
        final newContext = originalContext.copyWith(schemaMap: newSchemaMap);

        expect(newContext.schemaMap, equals(newSchemaMap));
        expect(newContext.path, equals(originalContext.path));
        expect(newContext, isNot(same(originalContext)));
      });

      test('creates new context with updated path', () {
        final newPath = [
          TypeName(name: 'Mutation'),
          TypeName(name: 'CreateUser'),
        ];
        final newContext = originalContext.copyWith(path: newPath);

        expect(newContext.path, equals(newPath));
        expect(newContext.schemaMap, equals(originalContext.schemaMap));
        expect(newContext, isNot(same(originalContext)));
      });

      test('creates new context with updated currentType', () {
        const newType = ObjectTypeDefinitionNode(
          name: NameNode(value: 'Post'),
        );
        final newContext = originalContext.copyWith(currentType: newType);

        expect(newContext.currentType, equals(newType));
        expect(newContext.schemaMap, equals(originalContext.schemaMap));
        expect(newContext, isNot(same(originalContext)));
      });

      test('preserves original values when no parameters provided', () {
        final newContext = originalContext.copyWith();

        expect(newContext.schemaMap, equals(originalContext.schemaMap));
        expect(newContext.path, equals(originalContext.path));
        expect(
          newContext.generatedClasses,
          equals(originalContext.generatedClasses),
        );
        expect(newContext, isNot(same(originalContext)));
      });
    });

    group('validation', () {
      test('validates successfully with valid context', () {
        final context = GenerationContext(
          schemaMap: schemaMap,
          path: path,
          generatedClasses: generatedClasses,
          inputsClasses: inputsClasses,
          fragments: fragments,
          usedEnums: usedEnums,
          usedInputObjects: usedInputObjects,
        );

        expect(context.validate, returnsNormally);
      });

      test('throws exception for empty schemaMap output', () {
        final context = GenerationContext(
          schemaMap: SchemaMap(),
          path: path,
          generatedClasses: generatedClasses,
          inputsClasses: inputsClasses,
          fragments: fragments,
          usedEnums: usedEnums,
          usedInputObjects: usedInputObjects,
        );

        expect(
          context.validate,
          throwsA(
            isA<GenerationContextValidationException>().having(
              (e) => e.message,
              'message',
              contains('SchemaMap output cannot be null or empty'),
            ),
          ),
        );
      });

      test('throws exception for empty type name in path', () {
        final invalidPath = [TypeName(name: 'Query'), TypeName(name: '')];
        final context = GenerationContext(
          schemaMap: schemaMap,
          path: invalidPath,
          generatedClasses: generatedClasses,
          inputsClasses: inputsClasses,
          fragments: fragments,
          usedEnums: usedEnums,
          usedInputObjects: usedInputObjects,
        );

        expect(
          context.validate,
          throwsA(
            isA<GenerationContextValidationException>().having(
              (e) => e.message,
              'message',
              contains('Path cannot contain empty type names'),
            ),
          ),
        );
      });

      test('validates with null current class name', () {
        final context = GenerationContext(
          schemaMap: schemaMap,
          path: path,
          // null is allowed
          generatedClasses: generatedClasses,
          inputsClasses: inputsClasses,
          fragments: fragments,
          usedEnums: usedEnums,
          usedInputObjects: usedInputObjects,
        );

        expect(context.validate, returnsNormally);
      });

      test('validates with null current field name', () {
        final context = GenerationContext(
          schemaMap: schemaMap,
          path: path,
          // null is allowed
          generatedClasses: generatedClasses,
          inputsClasses: inputsClasses,
          fragments: fragments,
          usedEnums: usedEnums,
          usedInputObjects: usedInputObjects,
        );

        expect(context.validate, returnsNormally);
      });

      test('throws exception for duplicate class names', () {
        final duplicateClasses = [
          ClassDefinition(
            name: ClassName(name: 'User'),
          ),
          ClassDefinition(
            name: ClassName(name: 'User'),
          ),
        ];
        final context = GenerationContext(
          schemaMap: schemaMap,
          path: path,
          generatedClasses: duplicateClasses,
          inputsClasses: inputsClasses,
          fragments: fragments,
          usedEnums: usedEnums,
          usedInputObjects: usedInputObjects,
        );

        expect(
          context.validate,
          throwsA(
            isA<GenerationContextValidationException>().having(
              (e) => e.message,
              'message',
              contains('Duplicate class name found: User'),
            ),
          ),
        );
      });

      test('throws exception for duplicate input class names', () {
        final duplicateInputs = [
          QueryInput(
            name: const QueryInputName(name: 'CreateUserInput'),
            type: TypeName(name: 'String'),
          ),
          QueryInput(
            name: const QueryInputName(name: 'CreateUserInput'),
            type: TypeName(name: 'String'),
          ),
        ];
        final context = GenerationContext(
          schemaMap: schemaMap,
          path: path,
          generatedClasses: generatedClasses,
          inputsClasses: duplicateInputs,
          fragments: fragments,
          usedEnums: usedEnums,
          usedInputObjects: usedInputObjects,
        );

        expect(
          context.validate,
          throwsA(
            isA<GenerationContextValidationException>().having(
              (e) => e.message,
              'message',
              contains('Duplicate input class name found: CreateUserInput'),
            ),
          ),
        );
      });

      test('throws exception for duplicate fragment names', () {
        final duplicateFragments = [
          const FragmentDefinitionNode(
            name: NameNode(value: 'UserFragment'),
            typeCondition: TypeConditionNode(
              on: NamedTypeNode(name: NameNode(value: 'User')),
            ),
            selectionSet: SelectionSetNode(),
          ),
          const FragmentDefinitionNode(
            name: NameNode(value: 'UserFragment'),
            typeCondition: TypeConditionNode(
              on: NamedTypeNode(name: NameNode(value: 'User')),
            ),
            selectionSet: SelectionSetNode(),
          ),
        ];
        final context = GenerationContext(
          schemaMap: schemaMap,
          path: path,
          generatedClasses: generatedClasses,
          inputsClasses: inputsClasses,
          fragments: duplicateFragments,
          usedEnums: usedEnums,
          usedInputObjects: usedInputObjects,
        );

        expect(
          context.validate,
          throwsA(
            isA<GenerationContextValidationException>().having(
              (e) => e.message,
              'message',
              contains('Duplicate fragment name found: UserFragment'),
            ),
          ),
        );
      });
    });

    group('convenience methods', () {
      late GenerationContext context;

      setUp(() {
        context = GenerationContext(
          schemaMap: schemaMap,
          path: path,
          generatedClasses: generatedClasses,
          inputsClasses: inputsClasses,
          fragments: fragments,
          usedEnums: usedEnums,
          usedInputObjects: usedInputObjects,
        );
      });

      test('withCurrentType creates new context with updated type', () {
        const newType = ObjectTypeDefinitionNode(
          name: NameNode(value: 'Post'),
        );
        final newContext = context.withCurrentType(newType);

        expect(newContext.currentType, equals(newType));
        expect(newContext.schemaMap, equals(context.schemaMap));
        expect(newContext, isNot(same(context)));
      });

      test('withPath creates new context with updated path', () {
        final newPath = [TypeName(name: 'Mutation')];
        final newContext = context.withPath(newPath);

        expect(newContext.path, equals(newPath));
        expect(newContext.schemaMap, equals(context.schemaMap));
        expect(newContext, isNot(same(context)));
      });

      test('withPathExtension creates new context with extended path', () {
        final newTypeName = TypeName(name: 'Post');
        final newContext = context.withPathExtension(newTypeName);

        expect(newContext.path, equals([...path, newTypeName]));
        expect(newContext.schemaMap, equals(context.schemaMap));
        expect(newContext, isNot(same(context)));
      });

      test('withGeneratedClass creates new context with added class', () {
        final newClass = ClassDefinition(
          name: ClassName(name: 'Post'),
        );
        final newContext = context.withGeneratedClass(newClass);

        expect(newContext.generatedClasses, equals([newClass]));
        expect(newContext.schemaMap, equals(context.schemaMap));
        expect(newContext, isNot(same(context)));
      });

      test('withInputClass creates new context with added input', () {
        final newInput = QueryInput(
          name: const QueryInputName(name: 'CreatePostInput'),
          type: TypeName(name: 'String'),
        );
        final newContext = context.withInputClass(newInput);

        expect(newContext.inputsClasses, equals([newInput]));
        expect(newContext.schemaMap, equals(context.schemaMap));
        expect(newContext, isNot(same(context)));
      });

      test('withUsedEnum creates new context with added enum', () {
        final enumName = EnumName(name: 'Status');
        final newContext = context.withUsedEnum(enumName);

        expect(newContext.usedEnums, contains(enumName));
        expect(newContext.schemaMap, equals(context.schemaMap));
        expect(newContext, isNot(same(context)));
      });

      test(
        'withUsedInputObject creates new context with added input object',
        () {
          final inputObjectName = ClassName(name: 'CreateUserInput');
          final newContext = context.withUsedInputObject(inputObjectName);

          expect(newContext.usedInputObjects, contains(inputObjectName));
          expect(newContext.schemaMap, equals(context.schemaMap));
          expect(newContext, isNot(same(context)));
        },
      );
    });

    group('immutability', () {
      test('original context is not modified by copyWith', () {
        final originalContext = GenerationContext(
          schemaMap: schemaMap,
          path: path,
          generatedClasses: generatedClasses,
          inputsClasses: inputsClasses,
          fragments: fragments,
          usedEnums: usedEnums,
          usedInputObjects: usedInputObjects,
        );

        final newSchemaMap = SchemaMap(schema: 'new schema');
        final newContext = originalContext.copyWith(schemaMap: newSchemaMap);

        expect(originalContext.schemaMap, equals(schemaMap));
        expect(newContext.schemaMap, equals(newSchemaMap));
      });

      test('collections are not shared between contexts', () {
        final originalContext = GenerationContext(
          schemaMap: schemaMap,
          path: path,
          generatedClasses: [],
          inputsClasses: [],
          fragments: [],
          usedEnums: <EnumName>{},
          usedInputObjects: <ClassName>{},
        );

        final newClass = ClassDefinition(
          name: ClassName(name: 'Post'),
        );
        final newContext = originalContext.withGeneratedClass(newClass);

        expect(originalContext.generatedClasses, isEmpty);
        expect(newContext.generatedClasses, contains(newClass));
      });
    });
  });

  group('GenerationContextValidationException', () {
    test('creates exception with message', () {
      const message = 'Test validation error';
      final exception = GenerationContextValidationException(message);

      expect(exception.message, equals(message));
      expect(exception.toString(), contains(message));
      expect(
        exception.toString(),
        contains('GenerationContextValidationException'),
      );
    });
  });
}
