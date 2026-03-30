// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:dartpollo/dartpollo.dart';
import 'package:equatable/equatable.dart';
import 'package:gql/ast.dart';
import 'package:json_annotation/json_annotation.dart';
part 'big_query.graphql.g.dart';

@JsonSerializable(explicitToJson: true)
class BigQuery$Query$Charmander extends JsonSerializable with EquatableMixin {
  BigQuery$Query$Charmander();

  factory BigQuery$Query$Charmander.fromJson(Map<String, dynamic> json) =>
      _$BigQuery$Query$CharmanderFromJson(json);

  String? number;

  List<String?>? types;

  @override
  List<Object?> get props => [number, types];

  @override
  Map<String, dynamic> toJson() => _$BigQuery$Query$CharmanderToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BigQuery$Query$Pokemon$Evolutions extends JsonSerializable
    with EquatableMixin {
  BigQuery$Query$Pokemon$Evolutions();

  factory BigQuery$Query$Pokemon$Evolutions.fromJson(
          Map<String, dynamic> json) =>
      _$BigQuery$Query$Pokemon$EvolutionsFromJson(json);

  String? number;

  String? name;

  @override
  List<Object?> get props => [number, name];

  @override
  Map<String, dynamic> toJson() =>
      _$BigQuery$Query$Pokemon$EvolutionsToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BigQuery$Query$Pokemon extends JsonSerializable with EquatableMixin {
  BigQuery$Query$Pokemon();

  factory BigQuery$Query$Pokemon.fromJson(Map<String, dynamic> json) =>
      _$BigQuery$Query$PokemonFromJson(json);

  String? number;

  String? name;

  List<String?>? types;

  List<BigQuery$Query$Pokemon$Evolutions?>? evolutions;

  @override
  List<Object?> get props => [number, name, types, evolutions];

  @override
  Map<String, dynamic> toJson() => _$BigQuery$Query$PokemonToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BigQuery$Query extends JsonSerializable with EquatableMixin {
  BigQuery$Query();

  factory BigQuery$Query.fromJson(Map<String, dynamic> json) =>
      _$BigQuery$QueryFromJson(json);

  BigQuery$Query$Charmander? charmander;

  List<BigQuery$Query$Pokemon?>? pokemons;

  @override
  List<Object?> get props => [charmander, pokemons];

  @override
  Map<String, dynamic> toJson() => _$BigQuery$QueryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BigQueryArguments extends JsonSerializable with EquatableMixin {
  BigQueryArguments({required this.quantity});

  @override
  factory BigQueryArguments.fromJson(Map<String, dynamic> json) =>
      _$BigQueryArgumentsFromJson(json);

  late int quantity;

  @override
  List<Object?> get props => [quantity];

  @override
  Map<String, dynamic> toJson() => _$BigQueryArgumentsToJson(this);
}

final BIG_QUERY_QUERY_DOCUMENT_OPERATION_NAME = 'big_query';
final BIG_QUERY_QUERY_DOCUMENT = DocumentNodeHelpers.document([
  DocumentNodeHelpers.operation(
    OperationType.query,
    'big_query',
    variables: [
      VariableDefinitionNode(
        variable: DocumentNodeHelpers.variable('quantity'),
        type: NamedTypeNode(name: NameNode(value: 'Int'), isNonNull: true),
        defaultValue: DefaultValueNode(value: null),
      ),
    ],
    selections: [
      DocumentNodeHelpers.field('pokemon', alias: 'charmander', args: {
        'name': 'Charmander'
      }, selections: [
        DocumentNodeHelpers.field('number'),
        DocumentNodeHelpers.field('types'),
      ]),
      DocumentNodeHelpers.field('pokemons', args: {
        'first': DocumentNodeHelpers.variable('quantity')
      }, selections: [
        DocumentNodeHelpers.field('number'),
        DocumentNodeHelpers.field('name'),
        DocumentNodeHelpers.field('types'),
        DocumentNodeHelpers.field('evolutions',
            alias: 'evolutions',
            selections: [
              DocumentNodeHelpers.field('number'),
              DocumentNodeHelpers.field('name'),
            ]),
      ]),
    ],
  ),
]);

class BigQueryQuery extends GraphQLQuery<BigQuery$Query, BigQueryArguments> {
  BigQueryQuery({required this.variables});

  @override
  final DocumentNode document = BIG_QUERY_QUERY_DOCUMENT;

  @override
  final String operationName = BIG_QUERY_QUERY_DOCUMENT_OPERATION_NAME;

  @override
  final BigQueryArguments variables;

  @override
  List<Object?> get props => [document, operationName, variables];

  @override
  BigQuery$Query parse(Map<String, dynamic> json) =>
      BigQuery$Query.fromJson(json);
}
