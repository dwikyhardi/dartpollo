import 'package:dartpollo/generator/data/data.dart';
import 'package:dartpollo/generator/data/nullable.dart';
import 'package:dartpollo/generator/enum_generator.dart';
import 'package:dartpollo/generator/ephemeral_data.dart';
import 'package:dartpollo/generator/graphql_helpers.dart' as gql;
import 'package:dartpollo/generator/helpers.dart';
import 'package:gql/ast.dart';

/// Generator for GraphQL class definitions
class ClassGenerator {
  const ClassGenerator._();

  /// Generate a class definition from a GraphQL type definition node
  static ClassDefinition generateClass({
    required TypeDefinitionNode node,
    required Context context,
    required List<ClassProperty> properties,
    List<FragmentName> mixins = const [],
    Map<String, Name> factoryPossibilities = const {},
    Name? extension,
    bool isInput = false,
  }) {
    final name = ClassName.fromPath(path: context.fullPathName());

    return ClassDefinition(
      name: name,
      properties: properties,
      mixins: mixins,
      extension: extension,
      factoryPossibilities: factoryPossibilities,
      isInput: isInput,
    );
  }

  /// Generate properties for a class from GraphQL field definitions
  static List<ClassProperty> generateProperties({
    required List<FieldDefinitionNode> fields,
    required Context context,
    required void Function(Context) onNewClassFound,
  }) {
    final properties = <ClassProperty>[];

    for (final field in fields) {
      final property = _generateProperty(
        field: field,
        context: context,
        onNewClassFound: onNewClassFound,
      );
      properties.add(property);
    }

    return properties;
  }

  /// Generate properties for input classes from GraphQL input field definitions
  static List<ClassProperty> generateInputProperties({
    required List<InputValueDefinitionNode> fields,
    required Context context,
    required void Function(Context) onNewClassFound,
  }) {
    final properties = <ClassProperty>[];

    for (final field in fields) {
      final property = _generateInputProperty(
        field: field,
        context: context,
        onNewClassFound: onNewClassFound,
      );
      properties.add(property);
    }

    return properties;
  }

  /// Generate a single property from a field definition
  static ClassProperty _generateProperty({
    required FieldDefinitionNode field,
    required Context context,
    required void Function(Context) onNewClassFound,
  }) {
    final fieldName = ClassPropertyName(name: field.name.value);

    return createClassProperty(
      fieldName: fieldName,
      fieldType: field.type,
      fieldDirectives: field.directives,
      context: context,
      onNewClassFound: onNewClassFound,
    );
  }

  /// Generate a single property from an input field definition
  static ClassProperty _generateInputProperty({
    required InputValueDefinitionNode field,
    required Context context,
    required void Function(Context) onNewClassFound,
  }) {
    final fieldName = ClassPropertyName(name: field.name.value);

    return createClassProperty(
      fieldName: fieldName,
      fieldType: field.type,
      fieldDirectives: field.directives,
      context: context,
      onNewClassFound: onNewClassFound,
    );
  }

  /// Core method to create a class property (extracted from main generator)
  static ClassProperty createClassProperty({
    required ClassPropertyName fieldName,
    ClassPropertyName? fieldAlias,
    required TypeNode fieldType,
    List<DirectiveNode>? fieldDirectives,
    required Context context,
    required void Function(Context) onNewClassFound,
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

    final nextType = gql.getTypeByName(
      context.typeDefinitionNodeVisitor,
      fieldType,
    );

    final aliasedContext = context.withAlias(
      nextFieldName: fieldName,
      nextClassName: ClassName(name: nextType.name.value),
      alias: fieldAlias,
    );

    final nextClassName = aliasedContext.fullPathName();

    final dartTypeName = gql.buildTypeName(
      fieldType,
      context.options,
      replaceLeafWith: ClassName.fromPath(path: nextClassName),
      typeDefinitionNodeVisitor: context.typeDefinitionNodeVisitor,
    );

    logFn(
      context,
      aliasedContext.align + 1,
      '${aliasedContext.path}[${aliasedContext.currentType!.name.value}][${aliasedContext.currentClassName} ${aliasedContext.currentFieldName}] ${fieldAlias == null ? '' : '($fieldAlias) '}-> ${dartTypeName.namePrintable}',
    );

    // Handle complex types that need class generation
    if (nextType is ObjectTypeDefinitionNode ||
        nextType is UnionTypeDefinitionNode ||
        nextType is InterfaceTypeDefinitionNode) {
      onNewClassFound(
        aliasedContext.next(
          nextType: nextType,
          nextFieldName: fieldName,
          nextClassName: ClassName(name: nextType.name.value),
          alias: fieldAlias,
          ofUnion: Nullable<TypeDefinitionNode?>(null),
        ),
      );
    }

    final name = fieldAlias ?? fieldName;

    // Handle annotations
    final jsonKeyAnnotation = <String, String>{};
    if (name.namePrintable != name.name) {
      jsonKeyAnnotation['name'] = '\'${name.name}\'';
    }

    // Handle custom scalars
    if (nextType is ScalarTypeDefinitionNode) {
      final scalar = gql.getSingleScalarMap(
        context.options,
        nextType.name.value,
      );

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
    // Handle enums
    else if (nextType is EnumTypeDefinitionNode) {
      if (markAsUsed) {
        context.usedEnums.add(EnumName(name: nextType.name.value));
      }

      if (context.schemaMap.convertEnumToString) {
        // If convertEnumToString is enabled, we'll return a String instead of an enum
        return EnumGenerator.handleEnumToStringConversion(
          fieldType: fieldType,
          dartTypeName: dartTypeName,
          name: name,
          jsonKeyAnnotation: jsonKeyAnnotation,
        );
      } else {
        // Original behavior when convertEnumToString is false
        EnumGenerator.addUnknownEnumValueAnnotation(
          fieldType: fieldType,
          dartTypeName: dartTypeName,
          jsonKeyAnnotation: jsonKeyAnnotation,
        );
      }
    }

    final annotations = <String>[];

    if (jsonKeyAnnotation.isNotEmpty) {
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
      annotations.add('JsonKey($jsonKey)');
    }
    annotations.addAll(proceedDeprecated(fieldDirectives));

    return ClassProperty(
      type: dartTypeName,
      name: name,
      annotations: annotations,
    );
  }

  /// Generate class annotations and metadata
  static List<String> generateClassAnnotations({
    required TypeDefinitionNode node,
    required Context context,
  }) => proceedDeprecated(node.directives);

  /// Validate property type resolution
  static void validatePropertyType({
    required TypeNode fieldType,
    required Context context,
  }) {
    try {
      gql.getTypeByName(context.typeDefinitionNodeVisitor, fieldType);
    } on Exception {
      throw Exception(
        'Failed to resolve type for field type: $fieldType. '
        'Make sure your schema is updated and the type exists.',
      );
    }
  }
}
