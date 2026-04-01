import 'package:dartpollo_generator/generator/data/data.dart';
import 'package:test/test.dart';

import '../../helpers.dart';

void main() {
  group('On scalars', () {
    group('On custom scalars', () {
      test(
        'If they can be converted to a simple dart class',
        () => testGenerator(
          query: 'query query { a, b }',
          schema: r'''
            scalar MyUuid
            scalar Json
            
            schema {
              query: SomeObject
            }
            
            type SomeObject {
              a: MyUuid
              b: Json
            }
          ''',
          libraryDefinition: libraryDefinition,
          generatedFile: generatedFile,
          builderOptionsMap: {
            'scalar_mapping': [
              {
                'graphql_type': 'MyUuid',
                'dart_type': 'String',
              },
              {
                'graphql_type': 'Json',
                'dart_type': 'Map<String, dynamic>',
              },
            ],
          },
        ),
      );
    });

    test(
      'When they need custom parser functions',
      () => testGenerator(
        query: 'query query { a }',
        schema: r'''
          scalar MyUuid

          schema {
            query: SomeObject
          }

          type SomeObject {
            a: MyUuid
          }
        ''',
        libraryDefinition: libraryDefinitionWithCustomParserFns,
        generatedFile: generatedFileWithCustomParserFns,
        builderOptionsMap: {
          'scalar_mapping': [
            {
              'graphql_type': 'MyUuid',
              'custom_parser_import': 'package:example/src/custom_parser.dart',
              'dart_type': 'MyDartUuid',
            },
          ],
        },
      ),
    );

    test(
      'When they need custom imports',
      () => testGenerator(
        query: 'query query { a, b, c, d, e, f }',
        schema: r'''
          scalar MyUuid

          schema {
            query: SomeObject
          }

          type SomeObject {
            a: MyUuid
            b: MyUuid!
            c: [MyUuid!]!
            d: [MyUuid]
            e: [MyUuid]!
            f: [MyUuid!]
          }
        ''',
        libraryDefinition: libraryDefinitionWithCustomImports,
        generatedFile: generatedFileWithCustomImports,
        builderOptionsMap: {
          'scalar_mapping': [
            {
              'graphql_type': 'MyUuid',
              'custom_parser_import': 'package:example/src/custom_parser.dart',
              'dart_type': {
                'name': 'MyUuid',
                'imports': ['package:uuid/uuid.dart'],
              },
            },
          ],
        },
      ),
    );
  });
}

final LibraryDefinition libraryDefinition = LibraryDefinition(
  basename: r'**.graphql',
  queries: [
    QueryDefinition(
      name: QueryName(name: r'Query$_SomeObject'),
      operationName: r'query',
      classes: [
        ClassDefinition(
          name: ClassName(name: r'Query$_SomeObject'),
          properties: [
            ClassProperty(
              type: DartTypeName(name: r'String'),
              name: const ClassPropertyName(name: r'a'),
            ),
            ClassProperty(
              type: DartTypeName(name: r'Map<String, dynamic>'),
              name: const ClassPropertyName(name: r'b'),
            ),
          ],
          typeNameField: const ClassPropertyName(name: r'__typename'),
        ),
      ],
    ),
  ],
);

final LibraryDefinition
libraryDefinitionWithCustomParserFns = LibraryDefinition(
  basename: r'**.graphql',
  queries: [
    QueryDefinition(
      name: QueryName(name: r'Query$_SomeObject'),
      operationName: r'query',
      classes: [
        ClassDefinition(
          name: ClassName(name: r'Query$_SomeObject'),
          properties: [
            ClassProperty(
              type: DartTypeName(name: r'MyDartUuid'),
              name: const ClassPropertyName(name: r'a'),
              annotations: const [
                r'JsonKey(fromJson: fromGraphQLMyUuidNullableToDartMyDartUuidNullable, toJson: fromDartMyDartUuidNullableToGraphQLMyUuidNullable)',
              ],
            ),
          ],
          typeNameField: const ClassPropertyName(name: r'__typename'),
        ),
      ],
    ),
  ],
  customImports: const [r'package:example/src/custom_parser.dart'],
);

final LibraryDefinition libraryDefinitionWithCustomImports = LibraryDefinition(
  basename: r'**.graphql',
  queries: [
    QueryDefinition(
      name: QueryName(name: r'Query$_SomeObject'),
      operationName: r'query',
      classes: [
        ClassDefinition(
          name: ClassName(name: r'Query$_SomeObject'),
          properties: [
            ClassProperty(
              type: DartTypeName(name: r'MyUuid'),
              name: const ClassPropertyName(name: r'a'),
              annotations: const [
                r'JsonKey(fromJson: fromGraphQLMyUuidNullableToDartMyUuidNullable, toJson: fromDartMyUuidNullableToGraphQLMyUuidNullable)',
              ],
            ),
            ClassProperty(
              type: DartTypeName(name: r'MyUuid', isNonNull: true),
              name: const ClassPropertyName(name: r'b'),
              annotations: const [
                r'JsonKey(fromJson: fromGraphQLMyUuidToDartMyUuid, toJson: fromDartMyUuidToGraphQLMyUuid)',
              ],
            ),
            ClassProperty(
              type: ListOfTypeName(
                typeName: DartTypeName(name: r'MyUuid', isNonNull: true),
              ),
              name: const ClassPropertyName(name: r'c'),
              annotations: const [
                r'JsonKey(fromJson: fromGraphQLListMyUuidToDartListMyUuid, toJson: fromDartListMyUuidToGraphQLListMyUuid)',
              ],
            ),
            ClassProperty(
              type: ListOfTypeName(
                typeName: DartTypeName(name: r'MyUuid'),
                isNonNull: false,
              ),
              name: const ClassPropertyName(name: r'd'),
              annotations: const [
                r'JsonKey(fromJson: fromGraphQLListNullableMyUuidNullableToDartListNullableMyUuidNullable, toJson: fromDartListNullableMyUuidNullableToGraphQLListNullableMyUuidNullable)',
              ],
            ),
            ClassProperty(
              type: ListOfTypeName(
                typeName: DartTypeName(name: r'MyUuid'),
              ),
              name: const ClassPropertyName(name: r'e'),
              annotations: const [
                r'JsonKey(fromJson: fromGraphQLListMyUuidNullableToDartListMyUuidNullable, toJson: fromDartListMyUuidNullableToGraphQLListMyUuidNullable)',
              ],
            ),
            ClassProperty(
              type: ListOfTypeName(
                typeName: DartTypeName(name: r'MyUuid', isNonNull: true),
                isNonNull: false,
              ),
              name: const ClassPropertyName(name: r'f'),
              annotations: const [
                r'JsonKey(fromJson: fromGraphQLListNullableMyUuidToDartListNullableMyUuid, toJson: fromDartListNullableMyUuidToGraphQLListNullableMyUuid)',
              ],
            ),
          ],
          typeNameField: const ClassPropertyName(name: r'__typename'),
        ),
      ],
    ),
  ],
  customImports: const [
    r'package:uuid/uuid.dart',
    r'package:example/src/custom_parser.dart',
  ],
);

const generatedFile = r'''// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:gql/ast.dart';
part 'query.graphql.g.dart';

@JsonSerializable(explicitToJson: true)
class Query$SomeObject extends JsonSerializable with EquatableMixin {
  Query$SomeObject();

  factory Query$SomeObject.fromJson(Map<String, dynamic> json) =>
      _$Query$SomeObjectFromJson(json);

  String? a;

  Map<String, dynamic>? b;

  @override
  List<Object?> get props => [a, b];
  @override
  Map<String, dynamic> toJson() => _$Query$SomeObjectToJson(this);
}
''';

const generatedFileWithCustomParserFns =
    r'''// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:gql/ast.dart';
import 'package:example/src/custom_parser.dart';
part 'query.graphql.g.dart';

@JsonSerializable(explicitToJson: true)
class Query$SomeObject extends JsonSerializable with EquatableMixin {
  Query$SomeObject();

  factory Query$SomeObject.fromJson(Map<String, dynamic> json) =>
      _$Query$SomeObjectFromJson(json);

  @JsonKey(
      fromJson: fromGraphQLMyUuidNullableToDartMyDartUuidNullable,
      toJson: fromDartMyDartUuidNullableToGraphQLMyUuidNullable)
  MyDartUuid? a;

  @override
  List<Object?> get props => [a];
  @override
  Map<String, dynamic> toJson() => _$Query$SomeObjectToJson(this);
}
''';

const generatedFileWithCustomImports =
    r'''// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:gql/ast.dart';
import 'package:uuid/uuid.dart';
import 'package:example/src/custom_parser.dart';
part 'query.graphql.g.dart';

@JsonSerializable(explicitToJson: true)
class Query$SomeObject extends JsonSerializable with EquatableMixin {
  Query$SomeObject();

  factory Query$SomeObject.fromJson(Map<String, dynamic> json) =>
      _$Query$SomeObjectFromJson(json);

  @JsonKey(
      fromJson: fromGraphQLMyUuidNullableToDartMyUuidNullable,
      toJson: fromDartMyUuidNullableToGraphQLMyUuidNullable)
  MyUuid? a;

  @JsonKey(
      fromJson: fromGraphQLMyUuidToDartMyUuid,
      toJson: fromDartMyUuidToGraphQLMyUuid)
  late MyUuid b;

  @JsonKey(
      fromJson: fromGraphQLListMyUuidToDartListMyUuid,
      toJson: fromDartListMyUuidToGraphQLListMyUuid)
  late List<MyUuid> c;

  @JsonKey(
      fromJson:
          fromGraphQLListNullableMyUuidNullableToDartListNullableMyUuidNullable,
      toJson:
          fromDartListNullableMyUuidNullableToGraphQLListNullableMyUuidNullable)
  List<MyUuid?>? d;

  @JsonKey(
      fromJson: fromGraphQLListMyUuidNullableToDartListMyUuidNullable,
      toJson: fromDartListMyUuidNullableToGraphQLListMyUuidNullable)
  late List<MyUuid?> e;

  @JsonKey(
      fromJson: fromGraphQLListNullableMyUuidToDartListNullableMyUuid,
      toJson: fromDartListNullableMyUuidToGraphQLListNullableMyUuid)
  List<MyUuid>? f;

  @override
  List<Object?> get props => [a, b, c, d, e, f];
  @override
  Map<String, dynamic> toJson() => _$Query$SomeObjectToJson(this);
}
''';
