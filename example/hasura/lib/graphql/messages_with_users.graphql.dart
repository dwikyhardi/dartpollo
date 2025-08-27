// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:collection/collection.dart';
import 'package:dartpollo/dartpollo.dart';
import 'package:dartpollo/schema/graphql_data_class.dart';
import 'package:gql/ast.dart';
import 'package:json_annotation/json_annotation.dart';
part 'messages_with_users.graphql.g.dart';

@JsonSerializable(explicitToJson: true)
class MessagesWithUsers$SubscriptionRoot$Messages$Profile
    extends GraphQLDataClass {
  MessagesWithUsers$SubscriptionRoot$Messages$Profile();

  factory MessagesWithUsers$SubscriptionRoot$Messages$Profile.fromJson(
          Map<String, dynamic> json) =>
      _$MessagesWithUsers$SubscriptionRoot$Messages$ProfileFromJson(json);

  late int id;

  late String name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MessagesWithUsers$SubscriptionRoot$Messages$Profile)
      return false;
    return id == other.id && name == other.name;
  }

  @override
  int get hashCode => Object.hash(id.hashCode, name.hashCode);

  @override
  String toString() =>
      'MessagesWithUsers\$SubscriptionRoot\$Messages\$Profile(id: $id, name: $name)';

  @override
  Map<String, dynamic> toJson() =>
      _$MessagesWithUsers$SubscriptionRoot$Messages$ProfileToJson(this);
}

@JsonSerializable(explicitToJson: true)
class MessagesWithUsers$SubscriptionRoot$Messages extends GraphQLDataClass {
  MessagesWithUsers$SubscriptionRoot$Messages();

  factory MessagesWithUsers$SubscriptionRoot$Messages.fromJson(
          Map<String, dynamic> json) =>
      _$MessagesWithUsers$SubscriptionRoot$MessagesFromJson(json);

  late int id;

  late String message;

  late MessagesWithUsers$SubscriptionRoot$Messages$Profile profile;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MessagesWithUsers$SubscriptionRoot$Messages) return false;
    return id == other.id &&
        message == other.message &&
        profile == other.profile;
  }

  @override
  int get hashCode =>
      Object.hash(id.hashCode, message.hashCode, profile.hashCode);

  @override
  String toString() =>
      'MessagesWithUsers\$SubscriptionRoot\$Messages(id: $id, message: $message, profile: $profile)';

  @override
  Map<String, dynamic> toJson() =>
      _$MessagesWithUsers$SubscriptionRoot$MessagesToJson(this);
}

@JsonSerializable(explicitToJson: true)
class MessagesWithUsers$SubscriptionRoot extends GraphQLDataClass {
  MessagesWithUsers$SubscriptionRoot();

  factory MessagesWithUsers$SubscriptionRoot.fromJson(
          Map<String, dynamic> json) =>
      _$MessagesWithUsers$SubscriptionRootFromJson(json);

  late List<MessagesWithUsers$SubscriptionRoot$Messages> messages;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MessagesWithUsers$SubscriptionRoot) return false;
    return const DeepCollectionEquality().equals(messages, other.messages);
  }

  @override
  int get hashCode => const DeepCollectionEquality().hash(messages);

  @override
  String toString() =>
      'MessagesWithUsers\$SubscriptionRoot(messages: ${messages?.length ?? 0} items)';

  @override
  Map<String, dynamic> toJson() =>
      _$MessagesWithUsers$SubscriptionRootToJson(this);
}

final MESSAGES_WITH_USERS_SUBSCRIPTION_DOCUMENT_OPERATION_NAME =
    'messages_with_users';
final MESSAGES_WITH_USERS_SUBSCRIPTION_DOCUMENT = DocumentNode(definitions: [
  OperationDefinitionNode(
    type: OperationType.subscription,
    name: NameNode(value: 'messages_with_users'),
    variableDefinitions: [],
    directives: [],
    selectionSet: SelectionSetNode(selections: [
      FieldNode(
        name: NameNode(value: 'messages'),
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
            name: NameNode(value: 'message'),
            alias: null,
            arguments: [],
            directives: [],
            selectionSet: null,
          ),
          FieldNode(
            name: NameNode(value: 'profile'),
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
                name: NameNode(value: 'name'),
                alias: null,
                arguments: [],
                directives: [],
                selectionSet: null,
              ),
            ]),
          ),
        ]),
      )
    ]),
  )
]);

class MessagesWithUsersSubscription
    extends GraphQLQuery<MessagesWithUsers$SubscriptionRoot, JsonSerializable> {
  MessagesWithUsersSubscription();

  @override
  final DocumentNode document = MESSAGES_WITH_USERS_SUBSCRIPTION_DOCUMENT;

  @override
  final String operationName =
      MESSAGES_WITH_USERS_SUBSCRIPTION_DOCUMENT_OPERATION_NAME;

  @override
  List<Object?> get props => [document, operationName];

  @override
  MessagesWithUsers$SubscriptionRoot parse(Map<String, dynamic> json) =>
      MessagesWithUsers$SubscriptionRoot.fromJson(json);
}
