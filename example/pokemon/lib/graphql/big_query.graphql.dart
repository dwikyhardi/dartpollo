// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:collection/collection.dart';
import 'package:dartpollo/dartpollo.dart';
import 'package:dartpollo/generator/document_helpers.dart';
import 'package:dartpollo/schema/graphql_data_class.dart';
import 'package:gql/ast.dart';
import 'package:json_annotation/json_annotation.dart';
part 'big_query.graphql.g.dart';

@JsonSerializable(explicitToJson: true)
class BigQuery$Query$Charmander extends GraphQLDataClass {
  BigQuery$Query$Charmander();

  factory BigQuery$Query$Charmander.fromJson(Map<String, dynamic> json) =>
      _$BigQuery$Query$CharmanderFromJson(json);

  String? number;

  List<String?>? types;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BigQuery$Query$Charmander) return false;
    return number == other.number &&
        const DeepCollectionEquality().equals(types, other.types);
  }

  @override
  int get hashCode =>
      Object.hash(number.hashCode, const DeepCollectionEquality().hash(types));

  @override
  String toString() =>
      'BigQuery\$Query\$Charmander(number: $number, types: ${types?.length ?? 0} items)';

  @override
  Map<String, dynamic> toJson() => _$BigQuery$Query$CharmanderToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BigQuery$Query$Pokemon$Evolutions extends GraphQLDataClass {
  BigQuery$Query$Pokemon$Evolutions();

  factory BigQuery$Query$Pokemon$Evolutions.fromJson(
          Map<String, dynamic> json) =>
      _$BigQuery$Query$Pokemon$EvolutionsFromJson(json);

  String? number;

  String? name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BigQuery$Query$Pokemon$Evolutions) return false;
    return name == other.name && number == other.number;
  }

  @override
  int get hashCode => Object.hash(number.hashCode, name.hashCode);

  @override
  String toString() =>
      'BigQuery\$Query\$Pokemon\$Evolutions(name: $name, number: $number)';

  @override
  Map<String, dynamic> toJson() =>
      _$BigQuery$Query$Pokemon$EvolutionsToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BigQuery$Query$Pokemon extends GraphQLDataClass {
  BigQuery$Query$Pokemon();

  factory BigQuery$Query$Pokemon.fromJson(Map<String, dynamic> json) =>
      _$BigQuery$Query$PokemonFromJson(json);

  String? number;

  String? name;

  List<String?>? types;

  List<BigQuery$Query$Pokemon$Evolutions?>? evolutions;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BigQuery$Query$Pokemon) return false;
    return const DeepCollectionEquality()
            .equals(evolutions, other.evolutions) &&
        name == other.name &&
        number == other.number &&
        const DeepCollectionEquality().equals(types, other.types);
  }

  @override
  int get hashCode => Object.hash(
      number.hashCode,
      name.hashCode,
      const DeepCollectionEquality().hash(types),
      const DeepCollectionEquality().hash(evolutions));

  @override
  String toString() =>
      'BigQuery\$Query\$Pokemon(evolutions: ${evolutions?.length ?? 0} items, name: $name, number: $number, types: ${types?.length ?? 0} items)';

  @override
  Map<String, dynamic> toJson() => _$BigQuery$Query$PokemonToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BigQuery$Query extends GraphQLDataClass {
  BigQuery$Query();

  factory BigQuery$Query.fromJson(Map<String, dynamic> json) =>
      _$BigQuery$QueryFromJson(json);

  BigQuery$Query$Charmander? charmander;

  List<BigQuery$Query$Pokemon?>? pokemons;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BigQuery$Query) return false;
    return charmander == other.charmander &&
        const DeepCollectionEquality().equals(pokemons, other.pokemons);
  }

  @override
  int get hashCode => Object.hash(
      charmander.hashCode, const DeepCollectionEquality().hash(pokemons));

  @override
  String toString() =>
      'BigQuery\$Query(charmander: $charmander, pokemons: ${pokemons?.length ?? 0} items)';

  @override
  Map<String, dynamic> toJson() => _$BigQuery$QueryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class BigQueryArguments extends GraphQLDataClass {
  BigQueryArguments({required this.quantity});

  factory BigQueryArguments.fromJson(Map<String, dynamic> json) =>
      _$BigQueryArgumentsFromJson(json);

  late int quantity;

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
