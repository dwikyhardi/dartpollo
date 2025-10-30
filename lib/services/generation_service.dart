import 'package:collection/collection.dart' show IterableExtension;
import 'package:dartpollo/generator/data/data.dart';
import 'package:dartpollo/generator/ephemeral_data.dart';
import 'package:dartpollo/generator/errors.dart';
import 'package:dartpollo/generator/fragment_processor.dart';
import 'package:dartpollo/generator/helpers.dart';
import 'package:dartpollo/visitor/canonical_visitor.dart';
import 'package:dartpollo/visitor/generator_visitor.dart';
import 'package:dartpollo/visitor/object_type_definition_visitor.dart';
import 'package:dartpollo/visitor/schema_definition_visitor.dart';
import 'package:gql/ast.dart';

import '../schema/schema_options.dart';
import 'file_service.dart';
import 'schema_service.dart';

/// Service responsible for coordinating the code generation process.
///
/// This service orchestrates the generation of GraphQL client code by
/// coordinating between schema operations, file operations, and various
/// code generators.
class GenerationService {
  /// Creates a new GenerationService with the required dependencies.
  ///
  /// [schemaService] handles schema operations and type lookups
  /// [fileService] handles file path operations and validation
  GenerationService({
    required this.schemaService,
    required this.fileService,
  });

  final SchemaService schemaService;
  final FileService fileService;

  /// Generates a complete library definition from GraphQL documents.
  ///
  /// This method coordinates the entire generation process:
  /// 1. Sets up the canonical visitor for enums and input objects
  /// 2. Processes fragments from all documents
  /// 3. Generates query definitions for each document
  /// 4. Merges and validates all generated classes
  /// 5. Returns a complete library definition
  ///
  /// [path] - The file path for the generated library
  /// [gqlDocs] - List of GraphQL documents to process
  /// [options] - Generator options and configuration
  /// [schemaMap] - Schema mapping configuration
  /// [fragmentsCommon] - Common fragments shared across documents
  ///
  /// Returns a [LibraryDefinition] containing all generated code
  ///
  /// Throws [DuplicatedClassesException] if duplicate classes are found
  /// Throws [GenerationProcessError] if generation fails
  LibraryDefinition generateLibrary(
    String path,
    List<DocumentNode> gqlDocs,
    GeneratorOptions options,
    SchemaMap schemaMap,
    List<FragmentDefinitionNode> fragmentsCommon,
  ) {
    try {
      // Validate inputs
      if (path.isEmpty) {
        throw GenerationProcessError('Path cannot be empty');
      }
      if (gqlDocs.isEmpty) {
        throw GenerationProcessError('No GraphQL documents provided');
      }

      // Set up canonical visitor for enums and input objects
      final canonicalVisitor = CanonicalVisitor(
        context: Context(
          schema: schemaService.schema,
          typeDefinitionNodeVisitor: schemaService.typeVisitor,
          options: options,
          schemaMap: schemaMap,
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

      schemaService.schema.accept(canonicalVisitor);

      // Extract fragments from all documents
      final documentFragments = gqlDocs
          .map((doc) => doc.definitions.whereType<FragmentDefinitionNode>())
          .expand((e) => e)
          .toList();

      // Create documents without fragments for processing
      final documentsWithoutFragments = gqlDocs.map((doc) {
        return DocumentNode(
          definitions: doc.definitions
              .where((e) => e is! FragmentDefinitionNode)
              .toList(),
          span: doc.span,
        );
      }).toList();

      // Generate query definitions for each document
      final queryDefinitions = documentsWithoutFragments
          .map(
            (doc) => generateDefinitions(
              path: path,
              document: doc,
              options: options,
              schemaMap: schemaMap,
              fragmentsCommon: [
                ...documentFragments,
                ...fragmentsCommon,
              ],
              canonicalVisitor: canonicalVisitor,
            ),
          )
          .expand((e) => e)
          .toList();

      // Validate and merge all generated classes
      final allClassesNames = queryDefinitions
          .map((def) => def.classes.map((c) => c))
          .expand((e) => e)
          .toList();

      _validateAndMergeDuplicateClasses(allClassesNames);

      // Extract basename and custom imports
      final basename = FileService.extractBasename(path);
      final customImports = schemaService.extractCustomImports(options);

      return LibraryDefinition(
        basename: basename,
        queries: queryDefinitions,
        customImports: customImports,
        schemaMap: schemaMap,
      );
    } catch (e) {
      // Preserve original exception types for backward compatibility
      if (e is GenerationProcessError ||
          e is DuplicatedClassesException ||
          e is MissingRootTypeException ||
          e is MissingFragmentException ||
          e is MissingScalarConfigurationException ||
          e is QueryGlobsSchemaException ||
          e is QueryGlobsOutputException ||
          e is MissingFilesException ||
          e is MissingBuildConfigurationException) {
        rethrow;
      }
      throw GenerationProcessError(
        'Failed to generate library: $e',
        context: 'Path: $path, Documents: ${gqlDocs.length}',
        suggestion: 'Check your GraphQL documents and schema for errors',
      );
    }
  }

  /// Generates query definitions from a single GraphQL document.
  ///
  /// This method processes a single document and generates all necessary
  /// query definitions, handling fragments and operations appropriately.
  ///
  /// [path] - The file path for context
  /// [document] - The GraphQL document to process
  /// [options] - Generator options and configuration
  /// [schemaMap] - Schema mapping configuration
  /// [fragmentsCommon] - Common fragments to include
  /// [canonicalVisitor] - Pre-configured canonical visitor
  ///
  /// Returns an iterable of [QueryDefinition] objects
  ///
  /// Throws [MissingRootTypeException] if root type is not found
  /// Throws [GenerationProcessError] if generation fails
  Iterable<QueryDefinition> generateDefinitions({
    required String path,
    required DocumentNode document,
    required GeneratorOptions options,
    required SchemaMap schemaMap,
    required List<FragmentDefinitionNode> fragmentsCommon,
    required CanonicalVisitor canonicalVisitor,
  }) {
    try {
      final operations = document.definitions
          .whereType<OperationDefinitionNode>()
          .toList();

      if (operations.isEmpty) {
        return [];
      }

      return operations.map((operation) {
        return _generateSingleQueryDefinition(
          path: path,
          document: document,
          operation: operation,
          options: options,
          schemaMap: schemaMap,
          fragmentsCommon: fragmentsCommon,
          canonicalVisitor: canonicalVisitor,
        );
      });
    } catch (e) {
      if (e is MissingRootTypeException || e is GenerationProcessError) {
        rethrow;
      }
      throw GenerationProcessError(
        'Failed to generate definitions: $e',
        context: 'Path: $path',
        suggestion: 'Check your GraphQL operations and schema',
      );
    }
  }

  /// Generates a single query definition from an operation.
  QueryDefinition _generateSingleQueryDefinition({
    required String path,
    required DocumentNode document,
    required OperationDefinitionNode operation,
    required GeneratorOptions options,
    required SchemaMap schemaMap,
    required List<FragmentDefinitionNode> fragmentsCommon,
    required CanonicalVisitor canonicalVisitor,
  }) {
    // Prepare definitions for this operation
    final definitions = document.definitions
        .where((e) => e is! OperationDefinitionNode || e == operation)
        .toList();

    // Add required fragments
    if (fragmentsCommon.isNotEmpty) {
      final fragmentsOperation = FragmentProcessor.extractFragments(
        operation.selectionSet,
        fragmentsCommon,
      );
      definitions.addAll(fragmentsOperation);
    }

    // Determine operation details
    final basename = FileService.extractBasename(path).split('.').first;
    final operationName = operation.name?.value ?? basename;

    final (rootTypeName, suffix) = _determineRootTypeAndSuffix(operation);
    final parentType = _findParentType(rootTypeName);

    // Create query name
    final name = QueryName.fromPath(
      path: createPathName([
        ClassName(name: operationName),
        ClassName(name: parentType.name.value),
      ], schemaMap.namingScheme),
    );

    // Create context for generation
    final context = Context(
      schema: schemaService.schema,
      typeDefinitionNodeVisitor: schemaService.typeVisitor,
      options: options,
      schemaMap: schemaMap,
      path: [
        TypeName(name: operationName),
        TypeName(name: parentType.name.value),
      ],
      currentType: parentType,
      currentFieldName: null,
      currentClassName: null,
      generatedClasses: [],
      inputsClasses: [],
      fragments: fragmentsCommon,
      usedEnums: {},
      usedInputObjects: {},
    );

    // Generate the query definition
    final visitor = GeneratorVisitor(context: context);
    final documentDefinitions = DocumentNode(definitions: definitions)
      ..accept(visitor);

    return QueryDefinition(
      name: name,
      operationName: operationName,
      document: documentDefinitions,
      classes: [
        // Include enum definitions if convertEnumToString is false
        if (!schemaMap.convertEnumToString)
          ...context.usedEnums
              .map((e) => canonicalVisitor.enums[e.name]?.call())
              .whereType<Definition>(),
        ...visitor.context.generatedClasses,
        ...context.usedInputObjects
            .map((e) => canonicalVisitor.inputObjects[e.name]?.call())
            .whereType<Definition>(),
      ],
      inputs: visitor.context.inputsClasses,
      generateHelpers: options.generateHelpers,
      generateQueries: options.generateQueries,
      suffix: suffix,
    );
  }

  /// Determines the root type name and suffix for an operation.
  (String, String) _determineRootTypeAndSuffix(
    OperationDefinitionNode operation,
  ) {
    final schemaVisitor = SchemaDefinitionVisitor();
    schemaService.schema.accept(schemaVisitor);

    String suffix;
    switch (operation.type) {
      case OperationType.subscription:
        suffix = 'Subscription';
      case OperationType.mutation:
        suffix = 'Mutation';
      case OperationType.query:
        suffix = 'Query';
    }

    final rootTypeName =
        (schemaVisitor.schemaDefinitionNode?.operationTypes ?? [])
            .firstWhereOrNull((e) => e.operation == operation.type)
            ?.type
            .name
            .value ??
        suffix;

    return (rootTypeName, suffix);
  }

  /// Finds the parent type definition for a root type name.
  ObjectTypeDefinitionNode _findParentType(String rootTypeName) {
    final objectVisitor = ObjectTypeDefinitionVisitor();
    schemaService.schema.accept(objectVisitor);

    final parentType = objectVisitor.getByName(rootTypeName);
    if (parentType == null) {
      throw MissingRootTypeException(rootTypeName);
    }

    return parentType;
  }

  /// Validates and merges duplicate classes, throwing an exception if conflicts exist.
  void _validateAndMergeDuplicateClasses(List<Definition> allClasses) {
    allClasses.mergeDuplicatesBy((a) => a.name, (a, b) {
      if (a.name == b.name && a != b) {
        throw DuplicatedClassesException(a, b);
      }
      return a;
    });
  }
}

/// Exception thrown when the generation process encounters an error.
class GenerationProcessError extends Error {
  GenerationProcessError(
    this.message, {
    this.context,
    this.suggestion,
  });

  final String message;
  final String? context;
  final String? suggestion;

  @override
  String toString() {
    final buffer = StringBuffer('GenerationProcessError: $message');
    if (context != null) {
      buffer.write('\nContext: $context');
    }
    if (suggestion != null) {
      buffer.write('\nSuggestion: $suggestion');
    }
    return buffer.toString();
  }
}
