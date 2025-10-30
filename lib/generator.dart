import 'package:collection/collection.dart' show IterableExtension;
import 'package:dartpollo/generator/class_generator.dart';
import 'package:dartpollo/generator/data/data.dart';
import 'package:dartpollo/generator/errors.dart'
    show DuplicatedClassesException, MissingRootTypeException;
import 'package:dartpollo/generator/input_generator.dart';
import 'package:dartpollo/services/file_service.dart';
import 'package:dartpollo/services/generation_service.dart';
import 'package:dartpollo/services/schema_service.dart';
import 'package:dartpollo/visitor/canonical_visitor.dart';
import 'package:dartpollo/visitor/type_definition_node_visitor.dart';
import 'package:gql/ast.dart';

import './generator/ephemeral_data.dart';
import './schema/schema_options.dart';

/// Callback function type for handling new class discoveries during generation.
///
/// This callback is invoked whenever a new class needs to be generated
/// during the GraphQL code generation process.
typedef OnNewClassFoundCallback = void Function(Context context);

/// Generates a complete library definition from GraphQL documents and schema.
///
/// This is the main entry point for generating Dart code from GraphQL documents.
/// It coordinates the entire generation process by:
/// 1. Creating necessary services (SchemaService, FileService, GenerationService)
/// 2. Delegating the generation work to the GenerationService
/// 3. Returning a complete LibraryDefinition with all generated code
///
/// **Parameters:**
/// - [path] - The file path for the generated library (used for naming)
/// - [gqlDocs] - List of GraphQL documents containing queries, mutations, subscriptions
/// - [options] - Generator configuration options (naming schemes, features, etc.)
/// - [schemaMap] - Schema mapping configuration for type resolution
/// - [fragmentsCommon] - Common fragments shared across documents
/// - [schema] - The GraphQL schema document
///
/// **Returns:**
/// A [LibraryDefinition] containing all generated classes, queries, and metadata
///
/// **Throws:**
/// - [GenerationProcessError] if generation fails
/// - [DuplicatedClassesException] if duplicate classes are detected
/// - [MissingRootTypeException] if required root types are missing
///
/// **Example:**
/// ```dart
/// final library = generateLibrary(
///   'lib/graphql/queries.dart',
///   [queryDocument, mutationDocument],
///   GeneratorOptions(),
///   SchemaMap(),
///   [],
///   schemaDocument,
/// );
/// ```
LibraryDefinition generateLibrary(
  String path,
  List<DocumentNode> gqlDocs,
  GeneratorOptions options,
  SchemaMap schemaMap,
  List<FragmentDefinitionNode> fragmentsCommon,
  DocumentNode schema,
) {
  // Create services with dependency injection
  final schemaService = SchemaService(schema);
  const fileService = FileService.instance;
  final generationService = GenerationService(
    schemaService: schemaService,
    fileService: fileService,
  );

  // Use GenerationService to generate the library
  return generationService.generateLibrary(
    path,
    gqlDocs,
    options,
    schemaMap,
    fragmentsCommon,
  );
}

/// Generates query definitions from a single GraphQL document.
///
/// This function processes a single GraphQL document and generates all necessary
/// query definitions. It's typically used internally by the generation pipeline
/// but can also be used directly for more granular control.
///
/// **Parameters:**
/// - [schema] - The GraphQL schema document
/// - [typeDefinitionNodeVisitor] - Visitor for type definitions (legacy parameter)
/// - [path] - The file path for context
/// - [document] - The GraphQL document to process
/// - [options] - Generator configuration options
/// - [schemaMap] - Schema mapping configuration
/// - [fragmentsCommon] - Common fragments to include
/// - [canonicalVisitor] - Pre-configured canonical visitor
///
/// **Returns:**
/// An iterable of [QueryDefinition] objects representing the generated queries
///
/// **Throws:**
/// - [GenerationProcessError] if generation fails
/// - [MissingRootTypeException] if root type is not found
///
/// **Note:**
/// This function is primarily used internally. For most use cases,
/// prefer using [generateLibrary] instead.
Iterable<QueryDefinition> generateDefinitions({
  required DocumentNode schema,
  required TypeDefinitionNodeVisitor typeDefinitionNodeVisitor,
  required String path,
  required DocumentNode document,
  required GeneratorOptions options,
  required SchemaMap schemaMap,
  required List<FragmentDefinitionNode> fragmentsCommon,
  required CanonicalVisitor canonicalVisitor,
}) {
  // Create services for this generation
  final schemaService = SchemaService(schema);
  const fileService = FileService.instance;
  final generationService = GenerationService(
    schemaService: schemaService,
    fileService: fileService,
  );

  // Use GenerationService to generate definitions
  return generationService.generateDefinitions(
    path: path,
    document: document,
    options: options,
    schemaMap: schemaMap,
    fragmentsCommon: fragmentsCommon,
    canonicalVisitor: canonicalVisitor,
  );
}

// Removed _extractCustomImports - now handled by SchemaService.extractCustomImports

/// Creates a class property object from GraphQL field information.
///
/// This function analyzes a GraphQL field and creates the corresponding
/// Dart class property with proper type mapping, annotations, and validation.
/// It handles both regular object fields and input object fields by delegating
/// to the appropriate specialized generators.
///
/// **Parameters:**
/// - [fieldName] - The name of the field to create a property for
/// - [fieldAlias] - Optional alias for the field (used in queries)
/// - [context] - The current generation context containing schema and type information
/// - [onNewClassFound] - Optional callback for when new classes need to be generated
/// - [markAsUsed] - Whether to mark related types as used (default: true)
///
/// **Returns:**
/// A [ClassProperty] object representing the Dart property
///
/// **Throws:**
/// - [Exception] if the field is not found in the GraphQL type
/// - [Exception] if unable to determine the field type
///
/// **Special Handling:**
/// - `__typename` fields are automatically handled with proper JSON annotations
/// - Input object fields are processed using [InputGenerator]
/// - Regular object fields are processed using [ClassGenerator]
///
/// **Example:**
/// ```dart
/// final property = createClassProperty(
///   fieldName: ClassPropertyName(name: 'userId'),
///   context: generationContext,
///   onNewClassFound: (context) => print('New class: ${context.currentClassName}'),
/// );
/// ```
ClassProperty createClassProperty({
  required ClassPropertyName fieldName,
  ClassPropertyName? fieldAlias,
  required Context context,
  OnNewClassFoundCallback? onNewClassFound,
  bool markAsUsed = true,
}) {
  // Handle __typename field
  if (fieldName.name == context.schemaMap.typeNameField) {
    return ClassProperty(
      type: TypeName(name: 'String'),
      name: fieldName,
      annotations: ['JsonKey(name: \'${context.schemaMap.typeNameField}\')'],
      isResolveType: true,
    );
  }

  // Determine field type and directives based on current type
  var finalFields = <Node>[];
  if (context.currentType is ObjectTypeDefinitionNode) {
    finalFields = (context.currentType! as ObjectTypeDefinitionNode).fields;
  } else if (context.currentType is InterfaceTypeDefinitionNode) {
    finalFields = (context.currentType! as InterfaceTypeDefinitionNode).fields;
  } else if (context.currentType is InputObjectTypeDefinitionNode) {
    finalFields =
        (context.currentType! as InputObjectTypeDefinitionNode).fields;
  }

  final regularField = finalFields
      .whereType<FieldDefinitionNode>()
      .firstWhereOrNull((f) => f.name.value == fieldName.name);
  final regularInputField = finalFields
      .whereType<InputValueDefinitionNode>()
      .firstWhereOrNull((f) => f.name.value == fieldName.name);

  final fieldType = regularField?.type ?? regularInputField?.type;
  final fieldDirectives =
      regularField?.directives ?? regularInputField?.directives;

  if (fieldType == null) {
    throw Exception(
      '''Field $fieldName was not found in GraphQL type ${context.currentType?.name.value}.
Make sure your query is correct and your schema is updated.''',
    );
  }

  // Use ClassGenerator or InputGenerator based on context
  if (context.currentType is InputObjectTypeDefinitionNode &&
      regularInputField != null) {
    // Use InputGenerator for input object fields
    return InputGenerator.createInputClassProperty(
      fieldName: fieldName,
      fieldType: fieldType,
      fieldDirectives: regularInputField.directives,
      context: context,
    );
  } else if (regularField != null) {
    // Use ClassGenerator for regular object fields
    return ClassGenerator.createClassProperty(
      fieldName: fieldName,
      fieldAlias: fieldAlias,
      fieldType: fieldType,
      fieldDirectives: fieldDirectives,
      context: context,
      onNewClassFound: onNewClassFound ?? (_) {},
      markAsUsed: markAsUsed,
    );
  } else {
    throw Exception(
      '''Unable to determine field type for $fieldName in ${context.currentType?.name.value}''',
    );
  }
}
