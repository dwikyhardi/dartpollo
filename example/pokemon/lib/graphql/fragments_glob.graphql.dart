// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:collection/collection.dart';
import 'package:dartpollo/dartpollo.dart';
import 'package:dartpollo/generator/document_helpers.dart';
import 'package:dartpollo/schema/graphql_data_class.dart';
import 'package:gql/ast.dart';
import 'package:json_annotation/json_annotation.dart';
part 'fragments_glob.graphql.g.dart';

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
class FragmentsGlob$Query$Pokemon$Pokemon extends GraphQLDataClass
    with PokemonMixin {
  FragmentsGlob$Query$Pokemon$Pokemon();

  factory FragmentsGlob$Query$Pokemon$Pokemon.fromJson(
          Map<String, dynamic> json) =>
      _$FragmentsGlob$Query$Pokemon$PokemonFromJson(json);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FragmentsGlob$Query$Pokemon$Pokemon) return false;
    return id == other.id && attacks == other.attacks && weight == other.weight;
  }

  @override
  int get hashCode =>
      Object.hash(id.hashCode, weight.hashCode, attacks.hashCode);

  @override
  String toString() =>
      'FragmentsGlob\$Query\$Pokemon\$Pokemon(id: $id, attacks: $attacks, weight: $weight)';

  @override
  Map<String, dynamic> toJson() =>
      _$FragmentsGlob$Query$Pokemon$PokemonToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FragmentsGlob$Query$Pokemon extends GraphQLDataClass with PokemonMixin {
  FragmentsGlob$Query$Pokemon();

  factory FragmentsGlob$Query$Pokemon.fromJson(Map<String, dynamic> json) =>
      _$FragmentsGlob$Query$PokemonFromJson(json);

  List<FragmentsGlob$Query$Pokemon$Pokemon?>? evolutions;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FragmentsGlob$Query$Pokemon) return false;
    return id == other.id &&
        attacks == other.attacks &&
        const DeepCollectionEquality().equals(evolutions, other.evolutions) &&
        weight == other.weight;
  }

  @override
  int get hashCode => Object.hash(id.hashCode, weight.hashCode,
      attacks.hashCode, const DeepCollectionEquality().hash(evolutions));

  @override
  String toString() =>
      'FragmentsGlob\$Query\$Pokemon(id: $id, attacks: $attacks, evolutions: ${evolutions?.length ?? 0} items, weight: $weight)';

  @override
  Map<String, dynamic> toJson() => _$FragmentsGlob$Query$PokemonToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FragmentsGlob$Query extends GraphQLDataClass {
  FragmentsGlob$Query();

  factory FragmentsGlob$Query.fromJson(Map<String, dynamic> json) =>
      _$FragmentsGlob$QueryFromJson(json);

  FragmentsGlob$Query$Pokemon? pokemon;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FragmentsGlob$Query) return false;
    return pokemon == other.pokemon;
  }

  @override
  int get hashCode => pokemon.hashCode;

  @override
  String toString() => 'FragmentsGlob\$Query(pokemon: $pokemon)';

  @override
  Map<String, dynamic> toJson() => _$FragmentsGlob$QueryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PokemonMixin$PokemonDimension extends GraphQLDataClass with WeightMixin {
  PokemonMixin$PokemonDimension();

  factory PokemonMixin$PokemonDimension.fromJson(Map<String, dynamic> json) =>
      _$PokemonMixin$PokemonDimensionFromJson(json);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PokemonMixin$PokemonDimension) return false;
    return minimum == other.minimum;
  }

  @override
  int get hashCode => minimum.hashCode;

  @override
  String toString() => 'PokemonMixin\$PokemonDimension(minimum: $minimum)';

  @override
  Map<String, dynamic> toJson() => _$PokemonMixin$PokemonDimensionToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PokemonMixin$PokemonAttack extends GraphQLDataClass
    with PokemonAttackMixin {
  PokemonMixin$PokemonAttack();

  factory PokemonMixin$PokemonAttack.fromJson(Map<String, dynamic> json) =>
      _$PokemonMixin$PokemonAttackFromJson(json);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PokemonMixin$PokemonAttack) return false;
    return special == other.special;
  }

  @override
  int get hashCode => special.hashCode;

  @override
  String toString() => 'PokemonMixin\$PokemonAttack(special: $special)';

  @override
  Map<String, dynamic> toJson() => _$PokemonMixin$PokemonAttackToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PokemonAttackMixin$Attack extends GraphQLDataClass with AttackMixin {
  PokemonAttackMixin$Attack();

  factory PokemonAttackMixin$Attack.fromJson(Map<String, dynamic> json) =>
      _$PokemonAttackMixin$AttackFromJson(json);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PokemonAttackMixin$Attack) return false;
    return name == other.name;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'PokemonAttackMixin\$Attack(name: $name)';

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
