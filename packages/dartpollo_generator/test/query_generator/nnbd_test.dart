import 'package:dartpollo_generator/generator/data/data.dart';
import 'package:test/test.dart';

import '../helpers.dart';

void main() {
  group('On nnbd', () {
    test(
      'On field selection',
      () => testGenerator(
        query: 'query { nonNullAndSelected, nullableAndSelected }',
        schema: r'''
        type Query {
          nonNullAndSelected: String!
          nonNullAndNotSelected: String!
          nullableAndSelected: String
          nullableAndNotSelected: String
        }
      ''',
        libraryDefinition: libraryDefinition,
        generatedFile: output,
      ),
    );
  });

  test(
    'On lists and nullability',
    () => testGenerator(
      query: 'query { i, inn, li, linn, lnni, lnninn, matrix, matrixnn }',
      schema: r'''
        type Query {
          i: Int
          inn: Int!
          li: [Int]
          linn: [Int!]
          lnni: [Int]!
          lnninn: [Int!]!
          matrix: [[Int]]
          matrixnn: [[Int!]!]!
        }
      ''',
      libraryDefinition: listsLibraryDefinition,
      generatedFile: listsOutput,
    ),
  );
}

final libraryDefinition = LibraryDefinition(
  basename: r'**.graphql',
  queries: [
    QueryDefinition(
      name: QueryName(name: r'Query$_Query'),
      operationName: r'query',
      classes: [
        ClassDefinition(
          name: ClassName(name: r'Query$_Query'),
          properties: [
            ClassProperty(
              type: DartTypeName(name: r'String', isNonNull: true),
              name: const ClassPropertyName(name: r'nonNullAndSelected'),
            ),
            ClassProperty(
              type: DartTypeName(name: r'String'),
              name: const ClassPropertyName(name: r'nullableAndSelected'),
            ),
          ],
          typeNameField: const ClassPropertyName(name: r'__typename'),
        ),
      ],
    ),
  ],
);

const output = r'''// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:gql/ast.dart';
part 'query.graphql.g.dart';

@JsonSerializable(explicitToJson: true)
class Query$Query extends JsonSerializable with EquatableMixin {
  Query$Query();

  factory Query$Query.fromJson(Map<String, dynamic> json) =>
      _$Query$QueryFromJson(json);

  late String nonNullAndSelected;

  String? nullableAndSelected;

  @override
  List<Object?> get props => [nonNullAndSelected, nullableAndSelected];
  @override
  Map<String, dynamic> toJson() => _$Query$QueryToJson(this);
}
''';

final listsLibraryDefinition = LibraryDefinition(
  basename: r'**.graphql',
  queries: [
    QueryDefinition(
      name: QueryName(name: r'Query$_Query'),
      operationName: r'query',
      classes: [
        ClassDefinition(
          name: ClassName(name: r'Query$_Query'),
          properties: [
            ClassProperty(
              type: DartTypeName(name: r'int'),
              name: const ClassPropertyName(name: r'i'),
            ),
            ClassProperty(
              type: DartTypeName(name: r'int', isNonNull: true),
              name: const ClassPropertyName(name: r'inn'),
            ),
            ClassProperty(
              type: ListOfTypeName(
                typeName: DartTypeName(name: r'int'),
                isNonNull: false,
              ),
              name: const ClassPropertyName(name: r'li'),
            ),
            ClassProperty(
              type: ListOfTypeName(
                typeName: DartTypeName(name: r'int', isNonNull: true),
                isNonNull: false,
              ),
              name: const ClassPropertyName(name: r'linn'),
            ),
            ClassProperty(
              type: ListOfTypeName(
                typeName: DartTypeName(name: r'int'),
              ),
              name: const ClassPropertyName(name: r'lnni'),
            ),
            ClassProperty(
              type: ListOfTypeName(
                typeName: DartTypeName(name: r'int', isNonNull: true),
              ),
              name: const ClassPropertyName(name: r'lnninn'),
            ),
            ClassProperty(
              type: ListOfTypeName(
                typeName: ListOfTypeName(
                  typeName: DartTypeName(name: r'int'),
                  isNonNull: false,
                ),
                isNonNull: false,
              ),
              name: const ClassPropertyName(name: r'matrix'),
            ),
            ClassProperty(
              type: ListOfTypeName(
                typeName: ListOfTypeName(
                  typeName: DartTypeName(name: r'int', isNonNull: true),
                ),
              ),
              name: const ClassPropertyName(name: r'matrixnn'),
            ),
          ],
          typeNameField: const ClassPropertyName(name: r'__typename'),
        ),
      ],
    ),
  ],
);

const listsOutput = r'''// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:gql/ast.dart';
part 'query.graphql.g.dart';

@JsonSerializable(explicitToJson: true)
class Query$Query extends JsonSerializable with EquatableMixin {
  Query$Query();

  factory Query$Query.fromJson(Map<String, dynamic> json) =>
      _$Query$QueryFromJson(json);

  int? i;

  late int inn;

  List<int?>? li;

  List<int>? linn;

  late List<int?> lnni;

  late List<int> lnninn;

  List<List<int?>?>? matrix;

  late List<List<int>> matrixnn;

  @override
  List<Object?> get props => [i, inn, li, linn, lnni, lnninn, matrix, matrixnn];
  @override
  Map<String, dynamic> toJson() => _$Query$QueryToJson(this);
}
''';
