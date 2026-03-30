// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:dartpollo/dartpollo.dart';
import 'package:equatable/equatable.dart';
import 'package:gql/ast.dart';
import 'package:json_annotation/json_annotation.dart';
part 'fragment_query.query.gql.g.dart';

mixin PokemonPartsMixin {
  String? number;
  String? name;
  List<String?>? types;
}

@JsonSerializable(explicitToJson: true)
class FragmentQuery$Query$Charmander extends JsonSerializable
    with EquatableMixin, PokemonPartsMixin {
  FragmentQuery$Query$Charmander();

  factory FragmentQuery$Query$Charmander.fromJson(Map<String, dynamic> json) =>
      _$FragmentQuery$Query$CharmanderFromJson(json);

  @override
  List<Object?> get props => [number, name, types];

  @override
  Map<String, dynamic> toJson() => _$FragmentQuery$Query$CharmanderToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FragmentQuery$Query$Pokemon$Evolutions extends JsonSerializable
    with EquatableMixin, PokemonPartsMixin {
  FragmentQuery$Query$Pokemon$Evolutions();

  factory FragmentQuery$Query$Pokemon$Evolutions.fromJson(
          Map<String, dynamic> json) =>
      _$FragmentQuery$Query$Pokemon$EvolutionsFromJson(json);

  @override
  List<Object?> get props => [number, name, types];

  @override
  Map<String, dynamic> toJson() =>
      _$FragmentQuery$Query$Pokemon$EvolutionsToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FragmentQuery$Query$Pokemon extends JsonSerializable
    with EquatableMixin, PokemonPartsMixin {
  FragmentQuery$Query$Pokemon();

  factory FragmentQuery$Query$Pokemon.fromJson(Map<String, dynamic> json) =>
      _$FragmentQuery$Query$PokemonFromJson(json);

  List<FragmentQuery$Query$Pokemon$Evolutions?>? evolutions;

  @override
  List<Object?> get props => [number, name, types, evolutions];

  @override
  Map<String, dynamic> toJson() => _$FragmentQuery$Query$PokemonToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FragmentQuery$Query extends JsonSerializable with EquatableMixin {
  FragmentQuery$Query();

  factory FragmentQuery$Query.fromJson(Map<String, dynamic> json) =>
      _$FragmentQuery$QueryFromJson(json);

  FragmentQuery$Query$Charmander? charmander;

  List<FragmentQuery$Query$Pokemon?>? pokemons;

  @override
  List<Object?> get props => [charmander, pokemons];

  @override
  Map<String, dynamic> toJson() => _$FragmentQuery$QueryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FragmentQueryArguments extends JsonSerializable with EquatableMixin {
  FragmentQueryArguments({required this.quantity});

  @override
  factory FragmentQueryArguments.fromJson(Map<String, dynamic> json) =>
      _$FragmentQueryArgumentsFromJson(json);

  late int quantity;

  @override
  List<Object?> get props => [quantity];

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
  DocumentNodeHelpers.fragmentDefinition(
    'PokemonParts',
    'Pokemon',
    selections: [
      DocumentNodeHelpers.field('number'),
      DocumentNodeHelpers.field('name'),
      DocumentNodeHelpers.field('types'),
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
