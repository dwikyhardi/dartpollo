import 'package:dart_style/dart_style.dart';
import 'package:dartpollo_annotation/schema/schema_options.dart';
import 'package:dartpollo_generator/generator/data/data.dart';
import 'package:dartpollo_generator/generator/data/enum_value_definition.dart';
import 'package:dartpollo_generator/generator/print_helpers.dart';
import 'package:gql/language.dart';
import 'package:test/test.dart';

/// Normalizes Dart code by formatting it with dart_style.
/// This makes tests resilient to whitespace/formatting differences
/// from code_builder's DartEmitter output.
String _normalizeCode(String code) {
  try {
    return DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format(code);
  } on FormatterException catch (_) {
    // If formatting fails (e.g. partial code), normalize whitespace manually
    return code
        .split('\n')
        .map((l) => l.trimRight())
        .join('\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}

/// Custom matcher that compares code after normalizing formatting.
Matcher equalsFormattedCode(String expected) => _FormattedCodeMatcher(expected);

class _FormattedCodeMatcher extends Matcher {
  _FormattedCodeMatcher(this.expected);

  final String expected;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! String) return false;
    return _normalizeCode(item) == _normalizeCode(expected);
  }

  @override
  Description describe(Description description) =>
      description.add('code that formats to:\n${_normalizeCode(expected)}');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is String) {
      return mismatchDescription.add(
        'formatted to:\n${_normalizeCode(item)}',
      );
    }
    return mismatchDescription.add('was not a String');
  }
}

void main() {
  group('On printCustomEnum', () {
    test('It will throw if name is empty.', () {
      expect(
        () => enumDefinitionToSpec(
          EnumDefinition(
            name: EnumName(name: ''),
            values: const [],
          ),
        ),
        throwsA(const TypeMatcher<AssertionError>()),
      );
    });

    test('It will throw if values is empty.', () {
      // expect(
      //     () => enumDefinitionToSpec(
      //         EnumDefinition(name: EnumName(name: 'Name'), values: null)),
      //     throwsA(TypeMatcher<AssertionError>()));
      expect(
        () => enumDefinitionToSpec(
          EnumDefinition(
            name: EnumName(name: 'Name'),
            values: const [],
          ),
        ),
        throwsA(const TypeMatcher<AssertionError>()),
      );
    });

    test('It will generate an Enum declaration.', () {
      final definition = EnumDefinition(
        name: EnumName(name: 'Name'),
        values: [
          EnumValueDefinition(
            name: EnumValueName(name: 'Option'),
          ),
          EnumValueDefinition(
            name: EnumValueName(name: 'anotherOption'),
          ),
          EnumValueDefinition(
            name: EnumValueName(name: 'third_option'),
          ),
          EnumValueDefinition(
            name: EnumValueName(name: 'FORTH_OPTION'),
          ),
        ],
      );

      final str = specToString(enumDefinitionToSpec(definition));

      expect(
        str,
        equalsFormattedCode('''enum Name {
  @JsonValue('Option')
  option,
  @JsonValue('anotherOption')
  anotherOption,
  @JsonValue('third_option')
  thirdOption,
  @JsonValue('FORTH_OPTION')
  forthOption,
}
'''),
      );
    });

    test('It will ignore duplicate options.', () {
      final definition = EnumDefinition(
        name: EnumName(name: 'Name'),
        values: [
          EnumValueDefinition(
            name: EnumValueName(name: 'Option'),
          ),
          EnumValueDefinition(
            name: EnumValueName(name: 'AnotherOption'),
          ),
          EnumValueDefinition(
            name: EnumValueName(name: 'Option'),
          ),
          EnumValueDefinition(
            name: EnumValueName(name: 'AnotherOption'),
          ),
        ],
      );

      final str = specToString(enumDefinitionToSpec(definition));

      expect(
        str,
        equalsFormattedCode('''enum Name {
  @JsonValue('Option')
  option,
  @JsonValue('AnotherOption')
  anotherOption,
}
'''),
      );
    });
  });

  group('On printCustomFragmentClass', () {
    test('It will throw if name is null or empty.', () {
      expect(
        () => fragmentClassDefinitionToSpec(
          FragmentClassDefinition(
            name: FragmentName(name: ''),
            properties: const [],
          ),
        ),
        throwsA(const TypeMatcher<AssertionError>()),
      );
    });

    test('It will generate an Mixins declarations.', () {
      final definition = FragmentClassDefinition(
        name: FragmentName(name: 'FragmentMixin'),
        properties: [
          ClassProperty(
            type: TypeName(name: 'Type'),
            name: const ClassPropertyName(name: 'name'),
          ),
          ClassProperty(
            type: TypeName(name: 'Type'),
            name: const ClassPropertyName(name: 'name'),
            annotations: const ['override'],
          ),
          ClassProperty(
            type: TypeName(name: 'Type'),
            name: const ClassPropertyName(name: 'name'),
            annotations: const ['Test'],
          ),
        ],
      );

      final str = specToString(fragmentClassDefinitionToSpec(definition));

      expect(
        str,
        equalsFormattedCode('''mixin FragmentMixin {
  Type? name;
  @override
  Type? name;
  @Test
  Type? name;
}
'''),
      );
    });
  });

  group('On printCustomClass', () {
    test('It will throw if name is empty.', () {
      // expect(
      //     () => classDefinitionToSpec(
      //         ClassDefinition(name: null, properties: []), [], []),
      //     throwsA(TypeMatcher<AssertionError>()));
      expect(
        () => classDefinitionToSpec(
          ClassDefinition(
            name: ClassName(name: ''),
          ),
          [],
          [],
        ),
        throwsA(const TypeMatcher<AssertionError>()),
      );
    });

    test('It can generate a class without properties.', () {
      final definition = ClassDefinition(
        name: ClassName(name: 'AClass'),
      );

      final str = specToString(classDefinitionToSpec(definition, [], []));

      expect(
        str,
        equalsFormattedCode('''@JsonSerializable(explicitToJson: true)
class AClass extends JsonSerializable with EquatableMixin {
  AClass();

  factory AClass.fromJson(Map<String, dynamic> json) => _\$AClassFromJson(json);

  @override
  List<Object?> get props => [];

  @override
  Map<String, dynamic> toJson() => _\$AClassToJson(this);
}
'''),
      );
    });

    test('"Mixins" will be included to class.', () {
      final definition = ClassDefinition(
        name: ClassName(name: 'AClass'),
        extension: ClassName(name: 'AnotherClass'),
      );

      final str = specToString(classDefinitionToSpec(definition, [], []));

      expect(
        str,
        equalsFormattedCode('''@JsonSerializable(explicitToJson: true)
class AClass extends AnotherClass with EquatableMixin {
  AClass();

  factory AClass.fromJson(Map<String, dynamic> json) => _\$AClassFromJson(json);

  @override
  List<Object?> get props => [];

  @override
  Map<String, dynamic> toJson() => _\$AClassToJson(this);
}
'''),
      );
    });

    test(
      'factoryPossibilities and typeNameField are used to generated a branch factory.',
      () {
        final definition = ClassDefinition(
          name: ClassName(name: 'AClass'),
          factoryPossibilities: {
            'ASubClass': ClassName(name: 'ASubClass'),
            'BSubClass': ClassName(name: 'BSubClass'),
          },
          typeNameField: const ClassPropertyName(name: '__typename'),
        );

        final str = specToString(classDefinitionToSpec(definition, [], []));

        expect(
          str,
          equalsFormattedCode(r'''@JsonSerializable(explicitToJson: true)
class AClass extends JsonSerializable with EquatableMixin {
  AClass();

  factory AClass.fromJson(Map<String, dynamic> json) {
    switch (json['__typename'].toString()) {
      case r'ASubClass':
        return ASubClass.fromJson(json);
      case r'BSubClass':
        return BSubClass.fromJson(json);
      default:
    }
    return _$AClassFromJson(json);
  }

  @override
  List<Object?> get props => [];

  @override
  Map<String, dynamic> toJson() {
    switch ($$typename) {
      case r'ASubClass':
        return (this as ASubClass).toJson();
      case r'BSubClass':
        return (this as BSubClass).toJson();
      default:
    }
    return _$AClassToJson(this);
  }
}
'''),
        );
      },
    );

    test('It can have properties.', () {
      final definition = ClassDefinition(
        name: ClassName(name: 'AClass'),
        properties: [
          ClassProperty(
            type: TypeName(name: 'Type'),
            name: const ClassPropertyName(name: 'name'),
          ),
          ClassProperty(
            type: TypeName(name: 'AnotherType'),
            name: const ClassPropertyName(name: 'anotherName'),
          ),
        ],
      );

      final str = specToString(classDefinitionToSpec(definition, [], []));

      expect(
        str,
        equalsFormattedCode('''@JsonSerializable(explicitToJson: true)
class AClass extends JsonSerializable with EquatableMixin {
  AClass();

  factory AClass.fromJson(Map<String, dynamic> json) => _\$AClassFromJson(json);

  Type? name;

  AnotherType? anotherName;

  @override
  List<Object?> get props => [name, anotherName];

  @override
  Map<String, dynamic> toJson() => _\$AClassToJson(this);
}
'''),
      );
    });

    test(
      'Its properties can be an override or have a custom annotation, or both.',
      () {
        final definition = ClassDefinition(
          name: ClassName(name: 'AClass'),
          properties: [
            ClassProperty(
              type: TypeName(name: 'Type'),
              name: const ClassPropertyName(name: 'nameA'),
            ),
            ClassProperty(
              type: TypeName(name: 'AnnotatedProperty'),
              name: const ClassPropertyName(name: 'nameB'),
              annotations: const ['Hey()'],
            ),
            ClassProperty(
              type: TypeName(name: 'OverridenProperty'),
              name: const ClassPropertyName(name: 'nameC'),
              annotations: const ['override'],
            ),
            ClassProperty(
              type: TypeName(name: 'AllAtOnce'),
              name: const ClassPropertyName(name: 'nameD'),
              annotations: const ['override', 'Ho()'],
            ),
          ],
        );

        final str = specToString(classDefinitionToSpec(definition, [], []));

        expect(
          str,
          equalsFormattedCode('''@JsonSerializable(explicitToJson: true)
class AClass extends JsonSerializable with EquatableMixin {
  AClass();

  factory AClass.fromJson(Map<String, dynamic> json) => _\$AClassFromJson(json);

  Type? nameA;

  @Hey()
  AnnotatedProperty? nameB;

  @override
  OverridenProperty? nameC;

  @override
  @Ho()
  AllAtOnce? nameD;

  @override
  List<Object?> get props => [nameA, nameB, nameC, nameD];

  @override
  Map<String, dynamic> toJson() => _\$AClassToJson(this);
}
'''),
        );
      },
    );

    test(
      'Mixins can be included and its properties will be considered on props getter',
      () {
        final definition = ClassDefinition(
          name: ClassName(name: 'AClass'),
          mixins: [FragmentName(name: 'FragmentMixin')],
        );

        final str = specToString(
          classDefinitionToSpec(definition, [
            FragmentClassDefinition(
              name: FragmentName(name: 'FragmentMixin'),
              properties: [
                ClassProperty(
                  type: TypeName(name: 'Type'),
                  name: const ClassPropertyName(name: 'name'),
                ),
              ],
            ),
          ], []),
        );

        expect(
          str,
          equalsFormattedCode('''@JsonSerializable(explicitToJson: true)
class AClass extends JsonSerializable with EquatableMixin, FragmentMixin {
  AClass();

  factory AClass.fromJson(Map<String, dynamic> json) => _\$AClassFromJson(json);

  @override
  List<Object?> get props => [name];

  @override
  Map<String, dynamic> toJson() => _\$AClassToJson(this);
}
'''),
        );
      },
    );

    test(
      'It can be an input object (and have a named parameter constructor).',
      () {
        final definition = ClassDefinition(
          name: ClassName(name: 'AClass'),
          properties: [
            ClassProperty(
              type: TypeName(name: 'Type'),
              name: const ClassPropertyName(name: 'name'),
            ),
            ClassProperty(
              type: TypeName(name: 'AnotherType', isNonNull: true),
              name: const ClassPropertyName(name: 'anotherName'),
            ),
          ],
          isInput: true,
        );

        final str = specToString(classDefinitionToSpec(definition, [], []));

        expect(
          str,
          equalsFormattedCode('''@JsonSerializable(explicitToJson: true)
class AClass extends JsonSerializable with EquatableMixin {
  AClass({
    this.name,
    required this.anotherName,
  });

  factory AClass.fromJson(Map<String, dynamic> json) => _\$AClassFromJson(json);

  Type? name;

  late AnotherType anotherName;

  @override
  List<Object?> get props => [name, anotherName];

  @override
  Map<String, dynamic> toJson() => _\$AClassToJson(this);
}
'''),
        );
      },
    );
  });

  group('On generateQueryClassSpec', () {
    test('It will throw if basename is null or empty.', () {
      expect(
        () => generateLibrarySpec(
          LibraryDefinition(basename: ''),
          GeneratorOptions(),
        ),
        throwsA(const TypeMatcher<AssertionError>()),
      );
    });

    test('It will throw if query name/type is null or empty.', () {
      expect(
        () => generateQueryClassSpec(
          QueryDefinition(
            name: QueryName(name: ''),
            operationName: 'Type',
            document: parseString('query test_query {}'),
          ),
        ),
        throwsA(const TypeMatcher<AssertionError>()),
      );
      expect(
        () => generateQueryClassSpec(
          QueryDefinition(
            name: QueryName(name: 'Type'),
            operationName: '',
            document: parseString('query test_query {}'),
          ),
        ),
        throwsA(
          const TypeMatcher<AssertionError>(),
        ),
      );
      expect(
        () => generateQueryClassSpec(
          QueryDefinition(
            name: QueryName(name: ''),
            operationName: 'test_query',
            document: parseString('query test_query {}'),
          ),
        ),
        throwsA(
          const TypeMatcher<AssertionError>(),
        ),
      );
    });

    test('It should generated an empty file by default.', () {
      final buffer = StringBuffer();
      final definition = LibraryDefinition(basename: r'test_query.graphql');
      final ignoreForFile = <String>[];
      writeLibraryDefinitionToBuffer(
        buffer,
        ignoreForFile,
        definition,
        GeneratorOptions(),
      );

      expect(
        buffer.toString(),
        equalsFormattedCode('''// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:equatable/equatable.dart';
import 'package:gql/ast.dart';
import 'package:json_annotation/json_annotation.dart';
part 'test_query.graphql.g.dart';
'''),
      );
    });

    test('When there are custom imports, they are included.', () {
      final buffer = StringBuffer();
      final definition = LibraryDefinition(
        basename: r'test_query.graphql',
        customImports: const ['some_file.dart'],
      );
      final ignoreForFile = <String>[];

      writeLibraryDefinitionToBuffer(
        buffer,
        ignoreForFile,
        definition,
        GeneratorOptions(),
      );

      expect(
        buffer.toString(),
        equalsFormattedCode('''// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:equatable/equatable.dart';
import 'package:gql/ast.dart';
import 'package:json_annotation/json_annotation.dart';

import 'some_file.dart';
part 'test_query.graphql.g.dart';
'''),
      );
    });

    test('When generateHelpers is true, an execute fn is generated.', () {
      final buffer = StringBuffer();
      final definition = LibraryDefinition(
        basename: r'test_query.graphql',
        queries: [
          QueryDefinition(
            name: QueryName(name: 'test_query'),
            operationName: 'test_query',
            document: parseString('query test_query {}'),
            generateHelpers: true,
          ),
        ],
      );
      final ignoreForFile = <String>[];

      writeLibraryDefinitionToBuffer(
        buffer,
        ignoreForFile,
        definition,
        GeneratorOptions(),
      );

      expect(
        buffer.toString(),
        equalsFormattedCode('''// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:dartpollo/dartpollo.dart';
import 'package:equatable/equatable.dart';
import 'package:gql/ast.dart';
import 'package:json_annotation/json_annotation.dart';
part 'test_query.graphql.g.dart';

final TEST_QUERY_QUERY_DOCUMENT_OPERATION_NAME = 'test_query';
final TEST_QUERY_QUERY_DOCUMENT = DocumentNode(definitions: [
  OperationDefinitionNode(
    type: OperationType.query,
    name: NameNode(value: 'test_query'),
    variableDefinitions: [],
    directives: [],
    selectionSet: SelectionSetNode(selections: []),
  )
]);

class TestQueryQuery extends GraphQLQuery<TestQuery, JsonSerializable> {
  TestQueryQuery();

  @override
  final DocumentNode document = TEST_QUERY_QUERY_DOCUMENT;

  @override
  final String operationName = TEST_QUERY_QUERY_DOCUMENT_OPERATION_NAME;

  @override
  List<Object?> get props => [document, operationName];

  @override
  TestQuery parse(Map<String, dynamic> json) => TestQuery.fromJson(json);
}
'''),
      );
    });

    test(
      'When generateHelpers is false and generateQueries is true, an execute fn is generated.',
      () {
        final buffer = StringBuffer();
        final definition = LibraryDefinition(
          basename: r'test_query.graphql',
          queries: [
            QueryDefinition(
              name: QueryName(name: 'test_query'),
              operationName: 'test_query',
              document: parseString('query test_query {}'),
              generateQueries: true,
            ),
          ],
        );
        final ignoreForFile = <String>[];

        writeLibraryDefinitionToBuffer(
          buffer,
          ignoreForFile,
          definition,
          GeneratorOptions(),
        );

        expect(
          buffer.toString(),
          equalsFormattedCode('''// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:equatable/equatable.dart';
import 'package:gql/ast.dart';
import 'package:json_annotation/json_annotation.dart';
part 'test_query.graphql.g.dart';

final TEST_QUERY_QUERY_DOCUMENT_OPERATION_NAME = 'test_query';
final TEST_QUERY_QUERY_DOCUMENT = DocumentNode(definitions: [
  OperationDefinitionNode(
    type: OperationType.query,
    name: NameNode(value: 'test_query'),
    variableDefinitions: [],
    directives: [],
    selectionSet: SelectionSetNode(selections: []),
  )
]);
'''),
        );
      },
    );

    test('The generated execute fn could have input.', () {
      final buffer = StringBuffer();
      final definition = LibraryDefinition(
        basename: r'test_query.graphql',
        queries: [
          QueryDefinition(
            name: QueryName(name: 'test_query'),
            operationName: 'test_query',
            document: parseString('query test_query {}'),
            generateHelpers: true,
            inputs: [
              QueryInput(
                type: TypeName(name: 'Type'),
                name: const QueryInputName(name: 'name'),
              ),
            ],
          ),
        ],
      );
      final ignoreForFile = <String>[];

      writeLibraryDefinitionToBuffer(
        buffer,
        ignoreForFile,
        definition,
        GeneratorOptions(),
      );

      expect(
        buffer.toString(),
        equalsFormattedCode(r'''// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:dartpollo/dartpollo.dart';
import 'package:equatable/equatable.dart';
import 'package:gql/ast.dart';
import 'package:json_annotation/json_annotation.dart';
part 'test_query.graphql.g.dart';

@JsonSerializable(explicitToJson: true)
class TestQueryArguments extends JsonSerializable with EquatableMixin {
  TestQueryArguments({this.name});

  @override
  factory TestQueryArguments.fromJson(Map<String, dynamic> json) =>
      _$TestQueryArgumentsFromJson(json);

  final Type? name;

  @override
  List<Object?> get props => [name];

  @override
  Map<String, dynamic> toJson() => _$TestQueryArgumentsToJson(this);
}

final TEST_QUERY_QUERY_DOCUMENT_OPERATION_NAME = 'test_query';
final TEST_QUERY_QUERY_DOCUMENT = DocumentNode(definitions: [
  OperationDefinitionNode(
    type: OperationType.query,
    name: NameNode(value: 'test_query'),
    variableDefinitions: [],
    directives: [],
    selectionSet: SelectionSetNode(selections: []),
  )
]);

class TestQueryQuery extends GraphQLQuery<TestQuery, TestQueryArguments> {
  TestQueryQuery({required this.variables});

  @override
  final DocumentNode document = TEST_QUERY_QUERY_DOCUMENT;

  @override
  final String operationName = TEST_QUERY_QUERY_DOCUMENT_OPERATION_NAME;

  @override
  final TestQueryArguments variables;

  @override
  List<Object?> get props => [document, operationName, variables];

  @override
  TestQuery parse(Map<String, dynamic> json) => TestQuery.fromJson(json);
}
'''),
      );
    });

    test('Will generate an Arguments class', () {
      final definition = QueryDefinition(
        name: QueryName(name: 'test_query'),
        operationName: 'test_query',
        document: parseString('query test_query {}'),
        generateHelpers: true,
        inputs: [
          QueryInput(
            type: TypeName(name: 'Type'),
            name: const QueryInputName(name: 'name'),
          ),
        ],
      );

      final str = specToString(generateArgumentClassSpec(definition));

      expect(
        str,
        equalsFormattedCode('''@JsonSerializable(explicitToJson: true)
class TestQueryArguments extends JsonSerializable with EquatableMixin {
  TestQueryArguments({this.name});

  @override
  factory TestQueryArguments.fromJson(Map<String, dynamic> json) =>
      _\$TestQueryArgumentsFromJson(json);

  final Type? name;

  @override
  List<Object?> get props => [name];

  @override
  Map<String, dynamic> toJson() => _\$TestQueryArgumentsToJson(this);
}
'''),
      );
    });

    test('Will generate a Query Class', () {
      final definition = QueryDefinition(
        name: QueryName(name: 'test_query'),
        operationName: 'test_query',
        document: parseString('query test_query {}'),
        generateHelpers: true,
        inputs: [
          QueryInput(
            type: TypeName(name: 'Type'),
            name: const QueryInputName(name: 'name'),
          ),
        ],
      );

      final str =
          specToString(generateQuerySpec(definition)) +
          specToString(generateQueryClassSpec(definition));

      expect(
        str,
        equalsFormattedCode(
          r'''final TEST_QUERY_QUERY_DOCUMENT_OPERATION_NAME = 'test_query';
final TEST_QUERY_QUERY_DOCUMENT = DocumentNode(definitions: [
  OperationDefinitionNode(
    type: OperationType.query,
    name: NameNode(value: 'test_query'),
    variableDefinitions: [],
    directives: [],
    selectionSet: SelectionSetNode(selections: []),
  )
]);
class TestQueryQuery extends GraphQLQuery<TestQuery, TestQueryArguments> {
  TestQueryQuery({required this.variables});

  @override
  final DocumentNode document = TEST_QUERY_QUERY_DOCUMENT;

  @override
  final String operationName = TEST_QUERY_QUERY_DOCUMENT_OPERATION_NAME;

  @override
  final TestQueryArguments variables;

  @override
  List<Object?> get props => [document, operationName, variables];

  @override
  TestQuery parse(Map<String, dynamic> json) => TestQuery.fromJson(json);
}
''',
        ),
      );
    });

    test('It will accept and write class/enum definitions.', () {
      final buffer = StringBuffer();
      final definition = LibraryDefinition(
        basename: r'test_query.graphql',
        queries: [
          QueryDefinition(
            name: QueryName(name: 'test_query'),
            operationName: 'test_query',
            document: parseString('query test_query {}'),
            classes: [
              EnumDefinition(
                name: EnumName(name: 'SomeEnum'),
                values: [
                  EnumValueDefinition(
                    name: EnumValueName(name: 'Value'),
                  ),
                ],
              ),
              ClassDefinition(
                name: ClassName(name: 'AClass'),
              ),
            ],
          ),
        ],
      );
      final ignoreForFile = <String>[];

      writeLibraryDefinitionToBuffer(
        buffer,
        ignoreForFile,
        definition,
        GeneratorOptions(),
      );

      expect(
        buffer.toString(),
        equalsFormattedCode('''// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:equatable/equatable.dart';
import 'package:gql/ast.dart';
import 'package:json_annotation/json_annotation.dart';
part 'test_query.graphql.g.dart';

@JsonSerializable(explicitToJson: true)
class AClass extends JsonSerializable with EquatableMixin {
  AClass();

  factory AClass.fromJson(Map<String, dynamic> json) => _\$AClassFromJson(json);

  @override
  List<Object?> get props => [];

  @override
  Map<String, dynamic> toJson() => _\$AClassToJson(this);
}

enum SomeEnum {
  @JsonValue('Value')
  value,
}
'''),
      );
    });
  });

  test('Should not add ignore_for_file when ignoreForFile is null', () {
    final buffer = StringBuffer();
    final definition = LibraryDefinition(basename: r'test_query.graphql');
    final ignoreForFile = <String>[];

    writeLibraryDefinitionToBuffer(
      buffer,
      ignoreForFile,
      definition,
      GeneratorOptions(),
    );

    expect(
      buffer.toString(),
      equalsFormattedCode('''// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:equatable/equatable.dart';
import 'package:gql/ast.dart';
import 'package:json_annotation/json_annotation.dart';
part 'test_query.graphql.g.dart';
'''),
    );
  });

  test('Should not add ignore_for_file when ignoreForFile is empty', () {
    final buffer = StringBuffer();
    final definition = LibraryDefinition(basename: r'test_query.graphql');
    final ignoreForFile = <String>[];

    writeLibraryDefinitionToBuffer(
      buffer,
      ignoreForFile,
      definition,
      GeneratorOptions(),
    );

    expect(
      buffer.toString(),
      equalsFormattedCode('''// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:equatable/equatable.dart';
import 'package:gql/ast.dart';
import 'package:json_annotation/json_annotation.dart';
part 'test_query.graphql.g.dart';
'''),
    );
  });

  test(
    'Should add // ignore_for_file: ... when ignoreForFile is not empty',
    () {
      final buffer = StringBuffer();
      final definition = LibraryDefinition(basename: r'test_query.graphql');
      final ignoreForFile = <String>['my_rule_1', 'my_rule_2'];

      writeLibraryDefinitionToBuffer(
        buffer,
        ignoreForFile,
        definition,
        GeneratorOptions(),
      );

      expect(
        buffer.toString(),
        equalsFormattedCode('''// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: my_rule_1, my_rule_2

import 'package:equatable/equatable.dart';
import 'package:gql/ast.dart';
import 'package:json_annotation/json_annotation.dart';
part 'test_query.graphql.g.dart';
'''),
      );
    },
  );
}
