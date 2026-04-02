// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'viewer.graphql.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Viewer$Query$User _$Viewer$Query$UserFromJson(Map<String, dynamic> json) =>
    Viewer$Query$User()..login = json['login'] as String;

Map<String, dynamic> _$Viewer$Query$UserToJson(Viewer$Query$User instance) =>
    <String, dynamic>{
      'login': instance.login,
    };

Viewer$Query _$Viewer$QueryFromJson(Map<String, dynamic> json) => Viewer$Query()
  ..viewer = Viewer$Query$User.fromJson(json['viewer'] as Map<String, dynamic>);

Map<String, dynamic> _$Viewer$QueryToJson(Viewer$Query instance) =>
    <String, dynamic>{
      'viewer': instance.viewer.toJson(),
    };
