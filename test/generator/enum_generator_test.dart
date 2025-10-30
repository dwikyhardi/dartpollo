import 'package:dartpollo/generator/data/data.dart';
import 'package:dartpollo/generator/enum_generator.dart';
import 'package:dartpollo/generator/ephemeral_data.dart';
import 'package:dartpollo/schema/schema_options.dart';
import 'package:dartpollo/visitor/type_definition_node_visitor.dart';
import 'package:gql/ast.dart';
import 'package:test/test.dart';

void main() {
  group('EnumGenerator', () {
    late Context mockContext;
    late DocumentNode mockSchema;
    late TypeDefinitionNodeVisitor mockTypeVisitor;
    late GeneratorOptions mockOptions;
    late SchemaMap mockSchemaMap;

    setUp(() {
      mockSchema = const DocumentNode();
      mockTypeVisitor = TypeDefinitionNodeVisitor();
      mockOptions = GeneratorOptions();
      mockSchemaMap = SchemaMap();

      mockContext = Context(
        schema: mockSchema,
        typeDefinitionNodeVisitor: mockTypeVisitor,
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

    group('unknownEnumValue', () {
      test('should have correct name', () {
        expect(EnumGenerator.unknownEnumValue.name.name, equals('UNKNOWN'));
        expect(
          EnumGenerator.unknownEnumValue.name.namePrintable,
          equals('unknown'),
        );
      });

      test('should have empty annotations', () {
        expect(EnumGenerator.unknownEnumValue.annotations, isEmpty);
      });
    });

    group('generateEnum', () {
      test('should generate enum with basic values', () {
        const enumNode = EnumTypeDefinitionNode(
          name: NameNode(value: 'Status'),
          values: [
            EnumValueDefinitionNode(
              name: NameNode(value: 'ACTIVE'),
            ),
            EnumValueDefinitionNode(
              name: NameNode(value: 'INACTIVE'),
            ),
          ],
        );

        final result = EnumGenerator.generateEnum(enumNode, mockContext);

        expect(result.name.name, equals('Status'));
        expect(result.name.namePrintable, equals('Status'));
        expect(result.values.length, equals(3)); // 2 values + UNKNOWN

        final valueNames = result.values.map((v) => v.name.name).toList();
        expect(valueNames, contains('ACTIVE'));
        expect(valueNames, contains('INACTIVE'));
        expect(valueNames, contains('UNKNOWN'));
      });

      test('should generate enum with deprecated values', () {
        const enumNode = EnumTypeDefinitionNode(
          name: NameNode(value: 'Status'),
          values: [
            EnumValueDefinitionNode(
              name: NameNode(value: 'ACTIVE'),
            ),
            EnumValueDefinitionNode(
              name: NameNode(value: 'DEPRECATED_VALUE'),
              directives: [
                DirectiveNode(
                  name: NameNode(value: 'deprecated'),
                  arguments: [
                    ArgumentNode(
                      name: NameNode(value: 'reason'),
                      value: StringValueNode(
                        value: 'Use ACTIVE instead',
                        isBlock: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

        final result = EnumGenerator.generateEnum(enumNode, mockContext);

        expect(result.values.length, equals(3)); // 2 values + UNKNOWN

        final deprecatedValue = result.values.firstWhere(
          (v) => v.name.name == 'DEPRECATED_VALUE',
        );
        expect(deprecatedValue.annotations, isNotEmpty);
        expect(deprecatedValue.annotations.first, contains('Deprecated'));
      });

      test('should generate enum with empty values', () {
        const enumNode = EnumTypeDefinitionNode(
          name: NameNode(value: 'EmptyEnum'),
        );

        final result = EnumGenerator.generateEnum(enumNode, mockContext);

        expect(result.name.name, equals('EmptyEnum'));
        expect(result.values.length, equals(1)); // Only UNKNOWN
        expect(result.values.first.name.name, equals('UNKNOWN'));
      });
    });

    group('generateEnumValues', () {
      test('should generate values with correct names', () {
        final valueNodes = [
          const EnumValueDefinitionNode(
            name: NameNode(value: 'FIRST_VALUE'),
          ),
          const EnumValueDefinitionNode(
            name: NameNode(value: 'SECOND_VALUE'),
          ),
        ];

        final result = EnumGenerator.generateEnumValues(
          valueNodes,
          mockContext,
        );

        expect(result.length, equals(3)); // 2 values + UNKNOWN
        expect(result[0].name.name, equals('FIRST_VALUE'));
        expect(result[0].name.namePrintable, equals('firstValue'));
        expect(result[1].name.name, equals('SECOND_VALUE'));
        expect(result[1].name.namePrintable, equals('secondValue'));
        expect(result[2].name.name, equals('UNKNOWN'));
      });

      test('should handle deprecated enum values', () {
        final valueNodes = [
          const EnumValueDefinitionNode(
            name: NameNode(value: 'NORMAL_VALUE'),
          ),
          const EnumValueDefinitionNode(
            name: NameNode(value: 'OLD_VALUE'),
            directives: [
              DirectiveNode(
                name: NameNode(value: 'deprecated'),
                arguments: [
                  ArgumentNode(
                    name: NameNode(value: 'reason'),
                    value: StringValueNode(
                      value: 'Use NORMAL_VALUE instead',
                      isBlock: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ];

        final result = EnumGenerator.generateEnumValues(
          valueNodes,
          mockContext,
        );

        expect(result.length, equals(3)); // 2 values + UNKNOWN

        final normalValue = result.firstWhere(
          (v) => v.name.name == 'NORMAL_VALUE',
        );
        expect(normalValue.annotations, isEmpty);

        final deprecatedValue = result.firstWhere(
          (v) => v.name.name == 'OLD_VALUE',
        );
        expect(deprecatedValue.annotations, isNotEmpty);
        expect(deprecatedValue.annotations.first, contains('Deprecated'));
      });

      test('should always add unknown enum value', () {
        final valueNodes = <EnumValueDefinitionNode>[];

        final result = EnumGenerator.generateEnumValues(
          valueNodes,
          mockContext,
        );

        expect(result.length, equals(1));
        expect(result.first.name.name, equals('UNKNOWN'));
      });
    });

    group('handleEnumToStringConversion', () {
      test('should convert single enum to String type', () {
        const fieldType = NamedTypeNode(name: NameNode(value: 'Status'));
        final dartTypeName = TypeName(name: 'Status', isNonNull: true);
        const name = ClassPropertyName(name: 'status');
        final jsonKeyAnnotation = <String, String>{};

        final result = EnumGenerator.handleEnumToStringConversion(
          fieldType: fieldType,
          dartTypeName: dartTypeName,
          name: name,
          jsonKeyAnnotation: jsonKeyAnnotation,
        );

        expect(result.type.name, equals('String'));
        expect(result.type.isNonNull, isTrue);
        expect(result.name.name, equals('status'));
        expect(result.annotations, isEmpty);
      });

      test('should convert single enum to String with JsonKey annotation', () {
        const fieldType = NamedTypeNode(name: NameNode(value: 'Status'));
        final dartTypeName = TypeName(name: 'Status', isNonNull: true);
        const name = ClassPropertyName(name: 'userStatus');
        final jsonKeyAnnotation = {'name': "'status'"};

        final result = EnumGenerator.handleEnumToStringConversion(
          fieldType: fieldType,
          dartTypeName: dartTypeName,
          name: name,
          jsonKeyAnnotation: jsonKeyAnnotation,
        );

        expect(result.type.name, equals('String'));
        expect(result.annotations.length, equals(1));
        expect(result.annotations.first, equals('JsonKey(name: \'status\')'));
      });

      test('should convert list of enums to List<String>', () {
        const fieldType = ListTypeNode(
          type: NamedTypeNode(
            name: NameNode(value: 'Status'),
          ),
          isNonNull: true,
        );
        final dartTypeName = ListOfTypeName(
          typeName: TypeName(name: 'Status'),
        );
        const name = ClassPropertyName(name: 'statuses');
        final jsonKeyAnnotation = <String, String>{};

        final result = EnumGenerator.handleEnumToStringConversion(
          fieldType: fieldType,
          dartTypeName: dartTypeName,
          name: name,
          jsonKeyAnnotation: jsonKeyAnnotation,
        );

        expect(result.type, isA<ListOfTypeName>());
        final listType = result.type as ListOfTypeName;
        expect(listType.typeName.name, equals('String'));
        expect(listType.isNonNull, isTrue);
        expect(result.name.name, equals('statuses'));
      });

      test(
        'should convert list of enums with JsonKey annotation when names differ',
        () {
          const fieldType = ListTypeNode(
            type: NamedTypeNode(
              name: NameNode(value: 'Status'),
            ),
            isNonNull: true,
          );
          final dartTypeName = ListOfTypeName(
            typeName: TypeName(name: 'Status'),
          );
          // Create a name where the printable name differs from the raw name
          const name = ClassPropertyName(
            name: 'user_statuses',
          ); // This will be converted to userStatuses
          final jsonKeyAnnotation = <String, String>{};

          final result = EnumGenerator.handleEnumToStringConversion(
            fieldType: fieldType,
            dartTypeName: dartTypeName,
            name: name,
            jsonKeyAnnotation: jsonKeyAnnotation,
          );

          expect(result.annotations.length, equals(1));
          expect(
            result.annotations.first,
            equals('JsonKey(name: \'user_statuses\')'),
          );
        },
      );

      test(
        'should convert list of enums without JsonKey annotation when names match',
        () {
          const fieldType = ListTypeNode(
            type: NamedTypeNode(
              name: NameNode(value: 'Status'),
            ),
            isNonNull: true,
          );
          final dartTypeName = ListOfTypeName(
            typeName: TypeName(name: 'Status'),
          );
          const name = ClassPropertyName(name: 'statuses');
          final jsonKeyAnnotation = <String, String>{};

          final result = EnumGenerator.handleEnumToStringConversion(
            fieldType: fieldType,
            dartTypeName: dartTypeName,
            name: name,
            jsonKeyAnnotation: jsonKeyAnnotation,
          );

          expect(result.annotations, isEmpty);
        },
      );
    });

    group('addUnknownEnumValueAnnotation', () {
      test('should add unknown enum value annotation for single enum', () {
        const fieldType = NamedTypeNode(name: NameNode(value: 'Status'));
        final dartTypeName = TypeName(name: 'Status', isNonNull: true);
        final jsonKeyAnnotation = <String, String>{};

        EnumGenerator.addUnknownEnumValueAnnotation(
          fieldType: fieldType,
          dartTypeName: dartTypeName,
          jsonKeyAnnotation: jsonKeyAnnotation,
        );

        expect(
          jsonKeyAnnotation['unknownEnumValue'],
          equals('Status.${EnumGenerator.unknownEnumValue.name.namePrintable}'),
        );
      });

      test('should add unknown enum value annotation for list of enums', () {
        const fieldType = ListTypeNode(
          type: NamedTypeNode(
            name: NameNode(value: 'Status'),
          ),
          isNonNull: true,
        );
        final dartTypeName = ListOfTypeName(
          typeName: TypeName(name: 'Status'),
        );
        final jsonKeyAnnotation = <String, String>{};

        EnumGenerator.addUnknownEnumValueAnnotation(
          fieldType: fieldType,
          dartTypeName: dartTypeName,
          jsonKeyAnnotation: jsonKeyAnnotation,
        );

        expect(
          jsonKeyAnnotation['unknownEnumValue'],
          equals('Status.${EnumGenerator.unknownEnumValue.name.namePrintable}'),
        );
      });

      test('should handle non-list types gracefully', () {
        const fieldType = NamedTypeNode(name: NameNode(value: 'CustomEnum'));
        final dartTypeName = TypeName(name: 'CustomEnum');
        final jsonKeyAnnotation = <String, String>{};

        EnumGenerator.addUnknownEnumValueAnnotation(
          fieldType: fieldType,
          dartTypeName: dartTypeName,
          jsonKeyAnnotation: jsonKeyAnnotation,
        );

        expect(
          jsonKeyAnnotation['unknownEnumValue'],
          equals(
            'CustomEnum.${EnumGenerator.unknownEnumValue.name.namePrintable}',
          ),
        );
      });
    });

    group('error cases and edge conditions', () {
      test('should handle enum with special characters in name', () {
        const enumNode = EnumTypeDefinitionNode(
          name: NameNode(value: 'Status_With_Underscores'),
          values: [
            EnumValueDefinitionNode(
              name: NameNode(value: 'VALUE_WITH_UNDERSCORES'),
            ),
          ],
        );

        final result = EnumGenerator.generateEnum(enumNode, mockContext);

        expect(result.name.name, equals('Status_With_Underscores'));
        expect(result.values.length, equals(2)); // 1 value + UNKNOWN
      });

      test('should handle enum values with complex directive structures', () {
        const enumNode = EnumTypeDefinitionNode(
          name: NameNode(value: 'ComplexEnum'),
          values: [
            EnumValueDefinitionNode(
              name: NameNode(value: 'COMPLEX_VALUE'),
              directives: [
                DirectiveNode(
                  name: NameNode(value: 'deprecated'),
                  arguments: [
                    ArgumentNode(
                      name: NameNode(value: 'reason'),
                      value: StringValueNode(
                        value: 'Complex reason with "quotes"',
                        isBlock: false,
                      ),
                    ),
                  ],
                ),
                DirectiveNode(
                  name: NameNode(value: 'customDirective'),
                ),
              ],
            ),
          ],
        );

        final result = EnumGenerator.generateEnum(enumNode, mockContext);

        expect(result.values.length, equals(2)); // 1 value + UNKNOWN
        final complexValue = result.values.firstWhere(
          (v) => v.name.name == 'COMPLEX_VALUE',
        );
        expect(complexValue.annotations, isNotEmpty);
      });

      test('should handle nullable list types in enum conversion', () {
        const fieldType = ListTypeNode(
          type: NamedTypeNode(
            name: NameNode(value: 'Status'),
          ),
          isNonNull: false,
        );
        final dartTypeName = ListOfTypeName(
          typeName: TypeName(name: 'Status'),
          isNonNull: false, // Nullable list
        );
        const name = ClassPropertyName(name: 'optionalStatuses');
        final jsonKeyAnnotation = <String, String>{};

        final result = EnumGenerator.handleEnumToStringConversion(
          fieldType: fieldType,
          dartTypeName: dartTypeName,
          name: name,
          jsonKeyAnnotation: jsonKeyAnnotation,
        );

        expect(result.type, isA<ListOfTypeName>());
        final listType = result.type as ListOfTypeName;
        expect(listType.isNonNull, isFalse); // Should preserve nullable nature
      });
    });
  });
}
