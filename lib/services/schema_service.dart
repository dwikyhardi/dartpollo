import 'package:gql/ast.dart';

import '../generator/graphql_helpers.dart' as gql;
import '../schema/schema_options.dart';
import '../visitor/type_definition_node_visitor.dart';

/// Service responsible for schema operations including parsing, validation,
/// and type lookup functionality.
///
/// This service provides a centralized interface for all schema-related operations
/// in the DartPollo code generation process. It handles:
/// - Schema parsing and type visitor initialization
/// - Type definition lookups by name
/// - Custom import extraction for scalar types
/// - Schema validation and consistency checks
///
/// The service is designed to be immutable after construction, with the schema
/// and type visitor being initialized once and reused throughout the generation process.
class SchemaService {
  /// Creates a new SchemaService and initializes the type visitor.
  ///
  /// The constructor automatically processes the schema by accepting the
  /// type visitor, which builds an internal index of all type definitions
  /// for efficient lookup operations.
  ///
  /// [schema] The GraphQL schema document to process
  SchemaService(this.schema) : typeVisitor = TypeDefinitionNodeVisitor() {
    schema.accept(typeVisitor);
  }

  /// The GraphQL schema document containing all type definitions
  final DocumentNode schema;

  /// Visitor that indexes all type definitions for fast lookup
  final TypeDefinitionNodeVisitor typeVisitor;

  /// Retrieves a type definition by name from the schema.
  ///
  /// This method provides fast O(1) lookup of type definitions using the
  /// internal type visitor index. It can find any type definition including:
  /// - Object types
  /// - Interface types
  /// - Union types
  /// - Enum types
  /// - Input types
  /// - Scalar types
  ///
  /// [name] The name of the type to look up
  ///
  /// Returns the [TypeDefinitionNode] if found, or null if the type doesn't exist
  ///
  /// Example:
  /// ```dart
  /// final userType = schemaService.getTypeByName('User');
  /// if (userType is ObjectTypeDefinitionNode) {
  ///   // Process object type
  /// }
  /// ```
  TypeDefinitionNode? getTypeByName(String name) {
    return typeVisitor.getByName(name);
  }

  /// Extracts custom imports required for scalar types based on generator options.
  ///
  /// This method analyzes all scalar types defined in the schema and determines
  /// which custom imports are needed based on the scalar mapping configuration
  /// in the generator options. It's used to generate the appropriate import
  /// statements in the generated Dart code.
  ///
  /// [options] The generator options containing scalar mapping configuration
  ///
  /// Returns a list of import statements needed for custom scalar types
  ///
  /// Example:
  /// ```dart
  /// final imports = schemaService.extractCustomImports(options);
  /// // imports might contain: ['package:my_app/scalars.dart']
  /// ```
  List<String> extractCustomImports(GeneratorOptions options) {
    return typeVisitor.types.values
        .whereType<ScalarTypeDefinitionNode>()
        .map((type) => gql.importsOfScalar(options, type.name.value))
        .expand((i) => i)
        .toSet()
        .toList();
  }

  /// Validates the schema for consistency and completeness
  void validateSchema() {
    // Basic schema validation - check if schema has any non-default type definitions
    final nonDefaultTypes = typeVisitor.types.values.where((type) {
      // Filter out default scalar types
      final defaultScalars = {'Boolean', 'Float', 'ID', 'Int', 'String'};
      return !defaultScalars.contains(type.name.value);
    });

    if (nonDefaultTypes.isEmpty) {
      throw Exception('Schema is empty or contains no type definitions');
    }

    // Validate that all referenced types exist
    nonDefaultTypes.forEach(_validateTypeReferences);
  }

  /// Validates that all type references in a type definition exist in the schema
  void _validateTypeReferences(TypeDefinitionNode type) {
    if (type is ObjectTypeDefinitionNode) {
      // Validate field types
      for (final field in type.fields) {
        _validateTypeNode(field.type);
      }
      // Validate interface implementations
      for (final interface in type.interfaces) {
        if (getTypeByName(interface.name.value) == null) {
          throw Exception(
            'Interface ${interface.name.value} referenced by ${type.name.value} not found in schema',
          );
        }
      }
    } else if (type is InterfaceTypeDefinitionNode) {
      // Validate field types
      for (final field in type.fields) {
        _validateTypeNode(field.type);
      }
    } else if (type is InputObjectTypeDefinitionNode) {
      // Validate input field types
      for (final field in type.fields) {
        _validateTypeNode(field.type);
      }
    } else if (type is UnionTypeDefinitionNode) {
      // Validate union member types
      for (final memberType in type.types) {
        if (getTypeByName(memberType.name.value) == null) {
          throw Exception(
            'Union member type ${memberType.name.value} in ${type.name.value} not found in schema',
          );
        }
      }
    }
  }

  /// Validates a type node recursively
  void _validateTypeNode(TypeNode typeNode) {
    if (typeNode is NamedTypeNode) {
      if (getTypeByName(typeNode.name.value) == null) {
        throw Exception('Type ${typeNode.name.value} not found in schema');
      }
    } else if (typeNode is ListTypeNode) {
      _validateTypeNode(typeNode.type);
    }
  }
}
