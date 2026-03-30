import 'package:dartpollo_generator/generator/data/data.dart';
import 'package:test/test.dart';

import '../../helpers.dart';

void main() {
  test(
    'On union with nested types',
    () => testGenerator(
      query: query,
      schema: graphQLSchema,
      libraryDefinition: libraryDefinition,
      generatedFile: generatedFile,
    ),
  );
}

const String query = r'''
  query checkoutById($checkoutId: ID!) {
    node(id: $checkoutId) {
        __typename
        ...on Checkout {
            id
            lineItems {
                id
                edges {
                    edges {
                        id
                    }
                }
            }
        }
    }
}
''';

const String graphQLSchema = '''
  schema {
    query: QueryRoot
  }
  
  interface Node {
      id: ID!
  }
  
  type Checkout implements Node {
      id: ID!
      lineItems: CheckoutLineItemConnection!
  }
  
  type CheckoutLineItem implements Node {
      id: ID!
  }
  
  type CheckoutLineItemConnection {
      id: ID!
      edges: [CheckoutLineItemEdge!]!
  }
  
  type CheckoutLineItemEdge {
      id: ID!
      edges: [ImageConnection]
      node: CheckoutLineItem!
  }
  
  type Image {
      id: ID
  }
  
  type ImageConnection {
      id: ID
      edges: [ImageEdge!]!
  }
  
  type ImageEdge {
      id: ID!
      node: Image!
  }
  
  type QueryRoot {
      node(
          id: ID!
      ): Node
  }
''';

final LibraryDefinition libraryDefinition = LibraryDefinition(
  basename: r'query.graphql',
  queries: [
    QueryDefinition(
      name: QueryName(name: r'CheckoutById$_QueryRoot'),
      operationName: r'checkoutById',
      classes: [
        ClassDefinition(
          name: ClassName(
            name:
                r'CheckoutById$_QueryRoot$_Node$_Checkout$_CheckoutLineItemConnection$_CheckoutLineItemEdge$_ImageConnection',
          ),
          properties: [
            ClassProperty(
              type: DartTypeName(name: r'String'),
              name: const ClassPropertyName(name: r'id'),
            ),
          ],
          typeNameField: const ClassPropertyName(name: r'__typename'),
        ),
        ClassDefinition(
          name: ClassName(
            name:
                r'CheckoutById$_QueryRoot$_Node$_Checkout$_CheckoutLineItemConnection$_CheckoutLineItemEdge',
          ),
          properties: [
            ClassProperty(
              type: ListOfTypeName(
                typeName: TypeName(
                  name:
                      r'CheckoutById$_QueryRoot$_Node$_Checkout$_CheckoutLineItemConnection$_CheckoutLineItemEdge$_ImageConnection',
                ),
                isNonNull: false,
              ),
              name: const ClassPropertyName(name: r'edges'),
            ),
          ],
          typeNameField: const ClassPropertyName(name: r'__typename'),
        ),
        ClassDefinition(
          name: ClassName(
            name:
                r'CheckoutById$_QueryRoot$_Node$_Checkout$_CheckoutLineItemConnection',
          ),
          properties: [
            ClassProperty(
              type: DartTypeName(name: r'String', isNonNull: true),
              name: const ClassPropertyName(name: r'id'),
            ),
            ClassProperty(
              type: ListOfTypeName(
                typeName: TypeName(
                  name:
                      r'CheckoutById$_QueryRoot$_Node$_Checkout$_CheckoutLineItemConnection$_CheckoutLineItemEdge',
                  isNonNull: true,
                ),
              ),
              name: const ClassPropertyName(name: r'edges'),
            ),
          ],
          typeNameField: const ClassPropertyName(name: r'__typename'),
        ),
        ClassDefinition(
          name: ClassName(name: r'CheckoutById$_QueryRoot$_Node$_Checkout'),
          properties: [
            ClassProperty(
              type: DartTypeName(name: r'String', isNonNull: true),
              name: const ClassPropertyName(name: r'id'),
            ),
            ClassProperty(
              type: TypeName(
                name:
                    r'CheckoutById$_QueryRoot$_Node$_Checkout$_CheckoutLineItemConnection',
                isNonNull: true,
              ),
              name: const ClassPropertyName(name: r'lineItems'),
            ),
          ],
          extension: ClassName(name: r'CheckoutById$_QueryRoot$_Node'),
          typeNameField: const ClassPropertyName(name: r'__typename'),
        ),
        ClassDefinition(
          name: ClassName(name: r'CheckoutById$_QueryRoot$_Node'),
          properties: [
            ClassProperty(
              type: TypeName(name: r'String'),
              name: const ClassPropertyName(name: r'__typename'),
              annotations: const [r'''JsonKey(name: '__typename')'''],
              isResolveType: true,
            ),
          ],
          factoryPossibilities: {
            r'Checkout': ClassName(
              name: r'CheckoutById$_QueryRoot$_Node$_Checkout',
            ),
          },
          typeNameField: const ClassPropertyName(name: r'__typename'),
        ),
        ClassDefinition(
          name: ClassName(name: r'CheckoutById$_QueryRoot'),
          properties: [
            ClassProperty(
              type: TypeName(name: r'CheckoutById$_QueryRoot$_Node'),
              name: const ClassPropertyName(name: r'node'),
            ),
          ],
          typeNameField: const ClassPropertyName(name: r'__typename'),
        ),
      ],
      inputs: [
        QueryInput(
          type: DartTypeName(name: r'String', isNonNull: true),
          name: const QueryInputName(name: r'checkoutId'),
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
class CheckoutById$QueryRoot$Node$Checkout$CheckoutLineItemConnection$CheckoutLineItemEdge$ImageConnection
    extends JsonSerializable with EquatableMixin {
  CheckoutById$QueryRoot$Node$Checkout$CheckoutLineItemConnection$CheckoutLineItemEdge$ImageConnection();

  factory CheckoutById$QueryRoot$Node$Checkout$CheckoutLineItemConnection$CheckoutLineItemEdge$ImageConnection.fromJson(
          Map<String, dynamic> json) =>
      _$CheckoutById$QueryRoot$Node$Checkout$CheckoutLineItemConnection$CheckoutLineItemEdge$ImageConnectionFromJson(
          json);

  String? id;

  @override
  List<Object?> get props => [id];
  @override
  Map<String, dynamic> toJson() =>
      _$CheckoutById$QueryRoot$Node$Checkout$CheckoutLineItemConnection$CheckoutLineItemEdge$ImageConnectionToJson(
          this);
}

@JsonSerializable(explicitToJson: true)
class CheckoutById$QueryRoot$Node$Checkout$CheckoutLineItemConnection$CheckoutLineItemEdge
    extends JsonSerializable with EquatableMixin {
  CheckoutById$QueryRoot$Node$Checkout$CheckoutLineItemConnection$CheckoutLineItemEdge();

  factory CheckoutById$QueryRoot$Node$Checkout$CheckoutLineItemConnection$CheckoutLineItemEdge.fromJson(
          Map<String, dynamic> json) =>
      _$CheckoutById$QueryRoot$Node$Checkout$CheckoutLineItemConnection$CheckoutLineItemEdgeFromJson(
          json);

  List<CheckoutById$QueryRoot$Node$Checkout$CheckoutLineItemConnection$CheckoutLineItemEdge$ImageConnection?>?
      edges;

  @override
  List<Object?> get props => [edges];
  @override
  Map<String, dynamic> toJson() =>
      _$CheckoutById$QueryRoot$Node$Checkout$CheckoutLineItemConnection$CheckoutLineItemEdgeToJson(
          this);
}

@JsonSerializable(explicitToJson: true)
class CheckoutById$QueryRoot$Node$Checkout$CheckoutLineItemConnection
    extends JsonSerializable with EquatableMixin {
  CheckoutById$QueryRoot$Node$Checkout$CheckoutLineItemConnection();

  factory CheckoutById$QueryRoot$Node$Checkout$CheckoutLineItemConnection.fromJson(
          Map<String, dynamic> json) =>
      _$CheckoutById$QueryRoot$Node$Checkout$CheckoutLineItemConnectionFromJson(
          json);

  late String id;

  late List<
          CheckoutById$QueryRoot$Node$Checkout$CheckoutLineItemConnection$CheckoutLineItemEdge>
      edges;

  @override
  List<Object?> get props => [id, edges];
  @override
  Map<String, dynamic> toJson() =>
      _$CheckoutById$QueryRoot$Node$Checkout$CheckoutLineItemConnectionToJson(
          this);
}

@JsonSerializable(explicitToJson: true)
class CheckoutById$QueryRoot$Node$Checkout extends CheckoutById$QueryRoot$Node
    with EquatableMixin {
  CheckoutById$QueryRoot$Node$Checkout();

  factory CheckoutById$QueryRoot$Node$Checkout.fromJson(
          Map<String, dynamic> json) =>
      _$CheckoutById$QueryRoot$Node$CheckoutFromJson(json);

  late String id;

  late CheckoutById$QueryRoot$Node$Checkout$CheckoutLineItemConnection
      lineItems;

  @override
  List<Object?> get props => [id, lineItems];
  @override
  Map<String, dynamic> toJson() =>
      _$CheckoutById$QueryRoot$Node$CheckoutToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CheckoutById$QueryRoot$Node extends JsonSerializable with EquatableMixin {
  CheckoutById$QueryRoot$Node();

  factory CheckoutById$QueryRoot$Node.fromJson(Map<String, dynamic> json) {
    switch (json['__typename'].toString()) {
      case r'Checkout':
        return CheckoutById$QueryRoot$Node$Checkout.fromJson(json);
      default:
    }
    return _$CheckoutById$QueryRoot$NodeFromJson(json);
  }

  @JsonKey(name: '__typename')
  String? $$typename;

  @override
  List<Object?> get props => [$$typename];
  @override
  Map<String, dynamic> toJson() {
    switch ($$typename) {
      case r'Checkout':
        return (this as CheckoutById$QueryRoot$Node$Checkout).toJson();
      default:
    }
    return _$CheckoutById$QueryRoot$NodeToJson(this);
  }
}

@JsonSerializable(explicitToJson: true)
class CheckoutById$QueryRoot extends JsonSerializable with EquatableMixin {
  CheckoutById$QueryRoot();

  factory CheckoutById$QueryRoot.fromJson(Map<String, dynamic> json) =>
      _$CheckoutById$QueryRootFromJson(json);

  CheckoutById$QueryRoot$Node? node;

  @override
  List<Object?> get props => [node];
  @override
  Map<String, dynamic> toJson() => _$CheckoutById$QueryRootToJson(this);
}
''';
