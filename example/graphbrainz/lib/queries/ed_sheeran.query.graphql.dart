// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:collection/collection.dart';
import 'package:dartpollo/dartpollo.dart';
import 'package:dartpollo/schema/graphql_data_class.dart';
import 'package:gql/ast.dart';
import 'package:json_annotation/json_annotation.dart';
part 'ed_sheeran.query.graphql.g.dart';

@JsonSerializable(explicitToJson: true)
class EdSheeran$Query$Node$Artist$ReleaseConnection$Release
    extends GraphQLDataClass {
  EdSheeran$Query$Node$Artist$ReleaseConnection$Release();

  factory EdSheeran$Query$Node$Artist$ReleaseConnection$Release.fromJson(
          Map<String, dynamic> json) =>
      _$EdSheeran$Query$Node$Artist$ReleaseConnection$ReleaseFromJson(json);

  late String id;

  String? status;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EdSheeran$Query$Node$Artist$ReleaseConnection$Release)
      return false;
    return id == other.id && status == other.status;
  }

  @override
  int get hashCode => Object.hash(id.hashCode, status.hashCode);

  @override
  String toString() =>
      'EdSheeran\$Query\$Node\$Artist\$ReleaseConnection\$Release(id: $id, status: $status)';

  @override
  Map<String, dynamic> toJson() =>
      _$EdSheeran$Query$Node$Artist$ReleaseConnection$ReleaseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class EdSheeran$Query$Node$Artist$ReleaseConnection extends GraphQLDataClass {
  EdSheeran$Query$Node$Artist$ReleaseConnection();

  factory EdSheeran$Query$Node$Artist$ReleaseConnection.fromJson(
          Map<String, dynamic> json) =>
      _$EdSheeran$Query$Node$Artist$ReleaseConnectionFromJson(json);

  List<EdSheeran$Query$Node$Artist$ReleaseConnection$Release?>? nodes;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EdSheeran$Query$Node$Artist$ReleaseConnection) return false;
    return const DeepCollectionEquality().equals(nodes, other.nodes);
  }

  @override
  int get hashCode => const DeepCollectionEquality().hash(nodes);

  @override
  String toString() =>
      'EdSheeran\$Query\$Node\$Artist\$ReleaseConnection(nodes: ${nodes?.length ?? 0} items)';

  @override
  Map<String, dynamic> toJson() =>
      _$EdSheeran$Query$Node$Artist$ReleaseConnectionToJson(this);
}

@JsonSerializable(explicitToJson: true)
class EdSheeran$Query$Node$Artist$LifeSpan extends GraphQLDataClass {
  EdSheeran$Query$Node$Artist$LifeSpan();

  factory EdSheeran$Query$Node$Artist$LifeSpan.fromJson(
          Map<String, dynamic> json) =>
      _$EdSheeran$Query$Node$Artist$LifeSpanFromJson(json);

  DateTime? begin;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EdSheeran$Query$Node$Artist$LifeSpan) return false;
    return begin == other.begin;
  }

  @override
  int get hashCode => begin.hashCode;

  @override
  String toString() =>
      'EdSheeran\$Query\$Node\$Artist\$LifeSpan(begin: $begin)';

  @override
  Map<String, dynamic> toJson() =>
      _$EdSheeran$Query$Node$Artist$LifeSpanToJson(this);
}

@JsonSerializable(explicitToJson: true)
class EdSheeran$Query$Node$Artist$SpotifyArtist extends GraphQLDataClass {
  EdSheeran$Query$Node$Artist$SpotifyArtist();

  factory EdSheeran$Query$Node$Artist$SpotifyArtist.fromJson(
          Map<String, dynamic> json) =>
      _$EdSheeran$Query$Node$Artist$SpotifyArtistFromJson(json);

  late String href;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EdSheeran$Query$Node$Artist$SpotifyArtist) return false;
    return href == other.href;
  }

  @override
  int get hashCode => href.hashCode;

  @override
  String toString() =>
      'EdSheeran\$Query\$Node\$Artist\$SpotifyArtist(href: $href)';

  @override
  Map<String, dynamic> toJson() =>
      _$EdSheeran$Query$Node$Artist$SpotifyArtistToJson(this);
}

@JsonSerializable(explicitToJson: true)
class EdSheeran$Query$Node$Artist extends EdSheeran$Query$Node {
  EdSheeran$Query$Node$Artist();

  factory EdSheeran$Query$Node$Artist.fromJson(Map<String, dynamic> json) =>
      _$EdSheeran$Query$Node$ArtistFromJson(json);

  late String mbid;

  String? name;

  EdSheeran$Query$Node$Artist$ReleaseConnection? releases;

  EdSheeran$Query$Node$Artist$LifeSpan? lifeSpan;

  EdSheeran$Query$Node$Artist$SpotifyArtist? spotify;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EdSheeran$Query$Node$Artist) return false;
    return mbid == other.mbid &&
        lifeSpan == other.lifeSpan &&
        name == other.name &&
        releases == other.releases &&
        spotify == other.spotify;
  }

  @override
  int get hashCode => Object.hash(mbid.hashCode, name.hashCode,
      releases.hashCode, lifeSpan.hashCode, spotify.hashCode);

  @override
  String toString() =>
      'EdSheeran\$Query\$Node\$Artist(mbid: $mbid, lifeSpan: $lifeSpan, name: $name, releases: $releases, spotify: $spotify)';

  @override
  Map<String, dynamic> toJson() => _$EdSheeran$Query$Node$ArtistToJson(this);
}

@JsonSerializable(explicitToJson: true)
class EdSheeran$Query$Node extends GraphQLDataClass {
  EdSheeran$Query$Node();

  factory EdSheeran$Query$Node.fromJson(Map<String, dynamic> json) =>
      _$EdSheeran$Query$NodeFromJson(json);

  @JsonKey(name: '__typename')
  String? $$typename;

  late String id;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EdSheeran$Query$Node) return false;
    return id == other.id && $$typename == other.$$typename;
  }

  @override
  int get hashCode => Object.hash($$typename.hashCode, id.hashCode);

  @override
  String toString() =>
      'EdSheeran\$Query\$Node(id: $id, \$\$typename: ' +
      $$typename.toString() +
      ')';

  @override
  Map<String, dynamic> toJson() {
    switch ($$typename) {
      case r'Artist':
        return (this as EdSheeran$Query$Node$Artist).toJson();
      default:
    }
    return _$EdSheeran$Query$NodeToJson(this);
  }
}

@JsonSerializable(explicitToJson: true)
class EdSheeran$Query extends GraphQLDataClass {
  EdSheeran$Query();

  factory EdSheeran$Query.fromJson(Map<String, dynamic> json) =>
      _$EdSheeran$QueryFromJson(json);

  EdSheeran$Query$Node? node;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EdSheeran$Query) return false;
    return node == other.node;
  }

  @override
  int get hashCode => node.hashCode;

  @override
  String toString() => 'EdSheeran\$Query(node: $node)';

  @override
  Map<String, dynamic> toJson() => _$EdSheeran$QueryToJson(this);
}

final ED_SHEERAN_QUERY_DOCUMENT_OPERATION_NAME = 'ed_sheeran';
final ED_SHEERAN_QUERY_DOCUMENT = DocumentNode(definitions: [
  OperationDefinitionNode(
    type: OperationType.query,
    name: NameNode(value: 'ed_sheeran'),
    variableDefinitions: [],
    directives: [],
    selectionSet: SelectionSetNode(selections: [
      FieldNode(
        name: NameNode(value: 'node'),
        alias: null,
        arguments: [
          ArgumentNode(
            name: NameNode(value: 'id'),
            value: StringValueNode(
              value:
                  'QXJ0aXN0OmI4YTdjNTFmLTM2MmMtNGRjYi1hMjU5LWJjNmUwMDk1ZjBhNg==',
              isBlock: false,
            ),
          )
        ],
        directives: [],
        selectionSet: SelectionSetNode(selections: [
          FieldNode(
            name: NameNode(value: '__typename'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
          FieldNode(
            name: NameNode(value: 'id'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
          InlineFragmentNode(
            typeCondition: TypeConditionNode(
                on: NamedTypeNode(
              name: NameNode(value: 'Artist'),
              isNonNull: false,
            )),
            directives: [],
            selectionSet: SelectionSetNode(selections: [
              FieldNode(
                name: NameNode(value: 'mbid'),
                alias: null,
                arguments: [],
                directives: [],
                selectionSet: null,
              ),
              FieldNode(
                name: NameNode(value: 'name'),
                alias: null,
                arguments: [],
                directives: [],
                selectionSet: null,
              ),
              FieldNode(
                name: NameNode(value: 'releases'),
                alias: null,
                arguments: [],
                directives: [],
                selectionSet: SelectionSetNode(selections: [
                  FieldNode(
                    name: NameNode(value: 'nodes'),
                    alias: null,
                    arguments: [],
                    directives: [],
                    selectionSet: SelectionSetNode(selections: [
                      FieldNode(
                        name: NameNode(value: 'id'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                      FieldNode(
                        name: NameNode(value: 'status'),
                        alias: null,
                        arguments: [],
                        directives: [],
                        selectionSet: null,
                      ),
                    ]),
                  )
                ]),
              ),
              FieldNode(
                name: NameNode(value: 'lifeSpan'),
                alias: null,
                arguments: [],
                directives: [],
                selectionSet: SelectionSetNode(selections: [
                  FieldNode(
                    name: NameNode(value: 'begin'),
                    alias: null,
                    arguments: [],
                    directives: [],
                    selectionSet: null,
                  )
                ]),
              ),
              FieldNode(
                name: NameNode(value: 'spotify'),
                alias: null,
                arguments: [],
                directives: [],
                selectionSet: SelectionSetNode(selections: [
                  FieldNode(
                    name: NameNode(value: 'href'),
                    alias: null,
                    arguments: [],
                    directives: [],
                    selectionSet: null,
                  )
                ]),
              ),
            ]),
          ),
        ]),
      )
    ]),
  )
]);

class EdSheeranQuery extends GraphQLQuery<EdSheeran$Query, JsonSerializable> {
  EdSheeranQuery();

  @override
  final DocumentNode document = ED_SHEERAN_QUERY_DOCUMENT;

  @override
  final String operationName = ED_SHEERAN_QUERY_DOCUMENT_OPERATION_NAME;

  @override
  List<Object?> get props => [document, operationName];

  @override
  EdSheeran$Query parse(Map<String, dynamic> json) =>
      EdSheeran$Query.fromJson(json);
}
