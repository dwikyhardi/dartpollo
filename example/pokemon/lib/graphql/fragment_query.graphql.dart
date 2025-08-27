// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:collection/collection.dart';
import 'package:dartpollo/dartpollo.dart';
import 'package:dartpollo/generator/document_helpers.dart';
import 'package:dartpollo/schema/graphql_data_class.dart';
import 'package:gql/ast.dart';
import 'package:json_annotation/json_annotation.dart';
part 'fragment_query.graphql.g.dart';

mixin PokemonPartsMixin {
  String? number;
  String? name;
  List<String?>? types;
}

@JsonSerializable(explicitToJson: true)
class FragmentQuery$Query$Charmander extends GraphQLDataClass
    with PokemonPartsMixin {
  FragmentQuery$Query$Charmander();

  factory FragmentQuery$Query$Charmander.fromJson(Map<String, dynamic> json) =>
      _$FragmentQuery$Query$CharmanderFromJson(json);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FragmentQuery$Query$Charmander) return false;
    return name == other.name && number == other.number && types == other.types;
  }

  @override
  int get hashCode =>
      Object.hash(number.hashCode, name.hashCode, types.hashCode);

  @override
  String toString() =>
      'FragmentQuery\$Query\$Charmander(name: $name, number: $number, types: $types)';

  @override
  Map<String, dynamic> toJson() => _$FragmentQuery$Query$CharmanderToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FragmentQuery$Query$Pokemon$Evolutions extends GraphQLDataClass
    with PokemonPartsMixin {
  FragmentQuery$Query$Pokemon$Evolutions();

  factory FragmentQuery$Query$Pokemon$Evolutions.fromJson(
          Map<String, dynamic> json) =>
      _$FragmentQuery$Query$Pokemon$EvolutionsFromJson(json);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FragmentQuery$Query$Pokemon$Evolutions) return false;
    return name == other.name && number == other.number && types == other.types;
  }

  @override
  int get hashCode =>
      Object.hash(number.hashCode, name.hashCode, types.hashCode);

  @override
  String toString() =>
      'FragmentQuery\$Query\$Pokemon\$Evolutions(name: $name, number: $number, types: $types)';

  @override
  Map<String, dynamic> toJson() =>
      _$FragmentQuery$Query$Pokemon$EvolutionsToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FragmentQuery$Query$Pokemon extends GraphQLDataClass
    with PokemonPartsMixin {
  FragmentQuery$Query$Pokemon();

  factory FragmentQuery$Query$Pokemon.fromJson(Map<String, dynamic> json) =>
      _$FragmentQuery$Query$PokemonFromJson(json);

  List<FragmentQuery$Query$Pokemon$Evolutions?>? evolutions;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FragmentQuery$Query$Pokemon) return false;
    return const DeepCollectionEquality()
            .equals(evolutions, other.evolutions) &&
        name == other.name &&
        number == other.number &&
        types == other.types;
  }

  @override
  int get hashCode => Object.hash(number.hashCode, name.hashCode,
      types.hashCode, const DeepCollectionEquality().hash(evolutions));

  @override
  String toString() =>
      'FragmentQuery\$Query\$Pokemon(evolutions: ${evolutions?.length ?? 0} items, name: $name, number: $number, types: $types)';

  @override
  Map<String, dynamic> toJson() => _$FragmentQuery$Query$PokemonToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FragmentQuery$Query extends GraphQLDataClass {
  FragmentQuery$Query();

  factory FragmentQuery$Query.fromJson(Map<String, dynamic> json) =>
      _$FragmentQuery$QueryFromJson(json);

  FragmentQuery$Query$Charmander? charmander;

  List<FragmentQuery$Query$Pokemon?>? pokemons;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FragmentQuery$Query) return false;
    return charmander == other.charmander &&
        const DeepCollectionEquality().equals(pokemons, other.pokemons);
  }

  @override
  int get hashCode => Object.hash(
      charmander.hashCode, const DeepCollectionEquality().hash(pokemons));

  @override
  String toString() =>
      'FragmentQuery\$Query(charmander: $charmander, pokemons: ${pokemons?.length ?? 0} items)';

  @override
  Map<String, dynamic> toJson() => _$FragmentQuery$QueryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FragmentQueryArguments extends GraphQLDataClass {
  FragmentQueryArguments({required this.quantity});

  factory FragmentQueryArguments.fromJson(Map<String, dynamic> json) =>
      _$FragmentQueryArgumentsFromJson(json);

  late int quantity;

  @override
  Map<String, dynamic> toJson() => _$FragmentQueryArgumentsToJson(this);
}

final FRAGMENT_QUERY_QUERY_DOCUMENT_OPERATION_NAME = 'fragmentQuery';
final FRAGMENT_QUERY_QUERY_DOCUMENT = DocumentNodeHelpers.document([
  DocumentNodeHelpers.operation(
    OperationType.query,
    'fragmentQuery',
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
        DocumentNodeHelpers.fragmentSpread('PokemonParts'),
      ]),
      DocumentNodeHelpers.field('pokemons', args: {
        'first': DocumentNodeHelpers.variable('quantity')
      }, selections: [
        DocumentNodeHelpers.fragmentSpread('PokemonParts'),
        DocumentNodeHelpers.field('evolutions',
            alias: 'evolutions',
            selections: [
              DocumentNodeHelpers.fragmentSpread('PokemonParts'),
            ]),
      ]),
    ],
  ),
]);

class FragmentQueryQuery
    extends GraphQLQuery<FragmentQuery$Query, FragmentQueryArguments> {
  FragmentQueryQuery({required this.variables});

  @override
  final DocumentNode document = FRAGMENT_QUERY_QUERY_DOCUMENT;

  @override
  final String operationName = FRAGMENT_QUERY_QUERY_DOCUMENT_OPERATION_NAME;

  @override
  final FragmentQueryArguments variables;

  @override
  List<Object?> get props => [document, operationName, variables];

  @override
  FragmentQuery$Query parse(Map<String, dynamic> json) =>
      FragmentQuery$Query.fromJson(json);
}
