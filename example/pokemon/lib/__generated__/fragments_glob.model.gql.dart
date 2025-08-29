// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:dartpollo/dartpollo.dart';
import 'package:equatable/equatable.dart';
import 'package:gql/ast.dart';
import 'package:json_annotation/json_annotation.dart';
part 'fragments_glob.model.gql.g.dart';

mixin PokemonMixin {
  late String id;
  PokemonMixin$PokemonDimension? weight;
  PokemonMixin$PokemonAttack? attacks;
}
mixin WeightMixin {
  String? minimum;
}
mixin PokemonAttackMixin {
  List<PokemonAttackMixin$Attack?>? special;
}
mixin AttackMixin {
  String? name;
}

@JsonSerializable(explicitToJson: true)
class FragmentsGlob$Query$Pokemon$Pokemon extends JsonSerializable
    with EquatableMixin, PokemonMixin {
  FragmentsGlob$Query$Pokemon$Pokemon();

  factory FragmentsGlob$Query$Pokemon$Pokemon.fromJson(
          Map<String, dynamic> json) =>
      _$FragmentsGlob$Query$Pokemon$PokemonFromJson(json);

  @override
  List<Object?> get props => [id, weight, attacks];

  @override
  Map<String, dynamic> toJson() =>
      _$FragmentsGlob$Query$Pokemon$PokemonToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FragmentsGlob$Query$Pokemon extends JsonSerializable
    with EquatableMixin, PokemonMixin {
  FragmentsGlob$Query$Pokemon();

  factory FragmentsGlob$Query$Pokemon.fromJson(Map<String, dynamic> json) =>
      _$FragmentsGlob$Query$PokemonFromJson(json);

  List<FragmentsGlob$Query$Pokemon$Pokemon?>? evolutions;

  @override
  List<Object?> get props => [id, weight, attacks, evolutions];

  @override
  Map<String, dynamic> toJson() => _$FragmentsGlob$Query$PokemonToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FragmentsGlob$Query extends JsonSerializable with EquatableMixin {
  FragmentsGlob$Query();

  factory FragmentsGlob$Query.fromJson(Map<String, dynamic> json) =>
      _$FragmentsGlob$QueryFromJson(json);

  FragmentsGlob$Query$Pokemon? pokemon;

  @override
  List<Object?> get props => [pokemon];

  @override
  Map<String, dynamic> toJson() => _$FragmentsGlob$QueryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PokemonMixin$PokemonDimension extends JsonSerializable
    with EquatableMixin, WeightMixin {
  PokemonMixin$PokemonDimension();

  factory PokemonMixin$PokemonDimension.fromJson(Map<String, dynamic> json) =>
      _$PokemonMixin$PokemonDimensionFromJson(json);

  @override
  List<Object?> get props => [minimum];

  @override
  Map<String, dynamic> toJson() => _$PokemonMixin$PokemonDimensionToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PokemonMixin$PokemonAttack extends JsonSerializable
    with EquatableMixin, PokemonAttackMixin {
  PokemonMixin$PokemonAttack();

  factory PokemonMixin$PokemonAttack.fromJson(Map<String, dynamic> json) =>
      _$PokemonMixin$PokemonAttackFromJson(json);

  @override
  List<Object?> get props => [special];

  @override
  Map<String, dynamic> toJson() => _$PokemonMixin$PokemonAttackToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PokemonAttackMixin$Attack extends JsonSerializable
    with EquatableMixin, AttackMixin {
  PokemonAttackMixin$Attack();

  factory PokemonAttackMixin$Attack.fromJson(Map<String, dynamic> json) =>
      _$PokemonAttackMixin$AttackFromJson(json);

  @override
  List<Object?> get props => [name];

  @override
  Map<String, dynamic> toJson() => _$PokemonAttackMixin$AttackToJson(this);
}

final FRAGMENTS_GLOB_QUERY_DOCUMENT_OPERATION_NAME = 'fragments_glob';
final FRAGMENTS_GLOB_QUERY_DOCUMENT = DocumentNodeHelpers.document([
  DocumentNodeHelpers.operation(
    OperationType.query,
    '',
    selections: [
      DocumentNodeHelpers.field('pokemon', args: {
        'name': 'Pikachu'
      }, selections: [
        DocumentNodeHelpers.fragmentSpread('Pokemon'),
        DocumentNodeHelpers.field('evolutions', selections: [
          DocumentNodeHelpers.fragmentSpread('Pokemon'),
        ]),
      ]),
    ],
  ),
  DocumentNodeHelpers.fragmentDefinition(
    'Pokemon',
    'Pokemon',
    selections: [
      DocumentNodeHelpers.field('id'),
      DocumentNodeHelpers.field('weight', selections: [
        DocumentNodeHelpers.fragmentSpread('weight'),
      ]),
      DocumentNodeHelpers.field('attacks', selections: [
        DocumentNodeHelpers.fragmentSpread('pokemonAttack'),
      ]),
    ],
  ),
  DocumentNodeHelpers.fragmentDefinition(
    'weight',
    'PokemonDimension',
    selections: [
      DocumentNodeHelpers.field('minimum'),
    ],
  ),
  DocumentNodeHelpers.fragmentDefinition(
    'pokemonAttack',
    'PokemonAttack',
    selections: [
      DocumentNodeHelpers.field('special', selections: [
        DocumentNodeHelpers.fragmentSpread('attack'),
      ]),
    ],
  ),
  DocumentNodeHelpers.fragmentDefinition(
    'attack',
    'Attack',
    selections: [
      DocumentNodeHelpers.field('name'),
    ],
  ),
]);

class FragmentsGlobQuery
    extends GraphQLQuery<FragmentsGlob$Query, JsonSerializable> {
  FragmentsGlobQuery();

  @override
  final DocumentNode document = FRAGMENTS_GLOB_QUERY_DOCUMENT;

  @override
  final String operationName = FRAGMENTS_GLOB_QUERY_DOCUMENT_OPERATION_NAME;

  @override
  List<Object?> get props => [document, operationName];

  @override
  FragmentsGlob$Query parse(Map<String, dynamic> json) =>
      FragmentsGlob$Query.fromJson(json);
}
