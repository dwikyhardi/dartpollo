import 'package:gql/ast.dart';
import '../visitor/type_definition_node_visitor.dart';
import '../schema/schema_options.dart';

/// Exception thrown when schema context validation fails
class SchemaContextValidationException implements Exception {
  final String message;

  SchemaContextValidationException(this.message);

  @override
  String toString() => 'SchemaContextValidationException: $message';
}

/// Immutable context containing schema-related information and configuration.
/// Provides schema, type visitor, and generator options for the generation process.
class SchemaContext {
  final DocumentNode schema;
  final TypeDefinitionNodeVisitor typeVisitor;
  final GeneratorOptions options;

  const SchemaContext({
    required this.schema,
    required this.typeVisitor,
    required this.options,
  });

  /// Validates the schema context for consistency
  void validate() {
    if (schema.definitions.isEmpty) {
      throw SchemaContextValidationException(
          'Schema must contain at least one definition');
    }

    // Validate that the type visitor has been properly initialized
    if (typeVisitor.types.isEmpty) {
      throw SchemaContextValidationException(
          'Type visitor must be initialized with schema types');
    }

    // Validate that basic scalar types are present
    final requiredScalars = ['Boolean', 'Float', 'ID', 'Int', 'String'];
    for (final scalar in requiredScalars) {
      if (!typeVisitor.types.containsKey(scalar)) {
        throw SchemaContextValidationException(
            'Missing required scalar type: $scalar');
      }
    }

    // Validate that schema definitions match type visitor types
    final schemaTypeNames = schema.definitions
        .whereType<TypeDefinitionNode>()
        .map((node) => node.name.value)
        .toSet();

    final visitorTypeNames = typeVisitor.types.keys
        .where((name) => !requiredScalars.contains(name))
        .toSet();

    if (!schemaTypeNames
        .containsAll(visitorTypeNames.difference(requiredScalars.toSet()))) {
      throw SchemaContextValidationException(
          'Type visitor contains types not found in schema');
    }
  }

  /// Validates that a specific type exists in the schema
  bool hasType(String typeName) {
    return typeVisitor.types.containsKey(typeName);
  }

  /// Gets a type definition by name, returns null if not found
  TypeDefinitionNode? getType(String typeName) {
    return typeVisitor.getByName(typeName);
  }

  /// Returns all available type names
  Set<String> get availableTypes => typeVisitor.types.keys.toSet();
}
