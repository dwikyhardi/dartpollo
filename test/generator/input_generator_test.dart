import 'package:dartpollo/generator/ephemeral_data.dart';
import 'package:dartpollo/generator/input_generator.dart';
import 'package:dartpollo/schema/schema_options.dart';
import 'package:dartpollo/visitor/type_definition_node_visitor.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:test/test.dart';

void main() {
  group('InputGenerator', () {
    late Context mockContext;
    late DocumentNode mockSchema;
    late TypeDefinitionNodeVisitor typeVisitor;
    late GeneratorOptions mockOptions;
    late SchemaMap mockSchemaMap;

    setUp(() {
      // Create a mock schema with input types, enums, and scalars
      mockSchema = parseString('''
        input UserInput {
          name: String!
          email: String
          age: Int
          role: UserRole
          tags: [String]
        }
        
        input NestedInput {
          user: UserInput
          metadata: JSON
        }
        
        enum UserRole {
          ADMIN
          USER
        }
        
        scalar JSON
      ''');

      typeVisitor = TypeDefinitionNodeVisitor();
      mockSchema.accept(typeVisitor);

      mockOptions = GeneratorOptions(
        scalarMapping: [
          ScalarMap(
            graphQLType: 'JSON',
            dartType: const DartType(name: 'Map<String, dynamic>'),
          ),
        ],
      );

      mockSchemaMap = SchemaMap();

      mockContext = Context(
        schema: mockSchema,
        typeDefinitionNodeVisitor: typeVisitor,
        options: mockOptions,
        schemaMap: mockSchemaMap,
        path: [],
        currentType: null,
        currentFieldName: null,
        currentClassName: null,
        generatedClasses: [],
        inputsClasses: [],
        fragments: [],
        usedEnums: {},
        usedInputObjects: {},
        log: false, // Disable logging for tests
      );
    });

    group('generateInputClass', () {
      test('should generate input class definition from input object type', () {
        final inputType =
            typeVisitor.getByName('UserInput')!
                as InputObjectTypeDefinitionNode;

        final classDefinition = InputGenerator.generateInputClass(
          inputType,
          mockContext,
        );

        expect(classDefinition.name.name, equals('UserInput'));
        expect(classDefinition.isInput, isTrue);
        expect(classDefinition.properties.length, equals(5));

        // Check that properties are generated correctly
        final nameProperty = classDefinition.properties.firstWhere(
          (p) => p.name.name == 'name',
        );
        expect(nameProperty.type.name, equals('String'));
        expect(nameProperty.type.isNonNull, isTrue);

        final emailProperty = classDefinition.properties.firstWhere(
          (p) => p.name.name == 'email',
        );
        expect(emailProperty.type.name, equals('String'));
        expect(emailProperty.type.isNonNull, isFalse);

        final ageProperty = classDefinition.properties.firstWhere(
          (p) => p.name.name == 'age',
        );
        expect(ageProperty.type.name, equals('int'));
        expect(ageProperty.type.isNonNull, isFalse);

        final roleProperty = classDefinition.properties.firstWhere(
          (p) => p.name.name == 'role',
        );
        expect(roleProperty.type.name, equals('UserRole'));
        expect(roleProperty.type.isNonNull, isFalse);

        final tagsProperty = classDefinition.properties.firstWhere(
          (p) => p.name.name == 'tags',
        );
        expect(tagsProperty.type.namePrintable, equals('List<String?>?'));
        expect(tagsProperty.type.isNonNull, isFalse);
      });

      test('should mark used enums when generating input class', () {
        final inputType =
            typeVisitor.getByName('UserInput')!
                as InputObjectTypeDefinitionNode;

        InputGenerator.generateInputClass(inputType, mockContext);

        expect(mockContext.usedEnums.any((e) => e.name == 'UserRole'), isTrue);
      });

      test(
        'should mark used input objects when generating nested input class',
        () {
          final inputType =
              typeVisitor.getByName('NestedInput')!
                  as InputObjectTypeDefinitionNode;

          InputGenerator.generateInputClass(inputType, mockContext);

          expect(
            mockContext.usedInputObjects.any((e) => e.name == 'UserInput'),
            isTrue,
          );
        },
      );
    });

    group('generateInputProperties', () {
      test('should generate properties from input field definitions', () {
        final inputType =
            typeVisitor.getByName('UserInput')!
                as InputObjectTypeDefinitionNode;

        final properties = InputGenerator.generateInputProperties(
          inputType.fields,
          mockContext,
        );

        expect(properties.length, equals(5));
        expect(properties.any((p) => p.name.name == 'name'), isTrue);
        expect(properties.any((p) => p.name.name == 'email'), isTrue);
        expect(properties.any((p) => p.name.name == 'age'), isTrue);
        expect(properties.any((p) => p.name.name == 'role'), isTrue);
        expect(properties.any((p) => p.name.name == 'tags'), isTrue);
      });

      test('should handle non-null types correctly', () {
        final inputType =
            typeVisitor.getByName('UserInput')!
                as InputObjectTypeDefinitionNode;

        final properties = InputGenerator.generateInputProperties(
          inputType.fields,
          mockContext,
        );

        final nameProperty = properties.firstWhere(
          (p) => p.name.name == 'name',
        );
        expect(nameProperty.type.isNonNull, isTrue);

        final emailProperty = properties.firstWhere(
          (p) => p.name.name == 'email',
        );
        expect(emailProperty.type.isNonNull, isFalse);
      });

      test('should handle list types correctly', () {
        final inputType =
            typeVisitor.getByName('UserInput')!
                as InputObjectTypeDefinitionNode;

        final properties = InputGenerator.generateInputProperties(
          inputType.fields,
          mockContext,
        );

        final tagsProperty = properties.firstWhere(
          (p) => p.name.name == 'tags',
        );
        expect(tagsProperty.type.namePrintable, equals('List<String?>?'));
        expect(tagsProperty.type.isNonNull, isFalse);
      });

      test('should add unknown enum value annotation for enum properties', () {
        final inputType =
            typeVisitor.getByName('UserInput')!
                as InputObjectTypeDefinitionNode;

        final properties = InputGenerator.generateInputProperties(
          inputType.fields,
          mockContext,
        );

        final roleProperty = properties.firstWhere(
          (p) => p.name.name == 'role',
        );
        expect(
          roleProperty.annotations.any((a) => a.contains('unknownEnumValue')),
          isTrue,
        );
        expect(
          roleProperty.annotations.any((a) => a.contains('UserRole.unknown')),
          isTrue,
        );
      });

      test('should handle custom scalar types', () {
        final inputType =
            typeVisitor.getByName('NestedInput')!
                as InputObjectTypeDefinitionNode;

        final properties = InputGenerator.generateInputProperties(
          inputType.fields,
          mockContext,
        );

        final metadataProperty = properties.firstWhere(
          (p) => p.name.name == 'metadata',
        );
        expect(metadataProperty.type.name, equals('Map<String, dynamic>'));
      });

      test('should handle nested input object types', () {
        final inputType =
            typeVisitor.getByName('NestedInput')!
                as InputObjectTypeDefinitionNode;

        final properties = InputGenerator.generateInputProperties(
          inputType.fields,
          mockContext,
        );

        final userProperty = properties.firstWhere(
          (p) => p.name.name == 'user',
        );
        expect(userProperty.type.name, equals('UserInput'));
        expect(userProperty.type.isNonNull, isFalse);
      });
    });

    group('input validation and type relationships', () {
      test('should track used enums correctly', () {
        final inputType =
            typeVisitor.getByName('UserInput')!
                as InputObjectTypeDefinitionNode;

        InputGenerator.generateInputProperties(inputType.fields, mockContext);

        expect(mockContext.usedEnums.length, equals(1));
        expect(mockContext.usedEnums.first.name, equals('UserRole'));
      });

      test('should track used input objects correctly', () {
        final inputType =
            typeVisitor.getByName('NestedInput')!
                as InputObjectTypeDefinitionNode;

        InputGenerator.generateInputProperties(inputType.fields, mockContext);

        expect(mockContext.usedInputObjects.length, equals(1));
        expect(mockContext.usedInputObjects.first.name, equals('UserInput'));
      });
    });

    group('input annotation processing', () {
      test('should add JsonKey annotation for field name transformation', () {
        // Create a schema with a field that needs name transformation
        final specialSchema = parseString('''
          input SpecialInput {
            special_field: String
          }
        ''');

        final specialTypeVisitor = TypeDefinitionNodeVisitor();
        specialSchema.accept(specialTypeVisitor);

        final specialContext = Context(
          schema: specialSchema,
          typeDefinitionNodeVisitor: specialTypeVisitor,
          options: mockOptions,
          schemaMap: mockSchemaMap,
          path: [],
          currentType: null,
          currentFieldName: null,
          currentClassName: null,
          generatedClasses: [],
          inputsClasses: [],
          fragments: [],
          usedEnums: {},
          usedInputObjects: {},
          log: false,
        );

        final inputType =
            specialTypeVisitor.getByName('SpecialInput')!
                as InputObjectTypeDefinitionNode;
        final properties = InputGenerator.generateInputProperties(
          inputType.fields,
          specialContext,
        );

        final specialProperty = properties.first;
        expect(specialProperty.name.name, equals('special_field'));
        expect(specialProperty.name.namePrintable, equals('specialField'));
        expect(
          specialProperty.annotations.any((a) => a.contains('JsonKey')),
          isTrue,
        );
        expect(
          specialProperty.annotations.any(
            (a) => a.contains('name: \'special_field\''),
          ),
          isTrue,
        );
      });

      test(
        'should not add JsonKey annotation when field name matches property name',
        () {
          final inputType =
              typeVisitor.getByName('UserInput')!
                  as InputObjectTypeDefinitionNode;

          final properties = InputGenerator.generateInputProperties(
            inputType.fields,
            mockContext,
          );

          final nameProperty = properties.firstWhere(
            (p) => p.name.name == 'name',
          );
          final hasJsonKeyForName = nameProperty.annotations.any(
            (a) => a.contains('name:'),
          );
          expect(hasJsonKeyForName, isFalse);
        },
      );
    });

    group('convertEnumToString handling', () {
      test(
        'should not add unknown enum value annotation when convertEnumToString is true',
        () {
          final enumToStringSchemaMap = SchemaMap(
            convertEnumToString: true,
          );

          final enumToStringContext = Context(
            schema: mockSchema,
            typeDefinitionNodeVisitor: typeVisitor,
            options: mockOptions,
            schemaMap: enumToStringSchemaMap,
            path: [],
            currentType: null,
            currentFieldName: null,
            currentClassName: null,
            generatedClasses: [],
            inputsClasses: [],
            fragments: [],
            usedEnums: {},
            usedInputObjects: {},
            log: false,
          );

          final inputType =
              typeVisitor.getByName('UserInput')!
                  as InputObjectTypeDefinitionNode;

          final properties = InputGenerator.generateInputProperties(
            inputType.fields,
            enumToStringContext,
          );

          final roleProperty = properties.firstWhere(
            (p) => p.name.name == 'role',
          );
          expect(
            roleProperty.annotations.any((a) => a.contains('unknownEnumValue')),
            isFalse,
          );
        },
      );
    });
  });
}
