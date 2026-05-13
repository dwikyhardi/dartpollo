// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

// dart format off
import 'package:dartpollo/dartpollo.dart';import 'package:equatable/equatable.dart';import 'package:gql/ast.dart';import 'package:json_annotation/json_annotation.dart';part 'simple_query.graphql.g.dart';@JsonSerializable(explicitToJson: true) class SimpleQuery$Query$Pokemon extends JsonSerializable with EquatableMixin {SimpleQuery$Query$Pokemon();

factory SimpleQuery$Query$Pokemon.fromJson(Map<String, dynamic> json) => _$SimpleQuery$Query$PokemonFromJson(json);

String? number;

List<String?>? types;

@override List<Object?> get props => [number, types];

@override Map<String, dynamic> toJson() => _$SimpleQuery$Query$PokemonToJson(this);

 }
@JsonSerializable(explicitToJson: true) class SimpleQuery$Query extends JsonSerializable with EquatableMixin {SimpleQuery$Query();

factory SimpleQuery$Query.fromJson(Map<String, dynamic> json) => _$SimpleQuery$QueryFromJson(json);

SimpleQuery$Query$Pokemon? pokemon;

@override List<Object?> get props => [pokemon];

@override Map<String, dynamic> toJson() => _$SimpleQuery$QueryToJson(this);

 }
final SIMPLE_QUERY_QUERY_DOCUMENT_OPERATION_NAME = 'simple_query';
final SIMPLE_QUERY_QUERY_DOCUMENT = 
DocumentNodeHelpers.document([
  DocumentNodeHelpers.operation(
    OperationType.query,
    'simple_query',
    selections: [
      DocumentNodeHelpers.field('pokemon', args: {'name': 'Charmander'}, selections: [
        DocumentNodeHelpers.field('number'),
        DocumentNodeHelpers.field('types'),
      ]),
    ],
  ),
])

;class SimpleQueryQuery extends GraphQLQuery<SimpleQuery$Query, JsonSerializable> {SimpleQueryQuery();

@override final DocumentNode document = SIMPLE_QUERY_QUERY_DOCUMENT;

@override final String operationName = SIMPLE_QUERY_QUERY_DOCUMENT_OPERATION_NAME;

@override List<Object?> get props => [document, operationName];

@override SimpleQuery$Query parse(Map<String, dynamic> json) => SimpleQuery$Query.fromJson(json);

 }
