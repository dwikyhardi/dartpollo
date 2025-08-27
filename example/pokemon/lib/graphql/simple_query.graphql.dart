// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:collection/collection.dart';
import 'package:dartpollo/dartpollo.dart';
import 'package:dartpollo/generator/document_helpers.dart';
import 'package:dartpollo/schema/graphql_data_class.dart';
import 'package:gql/ast.dart';
import 'package:json_annotation/json_annotation.dart';
part 'simple_query.graphql.g.dart';

@JsonSerializable(explicitToJson: true)
class SimpleQuery$Query$Pokemon extends GraphQLDataClass {
  SimpleQuery$Query$Pokemon();

  factory SimpleQuery$Query$Pokemon.fromJson(Map<String, dynamic> json) =>
      _$SimpleQuery$Query$PokemonFromJson(json);

  String? number;

  List<String?>? types;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SimpleQuery$Query$Pokemon) return false;
    return number == other.number &&
        const DeepCollectionEquality().equals(types, other.types);
  }

  @override
  int get hashCode =>
      Object.hash(number.hashCode, const DeepCollectionEquality().hash(types));

  @override
  String toString() =>
      'SimpleQuery\$Query\$Pokemon(number: $number, types: ${types?.length ?? 0} items)';

  @override
  Map<String, dynamic> toJson() => _$SimpleQuery$Query$PokemonToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SimpleQuery$Query extends GraphQLDataClass {
  SimpleQuery$Query();

  factory SimpleQuery$Query.fromJson(Map<String, dynamic> json) =>
      _$SimpleQuery$QueryFromJson(json);

  SimpleQuery$Query$Pokemon? pokemon;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SimpleQuery$Query) return false;
    return pokemon == other.pokemon;
  }

  @override
  int get hashCode => pokemon.hashCode;

  @override
  String toString() => 'SimpleQuery\$Query(pokemon: $pokemon)';

  @override
  Map<String, dynamic> toJson() => _$SimpleQuery$QueryToJson(this);
}

final SIMPLE_QUERY_QUERY_DOCUMENT_OPERATION_NAME = 'simple_query';
final SIMPLE_QUERY_QUERY_DOCUMENT = DocumentNodeHelpers.document([
  DocumentNodeHelpers.operation(
    OperationType.query,
    'simple_query',
    selections: [
      DocumentNodeHelpers.field('pokemon', args: {
        'name': 'Charmander'
      }, selections: [
        DocumentNodeHelpers.field('number'),
        DocumentNodeHelpers.field('types'),
      ]),
    ],
  ),
]);

class SimpleQueryQuery
    extends GraphQLQuery<SimpleQuery$Query, JsonSerializable> {
  SimpleQueryQuery();

  @override
  final DocumentNode document = SIMPLE_QUERY_QUERY_DOCUMENT;

  @override
  final String operationName = SIMPLE_QUERY_QUERY_DOCUMENT_OPERATION_NAME;

  @override
  List<Object?> get props => [document, operationName];

  @override
  SimpleQuery$Query parse(Map<String, dynamic> json) =>
      SimpleQuery$Query.fromJson(json);
}
