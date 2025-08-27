import 'package:dartpollo/generator/data/data.dart';
import 'package:dartpollo/generator/data/enum_value_definition.dart';
import 'package:dartpollo/generator/errors.dart';
import 'package:dartpollo/schema/schema_options.dart';
import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:dart_style/dart_style.dart';
import 'package:pub_semver/pub_semver.dart';

// ignore: implementation_imports
import 'package:gql_code_builder/src/ast.dart' as dart;
import 'package:recase/recase.dart';
import 'package:gql/ast.dart';

import '../generator/helpers.dart';

/// Generates a [Spec] of a single enum definition.
Spec enumDefinitionToSpec(EnumDefinition definition) =>
    CodeExpression(Code('''enum ${definition.name.namePrintable} {
  ${definition.values.removeDuplicatedBy((i) => i).map(_enumValueToSpec).join()}
}'''));

String _enumValueToSpec(EnumValueDefinition value) {
  final annotations = value.annotations
      .map((annotation) => '@$annotation')
      .followedBy(['@JsonValue(\'${value.name.name}\')']).join(' ');

  return '$annotations${value.name.namePrintable}, ';
}

String _fromJsonBody(ClassDefinition definition) {
  final buffer = StringBuffer();
  buffer.writeln(
      '''switch (json['${definition.typeNameField.name}'].toString()) {''');

  for (final p in definition.factoryPossibilities.entries) {
    buffer.writeln('''      case r'${p.key}':
        return ${p.value.namePrintable}.fromJson(json);''');
  }

  buffer.writeln('''      default:
    }
    return _\$${definition.name.namePrintable}FromJson(json);''');
  return buffer.toString();
}

String _toJsonBody(ClassDefinition definition) {
  final buffer = StringBuffer();
  final typeName = definition.typeNameField.namePrintable;
  buffer.writeln('''switch ($typeName) {''');

  for (final p in definition.factoryPossibilities.entries) {
    buffer.writeln('''      case r'${p.key}':
        return (this as ${p.value.namePrintable}).toJson();''');
  }

  buffer.writeln('''      default:
    }
    return _\$${definition.name.namePrintable}ToJson(this);''');
  return buffer.toString();
}

Method _propsMethod(Iterable<String> body) {
  return Method((m) => m
    ..type = MethodType.getter
    ..returns = refer('List<Object?>')
    ..annotations.add(CodeExpression(Code('override')))
    ..name = 'props'
    ..lambda = true
    ..body =
        Code('[${body.mergeDuplicatesBy((i) => i, (a, b) => a).join(', ')}]'));
}

/// Generates a [Spec] of a single class definition.
Spec classDefinitionToSpec(
    ClassDefinition definition,
    Iterable<FragmentClassDefinition> fragments,
    Iterable<ClassDefinition> classes) {
  final fromJson = definition.factoryPossibilities.isNotEmpty
      ? Constructor(
          (b) => b
            ..factory = true
            ..name = 'fromJson'
            ..requiredParameters.add(Parameter(
              (p) => p
                ..type = refer('Map<String, dynamic>')
                ..name = 'json',
            ))
            ..body = Code(_fromJsonBody(definition)),
        )
      : Constructor(
          (b) => b
            ..factory = true
            ..name = 'fromJson'
            ..lambda = true
            ..requiredParameters.add(Parameter(
              (p) => p
                ..type = refer('Map<String, dynamic>')
                ..name = 'json',
            ))
            ..body = Code('_\$${definition.name.namePrintable}FromJson(json)'),
        );

  final toJson = definition.factoryPossibilities.isNotEmpty
      ? Method(
          (m) => m
            ..name = 'toJson'
            ..annotations.add(CodeExpression(Code('override')))
            ..returns = refer('Map<String, dynamic>')
            ..body = Code(_toJsonBody(definition)),
        )
      : Method(
          (m) => m
            ..name = 'toJson'
            ..lambda = true
            ..annotations.add(CodeExpression(Code('override')))
            ..returns = refer('Map<String, dynamic>')
            ..body = Code('_\$${definition.name.namePrintable}ToJson(this)'),
        );

  final props = definition.mixins
      .map((i) {
        return fragments
            .firstWhere((f) {
              return f.name == i;
            }, orElse: () {
              throw MissingFragmentException(
                  i.namePrintable, definition.name.namePrintable);
            })
            .properties
            .map((p) => p.name.namePrintable);
      })
      .expand((i) => i)
      .followedBy(definition.properties.map((p) => p.name.namePrintable));

  final extendedClass =
      classes.firstWhereOrNull((e) => e.name == definition.extension);

  return Class(
    (b) => b
      ..annotations
          .add(CodeExpression(Code('JsonSerializable(explicitToJson: true)')))
      ..name = definition.name.namePrintable
      ..mixins.addAll([
        refer('EquatableMixin'),
        ...definition.mixins.map((i) => refer(i.namePrintable))
      ])
      ..methods.addAll([_propsMethod(props)])
      ..extend = definition.extension != null
          ? refer(definition.extension!.namePrintable)
          : refer('JsonSerializable')
      ..implements.addAll(definition.implementations.map(refer))
      ..constructors.add(Constructor((b) {
        if (definition.isInput) {
          b.optionalParameters.addAll(definition.properties
              .where(
                  (property) => !property.isOverride && !property.isResolveType)
              .map((property) => Parameter((p) {
                    p
                      ..name = property.name.namePrintable
                      ..named = true
                      ..toThis = true
                      ..required = property.type.isNonNull;
                  })));
        }
      }))
      // Always add fromJson constructor (either delegating or traditional)
      ..constructors.add(fromJson)
      // Only add toJson method when not using GraphQLDataClass
      ..methods.add(toJson)
      ..fields.addAll(definition.properties.map((p) {
        if (extendedClass != null &&
            extendedClass.properties.any((e) => e == p)) {
          // if class has the same prop as in extension
          p.annotations.add('override');
        }

        final field = Field((f) {
          f
            ..name = p.name.namePrintable
            ..late = p.type.isNonNull
            ..type = refer(p.type.namePrintable)
            ..annotations.addAll(
              p.annotations.map((e) => CodeExpression(Code(e))),
            );
        });
        return field;
      })),
  );
}

/// Generates a [Spec] of a single fragment class definition.
Spec fragmentClassDefinitionToSpec(FragmentClassDefinition definition) {
  final fields = definition.properties.map((p) {
    final lines = <String>[];
    lines.addAll(p.annotations.map((e) => '@$e'));
    lines.add(
        '${p.type.isNonNull ? 'late ' : ''}${p.type.namePrintable} ${p.name.namePrintable};');
    return lines.join('\n');
  });

  return CodeExpression(Code('''mixin ${definition.name.namePrintable} {
  ${fields.join('\n')}
}'''));
}

/// Generates a [Spec] of a mutation argument class.
Spec generateArgumentClassSpec(QueryDefinition definition) {
  final fromJsonCtor = Constructor(
    (b) => b
      ..factory = true
      ..name = 'fromJson'
      ..lambda = true
      ..requiredParameters.add(
        Parameter(
          (p) => p
            ..type = refer('Map<String, dynamic>')
            ..name = 'json',
        ),
      )
      // Keep annotation only when not using GraphQLDataClass for backward compatibility
      ..annotations.addAll([CodeExpression(Code('override'))])
      ..body = Code('_\$${definition.className}ArgumentsFromJson(json)'),
  );

  final classBuilder = ClassBuilder()
    ..annotations
        .add(CodeExpression(Code('JsonSerializable(explicitToJson: true)')))
    ..name = '${definition.className}Arguments'
    ..extend = refer('JsonSerializable')
    ..constructors.add(Constructor(
      (b) => b
        ..optionalParameters.addAll(
          definition.inputs.map(
            (input) => Parameter(
              (p) => p
                ..name = input.name.namePrintable
                ..named = true
                ..toThis = true
                ..required = input.type.isNonNull,
            ),
          ),
        ),
    ))
    ..constructors.add(fromJsonCtor)
    ..fields.addAll(
      definition.inputs.map(
        (p) => Field(
          (f) {
            f
              ..name = p.name.namePrintable
              ..late = p.type.isNonNull
              ..type = refer(p.type.namePrintable)
              ..annotations
                  .addAll(p.annotations.map((e) => CodeExpression(Code(e))));

            if (!p.type.isNonNull) {
              f.modifier = FieldModifier.final$;
            }
          },
        ),
      ),
    )
    ..mixins.add(refer('EquatableMixin'))
    ..methods.add(_propsMethod(
        definition.inputs.map((input) => input.name.namePrintable)))
    ..methods.add(Method(
      (m) => m
        ..name = 'toJson'
        ..lambda = true
        ..returns = refer('Map<String, dynamic>')
        ..annotations.add(CodeExpression(Code('override')))
        ..body = Code('_\$${definition.className}ArgumentsToJson(this)'),
    ));

  return classBuilder.build();
}

/// Generates TypeNode code for variable definitions.
String _generateTypeNodeCode(TypeNode type) {
  if (type is NamedTypeNode) {
    return "NamedTypeNode(name: NameNode(value: '${type.name.value}'), isNonNull: ${type.isNonNull})";
  }
  if (type is ListTypeNode) {
    return 'ListTypeNode(type: ${_generateTypeNodeCode(type.type)}, isNonNull: ${type.isNonNull})';
  }

  return "NamedTypeNode(name: NameNode(value: 'String'), isNonNull: false)"; // Fallback
}

/// Generates optimized DocumentNode code using template-based helpers.
///
/// This function converts a DocumentNode AST to optimized template-based code
/// that reduces verbosity by 40-50% through intelligent helper functions and caching.
String _generateOptimizedDocumentNode(DocumentNode document) {
  final buffer = StringBuffer();
  buffer.writeln('DocumentNodeHelpers.document([');

  for (final definition in document.definitions) {
    if (definition is FragmentDefinitionNode) {
      buffer.writeln('  DocumentNodeHelpers.fragmentDefinition(');
      buffer.writeln("    '${definition.name.value}',");
      buffer.writeln("    '${definition.typeCondition.on.name.value}',");

      if (definition.selectionSet.selections.isNotEmpty) {
        buffer.writeln('    selections: [');
        for (final selection in definition.selectionSet.selections) {
          _writeOptimizedSelection(buffer, selection, 6);
        }
        buffer.writeln('    ],');
      }

      buffer.writeln('  ),');
    } else if (definition is OperationDefinitionNode) {
      buffer.writeln('  DocumentNodeHelpers.operation(');
      buffer.writeln('    OperationType.${definition.type.name},');
      buffer.writeln("    '${definition.name?.value ?? ''}',");

      // Add variable definitions if present
      if (definition.variableDefinitions.isNotEmpty) {
        buffer.writeln('    variables: [');
        for (final varDef in definition.variableDefinitions) {
          buffer.writeln('      VariableDefinitionNode(');
          buffer.writeln(
              '        variable: DocumentNodeHelpers.variable(\'${varDef.variable.name.value}\'),');
          buffer
              .writeln('        type: ${_generateTypeNodeCode(varDef.type)},');
          // Add defaultValue parameter to prevent gql printer null assertion error
          if (varDef.defaultValue != null) {
            buffer.writeln(
                '        defaultValue: ${_generateDefaultValueCode(varDef.defaultValue!)},');
          } else {
            // Provide an empty DefaultValueNode to prevent null assertion crash
            buffer.writeln(
                '        defaultValue: DefaultValueNode(value: null),');
          }
          buffer.writeln('      ),');
        }
        buffer.writeln('    ],');
      }

      if (definition.selectionSet.selections.isNotEmpty) {
        buffer.writeln('    selections: [');
        for (final selection in definition.selectionSet.selections) {
          _writeOptimizedSelection(buffer, selection, 6);
        }
        buffer.writeln('    ],');
      }

      buffer.writeln('  ),');
    }
  }

  buffer.writeln('])');
  return buffer.toString();
}

/// Generates code for a DefaultValueNode.
String _generateDefaultValueCode(DefaultValueNode defaultValue) {
  if (defaultValue.value == null) {
    return 'DefaultValueNode(value: null)';
  }
  return 'DefaultValueNode(value: ${_valueNodeToAstCode(defaultValue.value!)})';
}

/// Converts a ValueNode into proper gql AST constructor code for defaults.
String _valueNodeToAstCode(ValueNode value) {
  if (value is StringValueNode) {
    final escaped = value.value.replaceAll("'", "\\'");
    return "StringValueNode(value: '$escaped')";
  }
  if (value is IntValueNode) {
    return "IntValueNode(value: '${value.value}')";
  }
  if (value is FloatValueNode) {
    return "FloatValueNode(value: '${value.value}')";
  }
  if (value is BooleanValueNode) {
    return 'BooleanValueNode(value: ${value.value})';
  }
  if (value is NullValueNode) {
    return 'NullValueNode()';
  }
  if (value is EnumValueNode) {
    return "EnumValueNode(name: NameNode(value: '${value.name.value}'))";
  }
  if (value is VariableNode) {
    return "VariableNode(name: NameNode(value: '${value.name.value}'))";
  }
  if (value is ListValueNode) {
    final items = value.values.map(_valueNodeToAstCode).join(', ');
    return 'ListValueNode(values: [$items])';
  }
  if (value is ObjectValueNode) {
    final fields = value.fields
        .map((f) =>
            "ObjectFieldNode(name: NameNode(value: '${f.name.value}'), value: ${_valueNodeToAstCode(f.value)})")
        .join(', ');
    return 'ObjectValueNode(fields: [$fields])';
  }
  // Fallback: emit a NullValueNode to keep types correct
  return 'NullValueNode()';
}

/// Writes an optimized selection (field, fragment, etc.) to the buffer.
void _writeOptimizedSelection(
    StringBuffer buffer, SelectionNode selection, int indent) {
  final indentStr = ' ' * indent;

  if (selection is FieldNode) {
    buffer.write(
        '${indentStr}DocumentNodeHelpers.field(\'${selection.name.value}\'');

    // Add alias if present
    if (selection.alias != null) {
      buffer.write(', alias: \'${selection.alias!.value}\'');
    }

    // Add arguments if present
    if (selection.arguments.isNotEmpty) {
      buffer.write(', args: {');
      for (int i = 0; i < selection.arguments.length; i++) {
        final arg = selection.arguments[i];
        if (i > 0) buffer.write(', ');
        buffer.write('\'${arg.name.value}\': ${_valueNodeToString(arg.value)}');
      }
      buffer.write('}');
    }

    // Add nested selections if present
    if (selection.selectionSet != null &&
        selection.selectionSet!.selections.isNotEmpty) {
      buffer.writeln(', selections: [');
      for (final nestedSelection in selection.selectionSet!.selections) {
        _writeOptimizedSelection(buffer, nestedSelection, indent + 2);
      }
      buffer.write('$indentStr]');
    }

    buffer.writeln('),');
  } else if (selection is FragmentSpreadNode) {
    buffer.writeln(
        '${indentStr}DocumentNodeHelpers.fragmentSpread(\'${selection.name.value}\'),');
  } else if (selection is InlineFragmentNode) {
    final typeName = selection.typeCondition?.on.name.value ?? '';
    buffer
        .write('${indentStr}DocumentNodeHelpers.inlineFragment(\'$typeName\'');

    // Add nested selections if present
    if (selection.selectionSet.selections.isNotEmpty) {
      buffer.writeln(', selections: [');
      for (final nestedSelection in selection.selectionSet.selections) {
        _writeOptimizedSelection(buffer, nestedSelection, indent + 2);
      }
      buffer.write('$indentStr]');
    }

    buffer.writeln('),');
  }
}

/// Converts a ValueNode to its string representation for code generation.
String _valueNodeToString(ValueNode value) {
  if (value is StringValueNode) {
    return "'${value.value}'";
  }
  if (value is IntValueNode) {
    return value.value;
  }
  if (value is FloatValueNode) {
    return value.value;
  }
  if (value is BooleanValueNode) {
    return value.value.toString();
  }
  if (value is NullValueNode) {
    return 'null';
  }
  if (value is VariableNode) {
    return "DocumentNodeHelpers.variable('${value.name.value}')";
  }
  if (value is ListValueNode) {
    final items = value.values.map(_valueNodeToString).join(', ');
    return '[$items]';
  }
  if (value is ObjectValueNode) {
    final fields = value.fields
        .map((f) => "'${f.name.value}': ${_valueNodeToString(f.value)}")
        .join(', ');
    return '{$fields}';
  }

  return 'null'; // Fallback for unsupported types
}

Spec generateQuerySpec(
  QueryDefinition definition, {
  bool optimizeDocumentNodes = false,
}) {
  return Block((b) => b
    ..statements.addAll([
      Code(
          "final ${definition.documentOperationName.constantCase} = '${definition.operationName}';"),
      Code('final ${definition.documentName.constantCase} = '),
      optimizeDocumentNodes
          ? Code(_generateOptimizedDocumentNode(definition.document))
          : dart.fromNode(definition.document).code,
      Code(';'),
    ]));
}

/// Generates a [Spec] of a query/mutation class.
Spec generateQueryClassSpec(QueryDefinition definition) {
  final typeDeclaration = definition.inputs.isEmpty
      ? '${definition.name.namePrintable}, JsonSerializable'
      : '${definition.name.namePrintable}, ${definition.className}Arguments';

  final name = '${definition.className}${definition.suffix}';

  final constructor = definition.inputs.isEmpty
      ? Constructor()
      : Constructor((b) => b
        ..optionalParameters.add(Parameter(
          (p) => p
            ..name = 'variables'
            ..toThis = true
            ..named = true
            ..required = true,
        )));

  final fields = [
    Field(
      (f) => f
        ..annotations.add(CodeExpression(Code('override')))
        ..modifier = FieldModifier.final$
        ..type = refer('DocumentNode', 'package:gql/ast.dart')
        ..name = 'document'
        ..assignment = Code(definition.documentName.constantCase),
    ),
    Field(
      (f) => f
        ..annotations.add(CodeExpression(Code('override')))
        ..modifier = FieldModifier.final$
        ..type = refer('String')
        ..name = 'operationName'
        ..assignment = Code(definition.documentOperationName.constantCase),
    ),
  ];

  if (definition.inputs.isNotEmpty) {
    fields.add(Field(
      (f) => f
        ..annotations.add(CodeExpression(Code('override')))
        ..modifier = FieldModifier.final$
        ..type = refer('${definition.className}Arguments')
        ..name = 'variables',
    ));
  }

  return Class(
    (b) => b
      ..name = name
      ..extend = refer('GraphQLQuery<$typeDeclaration>')
      ..constructors.add(constructor)
      ..fields.addAll(fields)
      ..methods.add(_propsMethod([
        'document',
        'operationName${definition.inputs.isNotEmpty ? ', variables' : ''}'
      ]))
      ..methods.add(Method(
        (m) => m
          ..annotations.add(CodeExpression(Code('override')))
          ..returns = refer(definition.name.namePrintable)
          ..name = 'parse'
          ..requiredParameters.add(Parameter(
            (p) => p
              ..type = refer('Map<String, dynamic>')
              ..name = 'json',
          ))
          ..lambda = true
          ..body = Code('${definition.name.namePrintable}.fromJson(json)'),
      )),
  );
}

/// Gathers and generates a [Spec] of a whole query/mutation and its
/// dependencies into a single library file.
Spec generateLibrarySpec(
    LibraryDefinition definition, GeneratorOptions options) {
  final importDirectives = [
    Directive.import('package:json_annotation/json_annotation.dart'),
    Directive.import('package:gql/ast.dart'),
  ];

  // Always include equatable import since we now always use EquatableMixin
  importDirectives.add(Directive.import('package:equatable/equatable.dart'));

  if (definition.queries.any((q) => q.generateHelpers)) {
    importDirectives.insertAll(
      0,
      [
        Directive.import('package:dartpollo/dartpollo.dart'),
      ],
    );
  }

  importDirectives.addAll(definition.customImports.map(Directive.import));

  final bodyDirectives = <Spec>[
    CodeExpression(Code('part \'${definition.basename}.g.dart\';')),
  ];

  final uniqueDefinitions = definition.queries
      .map((e) => e.classes.map((e) => e))
      .expand((e) => e)
      .fold<Map<String?, Definition>>(<String?, Definition>{}, (acc, element) {
    acc[element.name.name] = element;

    return acc;
  }).values;

  final fragments = uniqueDefinitions.whereType<FragmentClassDefinition>();
  final classes = uniqueDefinitions.whereType<ClassDefinition>();
  Iterable<EnumDefinition> enums =
      uniqueDefinitions.whereType<EnumDefinition>();

  if (definition.schemaMap?.convertEnumToString ?? false) {
    // Filter out enums that are not referenced in any class
    final enumNames = classes
        .expand((c) => c.properties)
        .map((p) => p.type.dartTypeSafe)
        .whereType<String>()
        .toSet();

    enums = enums.where((e) => enumNames.contains(e.name.namePrintable));
  }

  bodyDirectives.addAll(fragments.map(fragmentClassDefinitionToSpec));
  bodyDirectives.addAll(
      classes.map((cDef) => classDefinitionToSpec(cDef, fragments, classes)));
  bodyDirectives.addAll(enums.map(enumDefinitionToSpec));

  for (final queryDef in definition.queries) {
    if (queryDef.inputs.isNotEmpty &&
        (queryDef.generateHelpers || queryDef.generateQueries)) {
      bodyDirectives.add(generateArgumentClassSpec(queryDef));
    }

    if (queryDef.generateHelpers || queryDef.generateQueries) {
      bodyDirectives.add(generateQuerySpec(queryDef,
          optimizeDocumentNodes: options.optimizeDocumentNodes));
    }

    if (queryDef.generateHelpers) {
      bodyDirectives.add(generateQueryClassSpec(queryDef));
    }
  }

  return Library(
    (b) => b
      ..directives.addAll(importDirectives)
      ..body.addAll(bodyDirectives),
  );
}

/// Emit a [Spec] into a String, considering Dart formatting.
String specToString(Spec spec) {
  final emitter = DartEmitter(useNullSafetySyntax: true, orderDirectives: true);
  return DartFormatter(languageVersion: Version(3, 6, 0)).format(
    spec.accept(emitter).toString(),
  );
}

/// Generate Dart code typings from a query or mutation and its response from
/// a [QueryDefinition] into a buffer.
void writeLibraryDefinitionToBuffer(
  StringBuffer buffer,
  List<String> ignoreForFile,
  LibraryDefinition definition,
  GeneratorOptions options,
) {
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  if (ignoreForFile.isNotEmpty) {
    buffer.writeln(
      '// ignore_for_file: ${Set<String>.from(ignoreForFile).join(', ')}',
    );
  }
  buffer.write('\n');
  buffer.write(specToString(generateLibrarySpec(definition, options)));
}

/// Generate an empty file just exporting the library. This is used to avoid
/// a breaking change on file generation.
String writeLibraryForwarder(LibraryDefinition definition) =>
    '''// GENERATED CODE - DO NOT MODIFY BY HAND
export '${definition.basename}.dart';
''';
