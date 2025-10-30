import 'package:dartpollo/generator/data/data.dart';
import 'package:dartpollo/generator/data/enum_value_definition.dart';
import 'package:dartpollo/generator/data/nullable.dart';
import 'package:dartpollo/generator/ephemeral_data.dart';
import 'package:dartpollo/generator/helpers.dart';
import 'package:gql/ast.dart';

/// Generator for GraphQL enum types.
///
/// This class provides static methods for generating Dart enum definitions
/// from GraphQL enum type definitions. It handles:
/// - Enum value generation with proper naming conventions
/// - Unknown enum value handling for forward compatibility
/// - Enum-to-string conversion support
/// - Deprecated enum value handling
///
/// The generator follows GraphQL best practices by automatically adding
/// an UNKNOWN enum value to handle cases where the server returns enum
/// values not known to the client (useful for schema evolution).
class EnumGenerator {
  /// Private constructor to prevent instantiation.
  const EnumGenerator._();

  /// Standard enum value for handling unknown enum values from the server.
  ///
  /// This value is automatically added to all generated enums to provide
  /// forward compatibility when the GraphQL schema evolves and new enum
  /// values are added on the server side. The client can gracefully handle
  /// these unknown values instead of failing to deserialize.
  ///
  /// Example usage in generated code:
  /// ```dart
  /// enum UserRole {
  ///   ADMIN,
  ///   USER,
  ///   UNKNOWN, // This value
  /// }
  /// ```
  static final EnumValueDefinition unknownEnumValue = EnumValueDefinition(
    name: EnumValueName(name: 'UNKNOWN'),
  );

  /// Generates a complete enum definition from a GraphQL enum type definition.
  ///
  /// This method processes a GraphQL enum type definition node and creates
  /// a corresponding Dart enum definition with all enum values, including
  /// the automatic UNKNOWN value for forward compatibility.
  ///
  /// The generated enum includes:
  /// - All enum values from the GraphQL schema
  /// - Proper Dart naming conventions (converted from GraphQL naming)
  /// - An UNKNOWN value for handling server-side schema evolution
  /// - Support for deprecated enum values with appropriate annotations
  ///
  /// [node] The GraphQL enum type definition node to process
  /// [context] The generation context containing schema and configuration
  ///
  /// Returns an [EnumDefinition] representing the complete Dart enum
  ///
  /// Example:
  /// ```dart
  /// final enumDef = EnumGenerator.generateEnum(enumNode, context);
  /// // Generates: enum UserRole { ADMIN, USER, UNKNOWN }
  /// ```
  static EnumDefinition generateEnum(
    EnumTypeDefinitionNode node,
    Context context,
  ) {
    final enumName = EnumName(name: node.name.value);

    final nextContext = context.sameTypeWithNoPath(
      alias: enumName,
      ofUnion: Nullable<TypeDefinitionNode?>(null),
    );

    logFn(context, nextContext.align, '-> Enum');
    logFn(
      context,
      nextContext.align,
      '<- Generated enum ${enumName.namePrintable}.',
    );

    return EnumDefinition(
      name: enumName,
      values: generateEnumValues(node.values, context),
    );
  }

  /// Generate enum value definitions from GraphQL enum value definition nodes
  static List<EnumValueDefinition> generateEnumValues(
    List<EnumValueDefinitionNode> values,
    Context context,
  ) {
    final enumValues =
        values
            .map(
              (ev) => EnumValueDefinition(
                name: EnumValueName(name: ev.name.value),
                annotations: proceedDeprecated(ev.directives),
              ),
            )
            .toList()
          // Add the unknown enum value for handling unmapped values
          ..add(unknownEnumValue);

    return enumValues;
  }

  /// Handle enum-to-string conversion logic for class properties
  static ClassProperty handleEnumToStringConversion({
    required TypeNode fieldType,
    required TypeName dartTypeName,
    required ClassPropertyName name,
    required Map<String, String> jsonKeyAnnotation,
  }) {
    if (fieldType is ListTypeNode) {
      // For lists of enums, we need to modify the type to be List<String>
      // Use a simpler approach to avoid json_serializable errors
      // Don't use complex lambda expressions in JsonKey annotations

      // Override the dartTypeName to be List<String>
      return ClassProperty(
        type: ListOfTypeName(
          typeName: TypeName(name: 'String'),
          isNonNull: dartTypeName.isNonNull,
        ),
        name: name,
        // No custom fromJson/toJson functions, let json_serializable handle it
        annotations: name.namePrintable != name.name
            ? ['JsonKey(name: \'${name.name}\')']
            : [],
      );
    } else {
      // For single enums, we'll return a String
      // Create the JSON key annotation string with consistent ordering
      final orderedEntries = <String>[];
      if (jsonKeyAnnotation.containsKey('name')) {
        orderedEntries.add('name: ${jsonKeyAnnotation['name']}');
      }
      if (jsonKeyAnnotation.containsKey('unknownEnumValue')) {
        orderedEntries.add(
          'unknownEnumValue: ${jsonKeyAnnotation['unknownEnumValue']}',
        );
      }
      // Add any other entries
      for (final entry in jsonKeyAnnotation.entries) {
        if (entry.key != 'name' && entry.key != 'unknownEnumValue') {
          orderedEntries.add('${entry.key}: ${entry.value}');
        }
      }
      final jsonKey = orderedEntries.join(', ');

      return ClassProperty(
        type: TypeName(name: 'String', isNonNull: dartTypeName.isNonNull),
        name: name,
        annotations: jsonKeyAnnotation.isEmpty ? [] : ['JsonKey($jsonKey)'],
      );
    }
  }

  /// Add unknown enum value annotation for regular enum handling
  static void addUnknownEnumValueAnnotation({
    required TypeNode fieldType,
    required TypeName dartTypeName,
    required Map<String, String> jsonKeyAnnotation,
  }) {
    if (fieldType is ListTypeNode) {
      final innerDartTypeName = dartTypeName;
      if (innerDartTypeName is ListOfTypeName) {
        jsonKeyAnnotation['unknownEnumValue'] =
            '${innerDartTypeName.typeName.dartTypeSafe}.${unknownEnumValue.name.namePrintable}';
      }
    } else {
      jsonKeyAnnotation['unknownEnumValue'] =
          '${dartTypeName.dartTypeSafe}.${unknownEnumValue.name.namePrintable}';
    }
  }
}
