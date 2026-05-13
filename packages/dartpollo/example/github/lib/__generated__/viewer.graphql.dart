// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

// dart format off
import 'package:dartpollo/dartpollo.dart';import 'package:equatable/equatable.dart';import 'package:gql/ast.dart';import 'package:json_annotation/json_annotation.dart';part 'viewer.graphql.g.dart';@JsonSerializable(explicitToJson: true) class Viewer$Query$User extends JsonSerializable with EquatableMixin {Viewer$Query$User();

factory Viewer$Query$User.fromJson(Map<String, dynamic> json) => _$Viewer$Query$UserFromJson(json);

late String login;

@override List<Object?> get props => [login];

@override Map<String, dynamic> toJson() => _$Viewer$Query$UserToJson(this);

 }
@JsonSerializable(explicitToJson: true) class Viewer$Query extends JsonSerializable with EquatableMixin {Viewer$Query();

factory Viewer$Query.fromJson(Map<String, dynamic> json) => _$Viewer$QueryFromJson(json);

late Viewer$Query$User viewer;

@override List<Object?> get props => [viewer];

@override Map<String, dynamic> toJson() => _$Viewer$QueryToJson(this);

 }
final VIEWER_QUERY_DOCUMENT_OPERATION_NAME = 'Viewer';
final VIEWER_QUERY_DOCUMENT = 
DocumentNode(definitions: [OperationDefinitionNode(type: OperationType.query, name: NameNode(value: 'Viewer'), variableDefinitions: [], directives: [], selectionSet: SelectionSetNode(selections: [FieldNode(name: NameNode(value: 'viewer'), alias: null, arguments: [], directives: [], selectionSet: SelectionSetNode(selections: [FieldNode(name: NameNode(value: 'login'), alias: null, arguments: [], directives: [], selectionSet: null, )]), )]), )])
;class ViewerQuery extends GraphQLQuery<Viewer$Query, JsonSerializable> {ViewerQuery();

@override final DocumentNode document = VIEWER_QUERY_DOCUMENT;

@override final String operationName = VIEWER_QUERY_DOCUMENT_OPERATION_NAME;

@override List<Object?> get props => [document, operationName];

@override Viewer$Query parse(Map<String, dynamic> json) => Viewer$Query.fromJson(json);

 }
