import 'package:dartpollo/generator/class_generator.dart';
import 'package:dartpollo/generator/data/data.dart';
import 'package:dartpollo/generator/ephemeral_data.dart';
import 'package:dartpollo/schema/schema_options.dart';
import 'package:dartpollo/visitor/type_definition_node_visitor.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:test/test.dart';

void main() {
  group('ClassGenerator', () {
    late DocumentNode schema;
    late TypeDefinitionNodeVisitor typeVisitor;
    late Context context;

    setUp(() {
      schema = parseString('''
        type Query {
          user: User
          users: [User!]!
        }
        
        type User {
          id: ID!
          name: String!
          email: String
          age: Int
          isActive: Boolean!
          role: UserRole!
          tags: [String!]
          profile: UserProfile
        }
        
        type UserProfile {
          bio: String
          avatar: String
        }
        
        enum UserRole {
          ADMIN
          USER
          GUEST
        }
        
        input UserInput {
          name: String!
          email: String
          age: Int
        }
        
        scalar DateTime
      ''');

      typeVisitor = TypeDefinitionNodeVisitor();
      schema.accept(typeVisitor);

      context = Context(
        schema: schema,
        typeDefinitionNodeVisitor: typeVisitor,
        options: GeneratorOptions(),
        schemaMap: SchemaMap(
          namingScheme: NamingScheme.pathedWithTypes,
          typeNameField: '__typename',
        ),
        path: [TypeName(name: 'Query'), TypeName(name: 'User')],
        currentType: typeVisitor.getByName('User'),
        currentFieldName: ClassPropertyName(name: 'user'),
        currentClassName: ClassName(name: 'User'),
        generatedClasses: [],
        inputsClasses: [],
        fragments: [],
        usedEnums: {},
        usedInputObjects: {},
      );
    });

    group('generateClass', () {
      test('should generate a basic class definition', () {
        final userType =
            typeVisitor.getByName('User') as ObjectTypeDefinitionNode;
        final properties = [
          ClassProperty(
            name: ClassPropertyName(name: 'id'),
            type: TypeName(name: 'String', isNonNull: true),
          ),
          ClassProperty(
            name: ClassPropertyName(name: 'name'),
            type: TypeName(name: 'String', isNonNull: true),
          ),
        ];

        final classDefinition = ClassGenerator.generateClass(
          node: userType,
          context: context,
          properties: properties,
        );

        expect(classDefinition.name.name, contains('User'));
        expect(classDefinition.properties.length, equals(2));
        expect(classDefinition.isInput, isFalse);
        expect(classDefinition.mixins, isEmpty);
        expect(classDefinition.factoryPossibilities, isEmpty);
      });

      test('should generate input class definition', () {
        final inputType =
            typeVisitor.getByName('UserInput') as InputObjectTypeDefinitionNode;
        final properties = [
          ClassProperty(
            name: ClassPropertyName(name: 'name'),
            type: TypeName(name: 'String', isNonNull: true),
          ),
        ];

        final classDefinition = ClassGenerator.generateClass(
          node: inputType,
          context: context,
          properties: properties,
          isInput: true,
        );

        expect(classDefinition.isInput, isTrue);
        expect(classDefinition.properties.length, equals(1));
      });

      test('should generate class with mixins and factory possibilities', () {
        final userType =
            typeVisitor.getByName('User') as ObjectTypeDefinitionNode;
        final mixins = [FragmentName(name: 'UserFragment')];
        final factoryPossibilities = {'Admin': ClassName(name: 'AdminUser')};

        final classDefinition = ClassGenerator.generateClass(
          node: userType,
          context: context,
          properties: [],
          mixins: mixins,
          factoryPossibilities: factoryPossibilities,
        );

        expect(classDefinition.mixins.length, equals(1));
        expect(classDefinition.mixins.first.name, equals('UserFragment'));
        expect(classDefinition.factoryPossibilities.length, equals(1));
        expect(classDefinition.factoryPossibilities['Admin']?.name,
            equals('AdminUser'));
      });
    });

    group('generateProperties', () {
      test('should generate properties from field definitions', () {
        final userType =
            typeVisitor.getByName('User') as ObjectTypeDefinitionNode;
        final newClassesFound = <Context>[];

        final properties = ClassGenerator.generateProperties(
          fields: userType.fields,
          context: context,
          onNewClassFound: newClassesFound.add,
        );

        expect(properties.length, equals(8)); // All User fields
        expect(properties.any((p) => p.name.name == 'id'), isTrue);
        expect(properties.any((p) => p.name.name == 'name'), isTrue);
        expect(properties.any((p) => p.name.name == 'email'), isTrue);
        expect(properties.any((p) => p.name.name == 'age'), isTrue);
        expect(properties.any((p) => p.name.name == 'isActive'), isTrue);
        expect(properties.any((p) => p.name.name == 'role'), isTrue);
        expect(properties.any((p) => p.name.name == 'tags'), isTrue);
        expect(properties.any((p) => p.name.name == 'profile'), isTrue);

        // Should find UserProfile as a new class to generate
        expect(newClassesFound.length, equals(1));
        expect(newClassesFound.first.currentType?.name.value,
            equals('UserProfile'));
      });

      test('should handle scalar types correctly', () {
        final userType =
            typeVisitor.getByName('User') as ObjectTypeDefinitionNode;
        final idField = userType.fields.firstWhere((f) => f.name.value == 'id');
        final nameField =
            userType.fields.firstWhere((f) => f.name.value == 'name');
        final emailField =
            userType.fields.firstWhere((f) => f.name.value == 'email');

        final properties = ClassGenerator.generateProperties(
          fields: [idField, nameField, emailField],
          context: context,
          onNewClassFound: (_) {},
        );

        final idProperty = properties.firstWhere((p) => p.name.name == 'id');
        final nameProperty =
            properties.firstWhere((p) => p.name.name == 'name');
        final emailProperty =
            properties.firstWhere((p) => p.name.name == 'email');

        expect(idProperty.type.name, equals('String'));
        expect(idProperty.type.isNonNull, isTrue);
        expect(nameProperty.type.name, equals('String'));
        expect(nameProperty.type.isNonNull, isTrue);
        expect(emailProperty.type.name, equals('String'));
        expect(emailProperty.type.isNonNull, isFalse);
      });

      test('should handle enum types correctly', () {
        final userType =
            typeVisitor.getByName('User') as ObjectTypeDefinitionNode;
        final roleField =
            userType.fields.firstWhere((f) => f.name.value == 'role');

        final properties = ClassGenerator.generateProperties(
          fields: [roleField],
          context: context,
          onNewClassFound: (_) {},
        );

        final roleProperty = properties.first;
        expect(roleProperty.name.name, equals('role'));
        expect(roleProperty.type.name, equals('UserRole'));
        expect(
            roleProperty.annotations.any((a) => a.contains('unknownEnumValue')),
            isTrue);
        expect(context.usedEnums.any((e) => e.name == 'UserRole'), isTrue);
      });

      test('should handle enum to string conversion', () {
        final contextWithEnumToString = Context(
          schema: schema,
          typeDefinitionNodeVisitor: typeVisitor,
          options: GeneratorOptions(),
          schemaMap: SchemaMap(
            namingScheme: NamingScheme.pathedWithTypes,
            typeNameField: '__typename',
            convertEnumToString: true,
          ),
          path: [TypeName(name: 'Query'), TypeName(name: 'User')],
          currentType: typeVisitor.getByName('User'),
          currentFieldName: ClassPropertyName(name: 'user'),
          currentClassName: ClassName(name: 'User'),
          generatedClasses: [],
          inputsClasses: [],
          fragments: [],
          usedEnums: {},
          usedInputObjects: {},
        );

        final userType =
            typeVisitor.getByName('User') as ObjectTypeDefinitionNode;
        final roleField =
            userType.fields.firstWhere((f) => f.name.value == 'role');

        final properties = ClassGenerator.generateProperties(
          fields: [roleField],
          context: contextWithEnumToString,
          onNewClassFound: (_) {},
        );

        final roleProperty = properties.first;
        expect(roleProperty.type.name, equals('String'));
        expect(roleProperty.type.isNonNull, isTrue);
      });

      test('should handle list types correctly', () {
        final userType =
            typeVisitor.getByName('User') as ObjectTypeDefinitionNode;
        final tagsField =
            userType.fields.firstWhere((f) => f.name.value == 'tags');

        final properties = ClassGenerator.generateProperties(
          fields: [tagsField],
          context: context,
          onNewClassFound: (_) {},
        );

        final tagsProperty = properties.first;
        expect(tagsProperty.name.name, equals('tags'));
        expect(tagsProperty.type, isA<ListOfTypeName>());
        final listType = tagsProperty.type as ListOfTypeName;
        expect(listType.typeName.name, equals('String'));
        expect(listType.isNonNull, isFalse);
      });
    });

    group('generateInputProperties', () {
      test('should generate properties from input field definitions', () {
        final inputType =
            typeVisitor.getByName('UserInput') as InputObjectTypeDefinitionNode;

        final properties = ClassGenerator.generateInputProperties(
          fields: inputType.fields,
          context: context,
          onNewClassFound: (_) {},
        );

        expect(properties.length, equals(3));
        expect(properties.any((p) => p.name.name == 'name'), isTrue);
        expect(properties.any((p) => p.name.name == 'email'), isTrue);
        expect(properties.any((p) => p.name.name == 'age'), isTrue);

        final nameProperty =
            properties.firstWhere((p) => p.name.name == 'name');
        expect(nameProperty.type.name, equals('String'));
        expect(nameProperty.type.isNonNull, isTrue);

        final emailProperty =
            properties.firstWhere((p) => p.name.name == 'email');
        expect(emailProperty.type.isNonNull, isFalse);
      });
    });

    group('generateClassAnnotations', () {
      test('should generate empty annotations for node without directives', () {
        final userType =
            typeVisitor.getByName('User') as ObjectTypeDefinitionNode;

        final annotations = ClassGenerator.generateClassAnnotations(
          node: userType,
          context: context,
        );

        expect(annotations, isEmpty);
      });

      test('should handle deprecated directive', () {
        final schemaWithDeprecated = parseString('''
          type User @deprecated(reason: "Use UserV2 instead") {
            id: ID!
          }
        ''');

        final deprecatedTypeVisitor = TypeDefinitionNodeVisitor();
        schemaWithDeprecated.accept(deprecatedTypeVisitor);

        final userType =
            deprecatedTypeVisitor.getByName('User') as ObjectTypeDefinitionNode;

        final annotations = ClassGenerator.generateClassAnnotations(
          node: userType,
          context: context,
        );

        expect(annotations.length, equals(1));
        expect(annotations.first, contains('Deprecated'));
      });
    });

    group('validatePropertyType', () {
      test('should validate existing type successfully', () {
        final userType =
            typeVisitor.getByName('User') as ObjectTypeDefinitionNode;
        final nameField =
            userType.fields.firstWhere((f) => f.name.value == 'name');

        expect(
          () => ClassGenerator.validatePropertyType(
            fieldType: nameField.type,
            context: context,
          ),
          returnsNormally,
        );
      });

      test('should throw exception for non-existent type', () {
        final invalidType =
            NamedTypeNode(name: NameNode(value: 'NonExistentType'));

        expect(
          () => ClassGenerator.validatePropertyType(
            fieldType: invalidType,
            context: context,
          ),
          throwsException,
        );
      });
    });

    group('__typename field handling', () {
      test('should handle __typename field correctly', () {
        final schemaWithTypename = parseString('''
          type Query {
            user: User
          }
          
          type User {
            __typename: String!
            id: ID!
          }
        ''');

        final typenameTypeVisitor = TypeDefinitionNodeVisitor();
        schemaWithTypename.accept(typenameTypeVisitor);

        final typenameContext = Context(
          schema: schemaWithTypename,
          typeDefinitionNodeVisitor: typenameTypeVisitor,
          options: GeneratorOptions(),
          schemaMap: SchemaMap(
            namingScheme: NamingScheme.pathedWithTypes,
            typeNameField: '__typename',
          ),
          path: [TypeName(name: 'Query'), TypeName(name: 'User')],
          currentType: typenameTypeVisitor.getByName('User'),
          currentFieldName: ClassPropertyName(name: 'user'),
          currentClassName: ClassName(name: 'User'),
          generatedClasses: [],
          inputsClasses: [],
          fragments: [],
          usedEnums: {},
          usedInputObjects: {},
        );

        final userType =
            typenameTypeVisitor.getByName('User') as ObjectTypeDefinitionNode;
        final properties = ClassGenerator.generateProperties(
          fields: userType.fields,
          context: typenameContext,
          onNewClassFound: (_) {},
        );

        final typenameProperty =
            properties.firstWhere((p) => p.name.name == '__typename');
        expect(typenameProperty.type.name, equals('String'));
        expect(typenameProperty.isResolveType, isTrue);
        expect(typenameProperty.annotations.any((a) => a.contains('JsonKey')),
            isTrue);
      });
    });

    group('custom scalar handling', () {
      test('should handle custom scalars with parser', () {
        final contextWithCustomScalar = Context(
          schema: schema,
          typeDefinitionNodeVisitor: typeVisitor,
          options: GeneratorOptions(
            scalarMapping: [
              ScalarMap(
                graphQLType: 'DateTime',
                dartType: DartType(name: 'DateTime'),
                customParserImport: 'package:my_app/parsers.dart',
              ),
            ],
          ),
          schemaMap: SchemaMap(
            namingScheme: NamingScheme.pathedWithTypes,
            typeNameField: '__typename',
          ),
          path: [TypeName(name: 'Query'), TypeName(name: 'User')],
          currentType: typeVisitor.getByName('User'),
          currentFieldName: ClassPropertyName(name: 'user'),
          currentClassName: ClassName(name: 'User'),
          generatedClasses: [],
          inputsClasses: [],
          fragments: [],
          usedEnums: {},
          usedInputObjects: {},
        );

        final schemaWithDateTime = parseString('''
          type User {
            createdAt: DateTime!
          }
          
          scalar DateTime
        ''');

        final dateTimeTypeVisitor = TypeDefinitionNodeVisitor();
        schemaWithDateTime.accept(dateTimeTypeVisitor);

        final userType =
            dateTimeTypeVisitor.getByName('User') as ObjectTypeDefinitionNode;
        final dateTimeField =
            userType.fields.firstWhere((f) => f.name.value == 'createdAt');

        final contextWithDateTime =
            contextWithCustomScalar.nextTypeWithSamePath(
          nextType: userType,
          nextFieldName: ClassPropertyName(name: 'createdAt'),
          nextClassName: ClassName(name: 'User'),
        );

        final properties = ClassGenerator.generateProperties(
          fields: [dateTimeField],
          context: contextWithDateTime,
          onNewClassFound: (_) {},
        );

        final dateTimeProperty = properties.first;
        expect(dateTimeProperty.annotations.any((a) => a.contains('fromJson')),
            isTrue);
        expect(dateTimeProperty.annotations.any((a) => a.contains('toJson')),
            isTrue);
      });
    });

    group('interface and inheritance scenarios', () {
      test('should handle interface types', () {
        final schemaWithInterface = parseString('''
          interface Node {
            id: ID!
          }
          
          type User implements Node {
            id: ID!
            name: String!
          }
        ''');

        final interfaceTypeVisitor = TypeDefinitionNodeVisitor();
        schemaWithInterface.accept(interfaceTypeVisitor);

        final nodeInterface = interfaceTypeVisitor.getByName('Node')
            as InterfaceTypeDefinitionNode;
        final interfaceContext = Context(
          schema: schemaWithInterface,
          typeDefinitionNodeVisitor: interfaceTypeVisitor,
          options: GeneratorOptions(),
          schemaMap: SchemaMap(
            namingScheme: NamingScheme.pathedWithTypes,
            typeNameField: '__typename',
          ),
          path: [TypeName(name: 'Query'), TypeName(name: 'Node')],
          currentType: nodeInterface,
          currentFieldName: ClassPropertyName(name: 'node'),
          currentClassName: ClassName(name: 'Node'),
          generatedClasses: [],
          inputsClasses: [],
          fragments: [],
          usedEnums: {},
          usedInputObjects: {},
        );

        final properties = ClassGenerator.generateProperties(
          fields: nodeInterface.fields,
          context: interfaceContext,
          onNewClassFound: (_) {},
        );

        expect(properties.length, equals(1));
        expect(properties.first.name.name, equals('id'));
      });
    });
  });
}
