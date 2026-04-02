import 'package:dartpollo_generator/generator/data/data.dart';
import 'package:test/test.dart';

import '../helpers.dart';

void main() {
  group('On forwarder', () {
    test(
      'Output is auto-generated even when output config is provided',
      () => testGenerator(
        query: query,
        libraryDefinition: libraryDefinition,
        generatedFile: generatedFile,
        schema: r'''
          schema {
            query: QueryRoot
          }

          type QueryRoot {
            a: String
          }''',
      ),
    );
  });
}

const query = r'''
query custom {
  a
}
''';

final LibraryDefinition libraryDefinition = LibraryDefinition(
  basename: r'**.graphql',
  queries: [
    QueryDefinition(
      name: QueryName(name: r'Custom$_QueryRoot'),
      operationName: r'custom',
      classes: [
        ClassDefinition(
          name: ClassName(name: r'Custom$_QueryRoot'),
          properties: [
            ClassProperty(
              type: DartTypeName(name: r'String'),
              name: const ClassPropertyName(name: r'a'),
            ),
          ],
          typeNameField: const ClassPropertyName(name: r'__typename'),
        ),
      ],
    ),
  ],
);

const generatedFile = r'''// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:equatable/equatable.dart';
import 'package:gql/ast.dart';
import 'package:json_annotation/json_annotation.dart';
part 'query.graphql.g.dart';

@JsonSerializable(explicitToJson: true)
class Custom$QueryRoot extends JsonSerializable with EquatableMixin {
  Custom$QueryRoot();

  factory Custom$QueryRoot.fromJson(Map<String, dynamic> json) =>
      _$Custom$QueryRootFromJson(json);

  String? a;

  @override
  List<Object?> get props => [a];

  @override
  Map<String, dynamic> toJson() => _$Custom$QueryRootToJson(this);
}
''';
