import 'package:dartpollo_generator/generator/data/data.dart';
import 'package:test/test.dart';

import '../../helpers.dart';

void main() {
  group('On scalars', () {
    group('All default GraphQL scalars are parsed correctly', () {
      test(
        'If they are defined on schema',
        () => testGenerator(
          schema: r'''
            scalar Int
            scalar Float
            scalar String
            scalar Boolean
            scalar ID
            
            schema {
              query: SomeObject
            }
            
            type SomeObject {
              i: Int
              f: Float
              s: String
              b: Boolean
              id: ID
            }
          ''',
          query: 'query some_query { i, f, s, b, id }',
          libraryDefinition: libraryDefinition,
          generatedFile: generatedFile,
        ),
      );

      test(
        'All default GraphQL scalars are parsed correctly even if they are NOT explicitly defined on schema',
        () => testGenerator(
          schema: r'''
            schema {
              query: SomeObject
            }
            
            type SomeObject {
              i: Int
              f: Float
              s: String
              b: Boolean
              id: ID
            }
          ''',
          query: query,
          libraryDefinition: libraryDefinition,
          generatedFile: generatedFile,
        ),
      );
    });
  });
}

const String query = 'query some_query { i, f, s, b, id }';

final LibraryDefinition libraryDefinition = LibraryDefinition(
  basename: r'query.graphql',
  queries: [
    QueryDefinition(
      name: QueryName(name: r'SomeQuery$_SomeObject'),
      operationName: r'some_query',
      classes: [
        ClassDefinition(
          name: ClassName(name: r'SomeQuery$_SomeObject'),
          properties: [
            ClassProperty(
              type: DartTypeName(name: r'int'),
              name: const ClassPropertyName(name: r'i'),
            ),
            ClassProperty(
              type: DartTypeName(name: r'double'),
              name: const ClassPropertyName(name: r'f'),
            ),
            ClassProperty(
              type: DartTypeName(name: r'String'),
              name: const ClassPropertyName(name: r's'),
            ),
            ClassProperty(
              type: DartTypeName(name: r'bool'),
              name: const ClassPropertyName(name: r'b'),
            ),
            ClassProperty(
              type: DartTypeName(name: r'String'),
              name: const ClassPropertyName(name: r'id'),
            ),
          ],
          typeNameField: const ClassPropertyName(name: r'__typename'),
        ),
      ],
    ),
  ],
);

const generatedFile = r'''// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:gql/ast.dart';
part 'query.graphql.g.dart';

@JsonSerializable(explicitToJson: true)
class SomeQuery$SomeObject extends JsonSerializable with EquatableMixin {
  SomeQuery$SomeObject();

  factory SomeQuery$SomeObject.fromJson(Map<String, dynamic> json) =>
      _$SomeQuery$SomeObjectFromJson(json);

  int? i;

  double? f;

  String? s;

  bool? b;

  String? id;

  @override
  List<Object?> get props => [i, f, s, b, id];
  @override
  Map<String, dynamic> toJson() => _$SomeQuery$SomeObjectToJson(this);
}
''';
