import 'package:dartpollo_annotation/schema/schema_options.dart';
import 'package:dartpollo_generator/generator/data/data.dart';
import 'package:dartpollo_generator/generator/ephemeral_data.dart';
import 'package:dartpollo_generator/services/file_service.dart';
import 'package:dartpollo_generator/services/generation_service.dart';
import 'package:dartpollo_generator/services/schema_service.dart';
import 'package:dartpollo_generator/visitor/canonical_visitor.dart';
import 'package:gql/ast.dart';
import 'package:test/test.dart';

void main() {
  group('GenerationService', () {
    late SchemaService schemaService;
    late GenerationService generationService;
    late DocumentNode basicSchema;
    late DocumentNode queryDocument;
    late GeneratorOptions basicOptions;
    late SchemaMap basicSchemaMap;

    setUp(() {
      // Basic schema setup
      basicSchema = const DocumentNode(
        definitions: [
          ObjectTypeDefinitionNode(
            name: NameNode(value: 'Query'),
            fields: [
              FieldDefinitionNode(
                name: NameNode(value: 'user'),
                type: NamedTypeNode(
                  name: NameNode(value: 'User'),
                ),
                args: [
                  InputValueDefinitionNode(
                    name: NameNode(value: 'id'),
                    type: NamedTypeNode(
                      name: NameNode(value: 'ID'),
                      isNonNull: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
        ],
      );

      // Simple query document
      queryDocument = const DocumentNode(
        definitions: [
          OperationDefinitionNode(
            type: OperationType.query,
            name: NameNode(value: 'GetUser'),
            selectionSet: SelectionSetNode(
              selections: [
                FieldNode(
                  name: NameNode(value: 'user'),
                  arguments: [
                    ArgumentNode(
                      name: NameNode(value: 'id'),
                      value: StringValueNode(value: '1', isBlock: false),
                    ),
                  ],
                  selectionSet: SelectionSetNode(
                    selections: [
                      FieldNode(name: NameNode(value: 'id')),
                      FieldNode(name: NameNode(value: 'name')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );

      basicOptions = GeneratorOptions(
        scalarMapping: [],
      );

      basicSchemaMap = SchemaMap();

      // Create real services for integration testing
      schemaService = SchemaService(basicSchema);
      generationService = GenerationService(
        schemaService: schemaService,
        fileService: FileService.instance,
      );
    });

    group('constructor and dependency injection', () {
      test('should initialize with required dependencies', () {
        final service = GenerationService(
          schemaService: schemaService,
          fileService: FileService.instance,
        );

        expect(service.schemaService, equals(schemaService));
        expect(service.fileService, isA<FileService>());
      });
    });

    group('generateLibrary', () {
      test('should generate library with single query document', () {
        final result = generationService.generateLibrary(
          'test_query.graphql.dart',
          [queryDocument],
          basicOptions,
          basicSchemaMap,
          [],
        );

        expect(result, isA<LibraryDefinition>());
        expect(result.basename, equals('test_query.graphql'));
        expect(result.queries, isNotEmpty);
        expect(result.schemaMap, equals(basicSchemaMap));
      });

      test('should throw GenerationProcessError for empty path', () {
        expect(
          () => generationService.generateLibrary(
            '',
            [queryDocument],
            basicOptions,
            basicSchemaMap,
            [],
          ),
          throwsA(
            isA<GenerationProcessError>().having(
              (e) => e.message,
              'message',
              contains('Path cannot be empty'),
            ),
          ),
        );
      });

      test('should throw GenerationProcessError for empty documents', () {
        expect(
          () => generationService.generateLibrary(
            'test.graphql.dart',
            [],
            basicOptions,
            basicSchemaMap,
            [],
          ),
          throwsA(
            isA<GenerationProcessError>().having(
              (e) => e.message,
              'message',
              contains('No GraphQL documents provided'),
            ),
          ),
        );
      });

      test('should include custom imports', () {
        final result = generationService.generateLibrary(
          'test_query.graphql.dart',
          [queryDocument],
          basicOptions,
          basicSchemaMap,
          [],
        );

        expect(result.customImports, isA<List<String>>());
      });
    });

    group('generateDefinitions', () {
      test('should generate definitions for query operation', () {
        final canonicalVisitor = CanonicalVisitor(
          context: Context(
            schema: basicSchema,
            typeDefinitionNodeVisitor: schemaService.typeVisitor,
            options: basicOptions,
            schemaMap: basicSchemaMap,
            path: [],
            currentType: null,
            currentFieldName: null,
            currentClassName: null,
            generatedClasses: [],
            inputsClasses: [],
            fragments: [],
            usedEnums: {},
            usedInputObjects: {},
          ),
        );

        final definitions = generationService.generateDefinitions(
          path: 'test_query.graphql.dart',
          document: queryDocument,
          options: basicOptions,
          schemaMap: basicSchemaMap,
          fragmentsCommon: [],
          canonicalVisitor: canonicalVisitor,
        );

        expect(definitions, isNotEmpty);
        expect(definitions.length, equals(1));

        final definition = definitions.first;
        expect(definition.operationName, equals('GetUser'));
        expect(definition.suffix, equals('Query'));
      });

      test('should handle document with no operations', () {
        const emptyDocument = DocumentNode();
        final canonicalVisitor = CanonicalVisitor(
          context: Context(
            schema: basicSchema,
            typeDefinitionNodeVisitor: schemaService.typeVisitor,
            options: basicOptions,
            schemaMap: basicSchemaMap,
            path: [],
            currentType: null,
            currentFieldName: null,
            currentClassName: null,
            generatedClasses: [],
            inputsClasses: [],
            fragments: [],
            usedEnums: {},
            usedInputObjects: {},
          ),
        );

        final definitions = generationService.generateDefinitions(
          path: 'empty.graphql.dart',
          document: emptyDocument,
          options: basicOptions,
          schemaMap: basicSchemaMap,
          fragmentsCommon: [],
          canonicalVisitor: canonicalVisitor,
        );

        expect(definitions, isEmpty);
      });
    });

    group('error handling and recovery', () {
      test('should provide detailed error context', () {
        // Create a service with invalid schema to trigger error
        const invalidSchema = DocumentNode();
        final invalidSchemaService = SchemaService(invalidSchema);
        final invalidGenerationService = GenerationService(
          schemaService: invalidSchemaService,
          fileService: FileService.instance,
        );

        expect(
          () => invalidGenerationService.generateLibrary(
            'test.graphql.dart',
            [queryDocument],
            basicOptions,
            basicSchemaMap,
            [],
          ),
          throwsA(anything),
        );
      });
    });

    group('service integration', () {
      test('should coordinate between schema and file services', () {
        final result = generationService.generateLibrary(
          'integration_test.graphql.dart',
          [queryDocument],
          basicOptions,
          basicSchemaMap,
          [],
        );

        expect(result.basename, equals('integration_test.graphql'));
        expect(result.customImports, isA<List<String>>());
      });
    });
  });
}
