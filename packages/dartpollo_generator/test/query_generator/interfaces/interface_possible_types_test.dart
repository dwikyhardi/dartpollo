import 'package:dartpollo_generator/generator/data/data.dart';
import 'package:test/test.dart';

import '../../helpers.dart';

void main() {
  group('On types not used by interfaces', () {
    test(
      'Those other types are not considered nor generated',
      () => testGenerator(
        query: query,
        schema: graphQLSchema,
        libraryDefinition: libraryDefinition,
        generatedFile: generatedFile,
      ),
    );
  });
}

const query = r'''
  query custom($id: ID!) {
    nodeById(id: $id) {
      id
      __typename
      ... on User {
        username
      }
      ... on ChatMessage {
        message
      }
    }
  }
''';

// https://graphql-code-generator.com/#live-demo
const graphQLSchema = '''
  scalar String
  scalar ID
  
  schema {
    query: Query
  }
  
  type Query {
    nodeById(id: ID!): Node
  }
  
  interface Node {
    id: ID!
  }
  
  type User implements Node {
    id: ID!
    username: String!
  }
  
  type OtherEntity implements Node {
    id: ID!
    test: String!
  }
  
  type ChatMessage implements Node {
    id: ID!
    message: String!
    user: User!
  }
''';

final LibraryDefinition libraryDefinition = LibraryDefinition(
  basename: r'**.graphql',
  queries: [
    QueryDefinition(
      name: QueryName(name: r'Custom$_Query'),
      operationName: r'custom',
      classes: [
        ClassDefinition(
          name: ClassName(name: r'Custom$_Query$_Node$_User'),
          properties: [
            ClassProperty(
              type: DartTypeName(name: r'String', isNonNull: true),
              name: const ClassPropertyName(name: r'username'),
            ),
          ],
          extension: ClassName(name: r'Custom$_Query$_Node'),
          typeNameField: const ClassPropertyName(name: r'__typename'),
        ),
        ClassDefinition(
          name: ClassName(name: r'Custom$_Query$_Node$_ChatMessage'),
          properties: [
            ClassProperty(
              type: DartTypeName(name: r'String', isNonNull: true),
              name: const ClassPropertyName(name: r'message'),
            ),
          ],
          extension: ClassName(name: r'Custom$_Query$_Node'),
          typeNameField: const ClassPropertyName(name: r'__typename'),
        ),
        ClassDefinition(
          name: ClassName(name: r'Custom$_Query$_Node'),
          properties: [
            ClassProperty(
              type: DartTypeName(name: r'String', isNonNull: true),
              name: const ClassPropertyName(name: r'id'),
            ),
            ClassProperty(
              type: TypeName(name: r'String'),
              name: const ClassPropertyName(name: r'__typename'),
              annotations: const [r'''JsonKey(name: '__typename')'''],
              isResolveType: true,
            ),
          ],
          factoryPossibilities: {
            r'User': ClassName(name: r'Custom$_Query$_Node$_User'),
            r'ChatMessage': ClassName(
              name: r'Custom$_Query$_Node$_ChatMessage',
            ),
          },
          typeNameField: const ClassPropertyName(name: r'__typename'),
        ),
        ClassDefinition(
          name: ClassName(name: r'Custom$_Query'),
          properties: [
            ClassProperty(
              type: TypeName(name: r'Custom$_Query$_Node'),
              name: const ClassPropertyName(name: r'nodeById'),
            ),
          ],
          typeNameField: const ClassPropertyName(name: r'__typename'),
        ),
      ],
      inputs: [
        QueryInput(
          type: DartTypeName(name: r'String', isNonNull: true),
          name: const QueryInputName(name: r'id'),
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
class Custom$Query$Node$User extends Custom$Query$Node with EquatableMixin {
  Custom$Query$Node$User();

  factory Custom$Query$Node$User.fromJson(Map<String, dynamic> json) =>
      _$Custom$Query$Node$UserFromJson(json);

  late String username;

  @override
  List<Object?> get props => [username];
  @override
  Map<String, dynamic> toJson() => _$Custom$Query$Node$UserToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Custom$Query$Node$ChatMessage extends Custom$Query$Node
    with EquatableMixin {
  Custom$Query$Node$ChatMessage();

  factory Custom$Query$Node$ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$Custom$Query$Node$ChatMessageFromJson(json);

  late String message;

  @override
  List<Object?> get props => [message];
  @override
  Map<String, dynamic> toJson() => _$Custom$Query$Node$ChatMessageToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Custom$Query$Node extends JsonSerializable with EquatableMixin {
  Custom$Query$Node();

  factory Custom$Query$Node.fromJson(Map<String, dynamic> json) {
    switch (json['__typename'].toString()) {
      case r'User':
        return Custom$Query$Node$User.fromJson(json);
      case r'ChatMessage':
        return Custom$Query$Node$ChatMessage.fromJson(json);
      default:
    }
    return _$Custom$Query$NodeFromJson(json);
  }

  late String id;

  @JsonKey(name: '__typename')
  String? $$typename;

  @override
  List<Object?> get props => [id, $$typename];
  @override
  Map<String, dynamic> toJson() {
    switch ($$typename) {
      case r'User':
        return (this as Custom$Query$Node$User).toJson();
      case r'ChatMessage':
        return (this as Custom$Query$Node$ChatMessage).toJson();
      default:
    }
    return _$Custom$Query$NodeToJson(this);
  }
}

@JsonSerializable(explicitToJson: true)
class Custom$Query extends JsonSerializable with EquatableMixin {
  Custom$Query();

  factory Custom$Query.fromJson(Map<String, dynamic> json) =>
      _$Custom$QueryFromJson(json);

  Custom$Query$Node? nodeById;

  @override
  List<Object?> get props => [nodeById];
  @override
  Map<String, dynamic> toJson() => _$Custom$QueryToJson(this);
}
''';
