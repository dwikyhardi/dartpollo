import 'package:dartpollo_annotation/schema/schema_options.dart';
import 'package:dartpollo_generator/services/schema_service.dart';
import 'package:gql/ast.dart';
import 'package:test/test.dart';

void main() {
  group('SchemaService', () {
    late DocumentNode basicSchema;
    late DocumentNode complexSchema;
    late DocumentNode invalidSchema;
    late GeneratorOptions basicOptions;
    late GeneratorOptions customScalarOptions;

    setUp(() {
      // Basic schema with simple types
      basicSchema = const DocumentNode(
        definitions: [
          ObjectTypeDefinitionNode(
            name: NameNode(value: 'User'),
            fields: [
              FieldDefinitionNode(
                name: NameNode(value: 'id'),
                type: NamedTypeNode(
                  name: NameNode(value: 'ID'),
                  isNonNull: true,
                ),
              ),
              FieldDefinitionNode(
                name: NameNode(value: 'name'),
                type: NamedTypeNode(
                  name: NameNode(value: 'String'),
                  isNonNull: true,
                ),
              ),
            ],
          ),
          ScalarTypeDefinitionNode(
            name: NameNode(value: 'DateTime'),
          ),
        ],
      );

      // Complex schema with various types
      complexSchema = const DocumentNode(
        definitions: [
          ObjectTypeDefinitionNode(
            name: NameNode(value: 'User'),
            fields: [
              FieldDefinitionNode(
                name: NameNode(value: 'id'),
                type: NamedTypeNode(
                  name: NameNode(value: 'ID'),
                  isNonNull: true,
                ),
              ),
              FieldDefinitionNode(
                name: NameNode(value: 'profile'),
                type: NamedTypeNode(
                  name: NameNode(value: 'Profile'),
                ),
              ),
              FieldDefinitionNode(
                name: NameNode(value: 'posts'),
                type: ListTypeNode(
                  type: NamedTypeNode(
                    name: NameNode(value: 'Post'),
                    isNonNull: true,
                  ),
                  isNonNull: true,
                ),
              ),
            ],
            interfaces: [NamedTypeNode(name: NameNode(value: 'Node'))],
          ),
          InterfaceTypeDefinitionNode(
            name: NameNode(value: 'Node'),
            fields: [
              FieldDefinitionNode(
                name: NameNode(value: 'id'),
                type: NamedTypeNode(
                  name: NameNode(value: 'ID'),
                  isNonNull: true,
                ),
              ),
            ],
          ),
          ObjectTypeDefinitionNode(
            name: NameNode(value: 'Profile'),
            fields: [
              FieldDefinitionNode(
                name: NameNode(value: 'bio'),
                type: NamedTypeNode(
                  name: NameNode(value: 'String'),
                ),
              ),
            ],
          ),
          ObjectTypeDefinitionNode(
            name: NameNode(value: 'Post'),
            fields: [
              FieldDefinitionNode(
                name: NameNode(value: 'title'),
                type: NamedTypeNode(
                  name: NameNode(value: 'String'),
                  isNonNull: true,
                ),
              ),
              FieldDefinitionNode(
                name: NameNode(value: 'status'),
                type: NamedTypeNode(
                  name: NameNode(value: 'PostStatus'),
                  isNonNull: true,
                ),
              ),
            ],
          ),
          EnumTypeDefinitionNode(
            name: NameNode(value: 'PostStatus'),
            values: [
              EnumValueDefinitionNode(
                name: NameNode(value: 'DRAFT'),
              ),
              EnumValueDefinitionNode(
                name: NameNode(value: 'PUBLISHED'),
              ),
            ],
          ),
          InputObjectTypeDefinitionNode(
            name: NameNode(value: 'CreateUserInput'),
            fields: [
              InputValueDefinitionNode(
                name: NameNode(value: 'name'),
                type: NamedTypeNode(
                  name: NameNode(value: 'String'),
                  isNonNull: true,
                ),
              ),
              InputValueDefinitionNode(
                name: NameNode(value: 'email'),
                type: NamedTypeNode(
                  name: NameNode(value: 'String'),
                  isNonNull: true,
                ),
              ),
            ],
          ),
          UnionTypeDefinitionNode(
            name: NameNode(value: 'SearchResult'),
            types: [
              NamedTypeNode(name: NameNode(value: 'User')),
              NamedTypeNode(name: NameNode(value: 'Post')),
            ],
          ),
          ScalarTypeDefinitionNode(
            name: NameNode(value: 'DateTime'),
          ),
          ScalarTypeDefinitionNode(
            name: NameNode(value: 'JSON'),
          ),
        ],
      );

      // Invalid schema with missing type references
      invalidSchema = const DocumentNode(
        definitions: [
          ObjectTypeDefinitionNode(
            name: NameNode(value: 'User'),
            fields: [
              FieldDefinitionNode(
                name: NameNode(value: 'profile'),
                type: NamedTypeNode(
                  name: NameNode(value: 'NonExistentType'),
                ),
              ),
            ],
          ),
        ],
      );

      basicOptions = GeneratorOptions(
        scalarMapping: [],
      );

      customScalarOptions = GeneratorOptions(
        scalarMapping: [
          ScalarMap(
            graphQLType: 'DateTime',
            dartType: const DartType(
              name: 'DateTime',
              imports: ['dart:core'],
            ),
          ),
          ScalarMap(
            graphQLType: 'JSON',
            dartType: const DartType(
              name: 'Map<String, dynamic>',
              imports: ['dart:convert'],
            ),
            customParserImport: 'package:json_annotation/json_annotation.dart',
          ),
        ],
      );
    });

    group('constructor and initialization', () {
      test('should initialize with schema and create type visitor', () {
        final service = SchemaService(basicSchema);

        expect(service.schema, equals(basicSchema));
        expect(service.typeVisitor, isNotNull);
      });

      test('should parse schema and populate type visitor', () {
        final service = SchemaService(basicSchema);

        // Check that types are populated
        expect(service.typeVisitor.types, isNotEmpty);
        expect(service.typeVisitor.types.containsKey('User'), isTrue);
        expect(service.typeVisitor.types.containsKey('DateTime'), isTrue);

        // Check default scalars are included
        expect(service.typeVisitor.types.containsKey('String'), isTrue);
        expect(service.typeVisitor.types.containsKey('ID'), isTrue);
        expect(service.typeVisitor.types.containsKey('Int'), isTrue);
        expect(service.typeVisitor.types.containsKey('Float'), isTrue);
        expect(service.typeVisitor.types.containsKey('Boolean'), isTrue);
      });

      test('should handle complex schema with all type kinds', () {
        final service = SchemaService(complexSchema);

        expect(service.typeVisitor.types.containsKey('User'), isTrue);
        expect(service.typeVisitor.types.containsKey('Node'), isTrue);
        expect(service.typeVisitor.types.containsKey('Profile'), isTrue);
        expect(service.typeVisitor.types.containsKey('Post'), isTrue);
        expect(service.typeVisitor.types.containsKey('PostStatus'), isTrue);
        expect(
          service.typeVisitor.types.containsKey('CreateUserInput'),
          isTrue,
        );
        expect(service.typeVisitor.types.containsKey('SearchResult'), isTrue);
        expect(service.typeVisitor.types.containsKey('DateTime'), isTrue);
        expect(service.typeVisitor.types.containsKey('JSON'), isTrue);
      });
    });

    group('getTypeByName', () {
      test('should return existing type definition', () {
        final service = SchemaService(basicSchema);

        final userType = service.getTypeByName('User');
        expect(userType, isNotNull);
        expect(userType, isA<ObjectTypeDefinitionNode>());
        expect(
          (userType! as ObjectTypeDefinitionNode).name.value,
          equals('User'),
        );
      });

      test('should return null for non-existent type', () {
        final service = SchemaService(basicSchema);

        final nonExistentType = service.getTypeByName('NonExistentType');
        expect(nonExistentType, isNull);
      });

      test('should return default scalar types', () {
        final service = SchemaService(basicSchema);

        final stringType = service.getTypeByName('String');
        expect(stringType, isNotNull);
        expect(stringType, isA<ScalarTypeDefinitionNode>());

        final idType = service.getTypeByName('ID');
        expect(idType, isNotNull);
        expect(idType, isA<ScalarTypeDefinitionNode>());
      });

      test('should return custom scalar types', () {
        final service = SchemaService(basicSchema);

        final dateTimeType = service.getTypeByName('DateTime');
        expect(dateTimeType, isNotNull);
        expect(dateTimeType, isA<ScalarTypeDefinitionNode>());
        expect(
          (dateTimeType! as ScalarTypeDefinitionNode).name.value,
          equals('DateTime'),
        );
      });

      test('should return different type kinds correctly', () {
        final service = SchemaService(complexSchema);

        // Object type
        final userType = service.getTypeByName('User');
        expect(userType, isA<ObjectTypeDefinitionNode>());

        // Interface type
        final nodeType = service.getTypeByName('Node');
        expect(nodeType, isA<InterfaceTypeDefinitionNode>());

        // Enum type
        final statusType = service.getTypeByName('PostStatus');
        expect(statusType, isA<EnumTypeDefinitionNode>());

        // Input type
        final inputType = service.getTypeByName('CreateUserInput');
        expect(inputType, isA<InputObjectTypeDefinitionNode>());

        // Union type
        final unionType = service.getTypeByName('SearchResult');
        expect(unionType, isA<UnionTypeDefinitionNode>());

        // Scalar type
        final scalarType = service.getTypeByName('DateTime');
        expect(scalarType, isA<ScalarTypeDefinitionNode>());
      });
    });

    group('extractCustomImports', () {
      test('should return empty list when no custom scalars', () {
        final service = SchemaService(basicSchema);

        final imports = service.extractCustomImports(basicOptions);
        expect(imports, isEmpty);
      });

      test('should extract imports from custom scalar mappings', () {
        final service = SchemaService(complexSchema);

        final imports = service.extractCustomImports(customScalarOptions);
        expect(imports, isNotEmpty);
        expect(imports, contains('dart:core'));
        expect(imports, contains('dart:convert'));
        expect(
          imports,
          contains('package:json_annotation/json_annotation.dart'),
        );
      });

      test('should handle scalar mappings without imports', () {
        final optionsWithoutImports = GeneratorOptions(
          scalarMapping: [
            ScalarMap(
              graphQLType: 'DateTime',
              dartType: const DartType(name: 'DateTime'),
            ),
          ],
        );

        final service = SchemaService(complexSchema);
        final imports = service.extractCustomImports(optionsWithoutImports);

        // Should not contain any imports for DateTime since none were specified
        expect(imports.where((i) => i.contains('DateTime')), isEmpty);
      });

      test('should deduplicate imports', () {
        final optionsWithDuplicates = GeneratorOptions(
          scalarMapping: [
            ScalarMap(
              graphQLType: 'DateTime',
              dartType: const DartType(
                name: 'DateTime',
                imports: ['dart:core', 'dart:core'], // Duplicate import
              ),
            ),
            ScalarMap(
              graphQLType: 'JSON',
              dartType: const DartType(
                name: 'Map<String, dynamic>',
                imports: ['dart:core'], // Same import as above
              ),
            ),
          ],
        );

        final service = SchemaService(complexSchema);
        final imports = service.extractCustomImports(optionsWithDuplicates);

        // Should contain only one instance of 'dart:core'
        expect(imports.where((i) => i == 'dart:core').length, equals(1));
      });

      test('should only process scalar types from schema', () {
        final service = SchemaService(complexSchema);

        final imports = service.extractCustomImports(customScalarOptions);

        // Should only process DateTime and JSON scalars, not object types like User
        expect(
          imports.length,
          equals(3),
        ); // dart:core, dart:convert, json_annotation
      });
    });

    group('validateSchema', () {
      test('should pass validation for valid basic schema', () {
        final service = SchemaService(basicSchema);

        expect(service.validateSchema, returnsNormally);
      });

      test('should pass validation for valid complex schema', () {
        final service = SchemaService(complexSchema);

        expect(service.validateSchema, returnsNormally);
      });

      test('should throw exception for empty schema', () {
        const emptySchema = DocumentNode();
        final service = SchemaService(emptySchema);

        expect(
          service.validateSchema,
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Schema is empty or contains no type definitions'),
            ),
          ),
        );
      });

      test(
        'should throw exception for schema with missing type references',
        () {
          final service = SchemaService(invalidSchema);

          expect(
            service.validateSchema,
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Type NonExistentType not found in schema'),
              ),
            ),
          );
        },
      );

      test('should validate interface implementations', () {
        const schemaWithInvalidInterface = DocumentNode(
          definitions: [
            ObjectTypeDefinitionNode(
              name: NameNode(value: 'User'),
              fields: [
                FieldDefinitionNode(
                  name: NameNode(value: 'id'),
                  type: NamedTypeNode(
                    name: NameNode(value: 'ID'),
                    isNonNull: true,
                  ),
                ),
              ],
              interfaces: [
                NamedTypeNode(name: NameNode(value: 'NonExistentInterface')),
              ],
            ),
          ],
        );

        final service = SchemaService(schemaWithInvalidInterface);

        expect(
          service.validateSchema,
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains(
                'Interface NonExistentInterface referenced by User not found in schema',
              ),
            ),
          ),
        );
      });

      test('should validate union member types', () {
        const schemaWithInvalidUnion = DocumentNode(
          definitions: [
            ObjectTypeDefinitionNode(
              name: NameNode(value: 'User'),
              fields: [
                FieldDefinitionNode(
                  name: NameNode(value: 'id'),
                  type: NamedTypeNode(
                    name: NameNode(value: 'ID'),
                    isNonNull: true,
                  ),
                ),
              ],
            ),
            UnionTypeDefinitionNode(
              name: NameNode(value: 'SearchResult'),
              types: [
                NamedTypeNode(name: NameNode(value: 'User')),
                NamedTypeNode(name: NameNode(value: 'NonExistentType')),
              ],
            ),
          ],
        );

        final service = SchemaService(schemaWithInvalidUnion);

        expect(
          service.validateSchema,
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains(
                'Union member type NonExistentType in SearchResult not found in schema',
              ),
            ),
          ),
        );
      });

      test('should validate list type references', () {
        const schemaWithInvalidListType = DocumentNode(
          definitions: [
            ObjectTypeDefinitionNode(
              name: NameNode(value: 'User'),
              fields: [
                FieldDefinitionNode(
                  name: NameNode(value: 'posts'),
                  type: ListTypeNode(
                    type: NamedTypeNode(
                      name: NameNode(value: 'NonExistentPost'),
                      isNonNull: true,
                    ),
                    isNonNull: true,
                  ),
                ),
              ],
            ),
          ],
        );

        final service = SchemaService(schemaWithInvalidListType);

        expect(
          service.validateSchema,
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Type NonExistentPost not found in schema'),
            ),
          ),
        );
      });

      test('should validate input object field types', () {
        const schemaWithInvalidInputField = DocumentNode(
          definitions: [
            InputObjectTypeDefinitionNode(
              name: NameNode(value: 'CreateUserInput'),
              fields: [
                InputValueDefinitionNode(
                  name: NameNode(value: 'profile'),
                  type: NamedTypeNode(
                    name: NameNode(value: 'NonExistentProfile'),
                  ),
                ),
              ],
            ),
          ],
        );

        final service = SchemaService(schemaWithInvalidInputField);

        expect(
          service.validateSchema,
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Type NonExistentProfile not found in schema'),
            ),
          ),
        );
      });

      test('should validate interface field types', () {
        const schemaWithInvalidInterfaceField = DocumentNode(
          definitions: [
            InterfaceTypeDefinitionNode(
              name: NameNode(value: 'Node'),
              fields: [
                FieldDefinitionNode(
                  name: NameNode(value: 'metadata'),
                  type: NamedTypeNode(
                    name: NameNode(value: 'NonExistentMetadata'),
                  ),
                ),
              ],
            ),
          ],
        );

        final service = SchemaService(schemaWithInvalidInterfaceField);

        expect(
          service.validateSchema,
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Type NonExistentMetadata not found in schema'),
            ),
          ),
        );
      });
    });

    group('error cases and edge conditions', () {
      test('should handle schema with only default scalars', () {
        const scalarOnlySchema = DocumentNode();
        final service = SchemaService(scalarOnlySchema);

        // Should still have default scalars
        expect(service.getTypeByName('String'), isNotNull);
        expect(service.getTypeByName('Int'), isNotNull);
        expect(service.getTypeByName('Float'), isNotNull);
        expect(service.getTypeByName('Boolean'), isNotNull);
        expect(service.getTypeByName('ID'), isNotNull);
      });

      test('should handle case-sensitive type names', () {
        final service = SchemaService(basicSchema);

        expect(service.getTypeByName('User'), isNotNull);
        expect(service.getTypeByName('user'), isNull);
        expect(service.getTypeByName('USER'), isNull);
      });

      test('should handle empty type name lookup', () {
        final service = SchemaService(basicSchema);

        expect(service.getTypeByName(''), isNull);
      });

      test('should handle schema with circular type references', () {
        const circularSchema = DocumentNode(
          definitions: [
            ObjectTypeDefinitionNode(
              name: NameNode(value: 'User'),
              fields: [
                FieldDefinitionNode(
                  name: NameNode(value: 'friend'),
                  type: NamedTypeNode(
                    name: NameNode(value: 'User'),
                  ),
                ),
              ],
            ),
          ],
        );

        final service = SchemaService(circularSchema);

        // Should not throw during validation - circular references are valid
        expect(service.validateSchema, returnsNormally);
      });

      test('should handle schema with deeply nested list types', () {
        const nestedListSchema = DocumentNode(
          definitions: [
            ObjectTypeDefinitionNode(
              name: NameNode(value: 'Matrix'),
              fields: [
                FieldDefinitionNode(
                  name: NameNode(value: 'data'),
                  type: ListTypeNode(
                    type: ListTypeNode(
                      type: ListTypeNode(
                        type: NamedTypeNode(
                          name: NameNode(value: 'Int'),
                          isNonNull: true,
                        ),
                        isNonNull: true,
                      ),
                      isNonNull: true,
                    ),
                    isNonNull: true,
                  ),
                ),
              ],
            ),
          ],
        );

        final service = SchemaService(nestedListSchema);

        expect(service.validateSchema, returnsNormally);
      });

      test('should handle custom scalar options with null values', () {
        final optionsWithNulls = GeneratorOptions(
          scalarMapping: [
            ScalarMap(
              graphQLType: 'DateTime',
            ),
            ScalarMap(
              dartType: const DartType(name: 'String'),
            ),
          ],
        );

        final service = SchemaService(complexSchema);

        // Should not throw, but should handle null values gracefully
        expect(
          () => service.extractCustomImports(optionsWithNulls),
          returnsNormally,
        );
      });
    });
  });
}
