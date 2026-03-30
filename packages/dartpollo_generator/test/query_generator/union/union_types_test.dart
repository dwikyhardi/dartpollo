import 'package:dartpollo_generator/generator/data/data.dart';
import 'package:test/test.dart';

import '../../helpers.dart';

void main() {
  test(
    'On union types',
    () => testGenerator(
      query: query,
      schema: graphQLSchema,
      libraryDefinition: libraryDefinition,
      generatedFile: generatedFile,
    ),
  );
}

const String query = r'''
  query some_query { 
    o { 
      __typename, 
      ... on TypeA { 
        a
        _
        _a
        _a_a
        _a_a_
        _new
        __typename,
      }, 
      ... on TypeB { 
        b
        _
        _b
        _b_b
        _b_b_
        new
        IN
        __typename,
      } 
    } 
  }
''';

const String graphQLSchema = '''
  schema {
    query: SomeObject
  }

  type SomeObject {
    o: SomeUnion
  }
  
  union SomeUnion = TypeA | TypeB
  
  type TypeA {
    a: Int
    _: String
    _a: String
    _a_a: String
    _a_a_: String
    _new: String    
  }
  
  type TypeB {
    b: Int
    _: String
    _b: String
    _b_b: String
    _b_b_: String
    new: String
    IN: String
  }
''';

final LibraryDefinition libraryDefinition = LibraryDefinition(
  basename: r'query.graphql',
  queries: [
    QueryDefinition(
      name: QueryName(name: r'SomeQuery$_SomeObject'),
      operationName: r'some_query',
      classes: [
        ClassDefinition(
          name: ClassName(name: r'SomeQuery$_SomeObject$_SomeUnion$_TypeA'),
          properties: [
            ClassProperty(
              type: DartTypeName(name: r'int'),
              name: const ClassPropertyName(name: r'a'),
            ),
            ClassProperty(
              type: DartTypeName(name: r'String'),
              name: const ClassPropertyName(name: r'_'),
              annotations: const [r'''JsonKey(name: '_')'''],
            ),
            ClassProperty(
              type: DartTypeName(name: r'String'),
              name: const ClassPropertyName(name: r'_a'),
              annotations: const [r'''JsonKey(name: '_a')'''],
            ),
            ClassProperty(
              type: DartTypeName(name: r'String'),
              name: const ClassPropertyName(name: r'_a_a'),
              annotations: const [r'''JsonKey(name: '_a_a')'''],
            ),
            ClassProperty(
              type: DartTypeName(name: r'String'),
              name: const ClassPropertyName(name: r'_a_a_'),
              annotations: const [r'''JsonKey(name: '_a_a_')'''],
            ),
            ClassProperty(
              type: DartTypeName(name: r'String'),
              name: const ClassPropertyName(name: r'_new'),
              annotations: const [r'''JsonKey(name: '_new')'''],
            ),
            ClassProperty(
              type: TypeName(name: r'String'),
              name: const ClassPropertyName(name: r'__typename'),
              annotations: const [r'''JsonKey(name: '__typename')'''],
              isResolveType: true,
            ),
          ],
          extension: ClassName(name: r'SomeQuery$_SomeObject$_SomeUnion'),
          typeNameField: const ClassPropertyName(name: r'__typename'),
        ),
        ClassDefinition(
          name: ClassName(name: r'SomeQuery$_SomeObject$_SomeUnion$_TypeB'),
          properties: [
            ClassProperty(
              type: DartTypeName(name: r'int'),
              name: const ClassPropertyName(name: r'b'),
            ),
            ClassProperty(
              type: DartTypeName(name: r'String'),
              name: const ClassPropertyName(name: r'_'),
              annotations: const [r'''JsonKey(name: '_')'''],
            ),
            ClassProperty(
              type: DartTypeName(name: r'String'),
              name: const ClassPropertyName(name: r'_b'),
              annotations: const [r'''JsonKey(name: '_b')'''],
            ),
            ClassProperty(
              type: DartTypeName(name: r'String'),
              name: const ClassPropertyName(name: r'_b_b'),
              annotations: const [r'''JsonKey(name: '_b_b')'''],
            ),
            ClassProperty(
              type: DartTypeName(name: r'String'),
              name: const ClassPropertyName(name: r'_b_b_'),
              annotations: const [r'''JsonKey(name: '_b_b_')'''],
            ),
            ClassProperty(
              type: DartTypeName(name: r'String'),
              name: const ClassPropertyName(name: r'new'),
              annotations: const [r'''JsonKey(name: 'new')'''],
            ),
            ClassProperty(
              type: DartTypeName(name: r'String'),
              name: const ClassPropertyName(name: r'IN'),
              annotations: const [r'''JsonKey(name: 'IN')'''],
            ),
            ClassProperty(
              type: TypeName(name: r'String'),
              name: const ClassPropertyName(name: r'__typename'),
              annotations: const [r'''JsonKey(name: '__typename')'''],
              isResolveType: true,
            ),
          ],
          extension: ClassName(name: r'SomeQuery$_SomeObject$_SomeUnion'),
          typeNameField: const ClassPropertyName(name: r'__typename'),
        ),
        ClassDefinition(
          name: ClassName(name: r'SomeQuery$_SomeObject$_SomeUnion'),
          properties: [
            ClassProperty(
              type: TypeName(name: r'String'),
              name: const ClassPropertyName(name: r'__typename'),
              annotations: const [r'''JsonKey(name: '__typename')'''],
              isResolveType: true,
            ),
          ],
          factoryPossibilities: {
            r'TypeA': ClassName(
              name: r'SomeQuery$_SomeObject$_SomeUnion$_TypeA',
            ),
            r'TypeB': ClassName(
              name: r'SomeQuery$_SomeObject$_SomeUnion$_TypeB',
            ),
          },
          typeNameField: const ClassPropertyName(name: r'__typename'),
        ),
        ClassDefinition(
          name: ClassName(name: r'SomeQuery$_SomeObject'),
          properties: [
            ClassProperty(
              type: TypeName(name: r'SomeQuery$_SomeObject$_SomeUnion'),
              name: const ClassPropertyName(name: r'o'),
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
class SomeQuery$SomeObject$SomeUnion$TypeA
    extends SomeQuery$SomeObject$SomeUnion with EquatableMixin {
  SomeQuery$SomeObject$SomeUnion$TypeA();

  factory SomeQuery$SomeObject$SomeUnion$TypeA.fromJson(
          Map<String, dynamic> json) =>
      _$SomeQuery$SomeObject$SomeUnion$TypeAFromJson(json);

  int? a;

  @JsonKey(name: '_')
  String? $;

  @JsonKey(name: '_a')
  String? $a;

  @JsonKey(name: '_a_a')
  String? $aA;

  @JsonKey(name: '_a_a_')
  String? $aA_;

  @JsonKey(name: '_new')
  String? $new;

  @JsonKey(name: '__typename')
  @override
  String? $$typename;

  @override
  List<Object?> get props => [a, $, $a, $aA, $aA_, $new, $$typename];
  @override
  Map<String, dynamic> toJson() =>
      _$SomeQuery$SomeObject$SomeUnion$TypeAToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SomeQuery$SomeObject$SomeUnion$TypeB
    extends SomeQuery$SomeObject$SomeUnion with EquatableMixin {
  SomeQuery$SomeObject$SomeUnion$TypeB();

  factory SomeQuery$SomeObject$SomeUnion$TypeB.fromJson(
          Map<String, dynamic> json) =>
      _$SomeQuery$SomeObject$SomeUnion$TypeBFromJson(json);

  int? b;

  @JsonKey(name: '_')
  String? $;

  @JsonKey(name: '_b')
  String? $b;

  @JsonKey(name: '_b_b')
  String? $bB;

  @JsonKey(name: '_b_b_')
  String? $bB_;

  @JsonKey(name: 'new')
  String? kw$new;

  @JsonKey(name: 'IN')
  String? kw$IN;

  @JsonKey(name: '__typename')
  @override
  String? $$typename;

  @override
  List<Object?> get props => [b, $, $b, $bB, $bB_, kw$new, kw$IN, $$typename];
  @override
  Map<String, dynamic> toJson() =>
      _$SomeQuery$SomeObject$SomeUnion$TypeBToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SomeQuery$SomeObject$SomeUnion extends JsonSerializable
    with EquatableMixin {
  SomeQuery$SomeObject$SomeUnion();

  factory SomeQuery$SomeObject$SomeUnion.fromJson(Map<String, dynamic> json) {
    switch (json['__typename'].toString()) {
      case r'TypeA':
        return SomeQuery$SomeObject$SomeUnion$TypeA.fromJson(json);
      case r'TypeB':
        return SomeQuery$SomeObject$SomeUnion$TypeB.fromJson(json);
      default:
    }
    return _$SomeQuery$SomeObject$SomeUnionFromJson(json);
  }

  @JsonKey(name: '__typename')
  String? $$typename;

  @override
  List<Object?> get props => [$$typename];
  @override
  Map<String, dynamic> toJson() {
    switch ($$typename) {
      case r'TypeA':
        return (this as SomeQuery$SomeObject$SomeUnion$TypeA).toJson();
      case r'TypeB':
        return (this as SomeQuery$SomeObject$SomeUnion$TypeB).toJson();
      default:
    }
    return _$SomeQuery$SomeObject$SomeUnionToJson(this);
  }
}

@JsonSerializable(explicitToJson: true)
class SomeQuery$SomeObject extends JsonSerializable with EquatableMixin {
  SomeQuery$SomeObject();

  factory SomeQuery$SomeObject.fromJson(Map<String, dynamic> json) =>
      _$SomeQuery$SomeObjectFromJson(json);

  SomeQuery$SomeObject$SomeUnion? o;

  @override
  List<Object?> get props => [o];
  @override
  Map<String, dynamic> toJson() => _$SomeQuery$SomeObjectToJson(this);
}
''';
