import 'package:gql/ast.dart';
import 'data/class_definition.dart';
import 'data/class_property.dart';
import 'data/enum_definition.dart';
import 'data/nullable.dart';
import 'enum_generator.dart';
import 'ephemeral_data.dart';
import 'helpers.dart';
import 'graphql_helpers.dart' as gql;

/// Generator responsible for creating input object class definitions from
/// GraphQL input types. Handles input validation, type relationships, and annotations.
class InputGenerator {
  /// Generates an input class definition from a GraphQL input object type definition node
  static ClassDefinition generateInputClass(
    InputObjectTypeDefinitionNode node,
    Context context,
  ) {
    final name = ClassName(name: node.name.value);
    final nextContext = context.sameTypeWithNoPath(
      alias: name,
      ofUnion: Nullable<TypeDefinitionNode?>(null),
    );

    logFn(context, nextContext.align, '-> Input class');
    logFn(context, nextContext.align,
        '┌ ${nextContext.path}[${node.name.value}]');

    final properties = generateInputProperties(node.fields, nextContext);

    logFn(context, nextContext.align,
        '└ ${nextContext.path}[${node.name.value}]');
    logFn(context, nextContext.align,
        '<- Generated input class ${name.namePrintable}.');

    return ClassDefinition(
      isInput: true,
      name: name,
      properties: properties,
    );
  }

  /// Generates input class properties from GraphQL input value definition nodes
  static List<ClassProperty> generateInputProperties(
    List<InputValueDefinitionNode> fields,
    Context context,
  ) {
    return fields.map((field) {
      return createInputClassProperty(
        fieldName: ClassPropertyName(name: field.name.value),
        fieldType: field.type,
        fieldDirectives: field.directives,
        context: context,
      );
    }).toList();
  }

  /// Creates a class property for input objects with proper type handling and annotations
  static ClassProperty createInputClassProperty({
    required ClassPropertyName fieldName,
    required TypeNode fieldType,
    required List<DirectiveNode> fieldDirectives,
    required Context context,
  }) {
    final nextType =
        gql.getTypeByName(context.typeDefinitionNodeVisitor, fieldType);

    final dartTypeName = gql.buildTypeName(
      fieldType,
      context.options,
      dartType: true,
      replaceLeafWith: ClassName(name: nextType.name.value),
      typeDefinitionNodeVisitor: context.typeDefinitionNodeVisitor,
    );

    final currentTypeName = context.currentType?.name.value ?? 'Unknown';
    logFn(context, context.align + 1,
        '${context.path}[$currentTypeName][${context.currentClassName} ${fieldName.name}] -> ${dartTypeName.namePrintable}');

    // Handle annotations for input properties
    final annotations = <String>[];
    final jsonKeyAnnotation = <String, String>{};

    // Handle input object type relationships
    if (nextType is InputObjectTypeDefinitionNode) {
      context.usedInputObjects.add(ClassName(name: nextType.name.value));
    }

    // Handle enum types
    if (nextType is EnumTypeDefinitionNode) {
      context.usedEnums.add(EnumName(name: nextType.name.value));

      if (context.schemaMap.convertEnumToString) {
        // If convertEnumToString is enabled, we'll return a String instead of an enum
        return EnumGenerator.handleEnumToStringConversion(
          fieldType: fieldType,
          dartTypeName: dartTypeName,
          name: fieldName,
          jsonKeyAnnotation: jsonKeyAnnotation,
        );
      } else {
        // Add unknown enum value annotation for enum handling
        EnumGenerator.addUnknownEnumValueAnnotation(
          fieldType: fieldType,
          dartTypeName: dartTypeName,
          jsonKeyAnnotation: jsonKeyAnnotation,
        );
      }
    }

    // Add JsonKey annotation if field name needs transformation
    if (fieldName.namePrintable != fieldName.name) {
      jsonKeyAnnotation['name'] = '\'${fieldName.name}\'';
    }

    // Handle custom scalars
    if (nextType is ScalarTypeDefinitionNode) {
      final scalar =
          gql.getSingleScalarMap(context.options, nextType.name.value);

      if (scalar?.customParserImport != null &&
          nextType.name.value == scalar?.graphQLType) {
        final graphqlTypeName = gql.buildTypeName(
          fieldType,
          context.options,
          dartType: false,
          typeDefinitionNodeVisitor: context.typeDefinitionNodeVisitor,
        );

        jsonKeyAnnotation['fromJson'] =
            'fromGraphQL${graphqlTypeName.parserSafe}ToDart${dartTypeName.parserSafe}';
        jsonKeyAnnotation['toJson'] =
            'fromDart${dartTypeName.parserSafe}ToGraphQL${graphqlTypeName.parserSafe}';
      }
    }

    if (jsonKeyAnnotation.isNotEmpty) {
      // Create the JSON key annotation string with consistent ordering
      final orderedEntries = <String>[];
      if (jsonKeyAnnotation.containsKey('name')) {
        orderedEntries.add('name: ${jsonKeyAnnotation['name']}');
      }
      if (jsonKeyAnnotation.containsKey('unknownEnumValue')) {
        orderedEntries
            .add('unknownEnumValue: ${jsonKeyAnnotation['unknownEnumValue']}');
      }
      // Add any other entries
      for (final entry in jsonKeyAnnotation.entries) {
        if (entry.key != 'name' && entry.key != 'unknownEnumValue') {
          orderedEntries.add('${entry.key}: ${entry.value}');
        }
      }
      final jsonKey = orderedEntries.join(', ');
      annotations.add('JsonKey($jsonKey)');
    }

    // Add deprecated annotations if present
    annotations.addAll(proceedDeprecated(fieldDirectives));

    return ClassProperty(
      type: dartTypeName,
      name: fieldName,
      annotations: annotations,
    );
  }
}
