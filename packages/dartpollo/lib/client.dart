import 'dart:async';

import 'package:dartpollo_annotation/schema/graphql_query.dart';
import 'package:dartpollo_annotation/schema/graphql_response.dart';
import 'package:dio/dio.dart';
import 'package:gql_dedupe_link/gql_dedupe_link.dart';
import 'package:gql_dio_link/gql_dio_link.dart';
import 'package:gql_exec/gql_exec.dart';
import 'package:gql_link/gql_link.dart';
import 'package:json_annotation/json_annotation.dart';

/// Used to execute a GraphQL query or mutation and return its typed response.
///
/// A [Link] is used as the network interface.
class DartpolloClient {
  /// Instantiate an [DartpolloClient].
  ///
  /// [DedupeLink] and [DioLink] are included.
  /// To use different [Link] create an [DartpolloClient] with [DartpolloClient.fromLink].
  factory DartpolloClient(
    String graphQLEndpoint, {
    Dio? client,
    Map<String, String> defaultHeaders = const {},
    bool useGETForQueries = false,
    bool serializableErrors = false,
  }) {
    final dioLink = DioLink(
      graphQLEndpoint,
      client: client ?? Dio(),
      defaultHeaders: defaultHeaders,
      useGETForQueries: useGETForQueries,
      serializableErrors: serializableErrors,
    );
    return DartpolloClient.fromLink(
      Link.from([
        DedupeLink(),
        dioLink,
      ]),
    ).._dioLink = dioLink;
  }

  /// Create an [DartpolloClient] from [Link].
  DartpolloClient.fromLink(this._link);

  DioLink? _dioLink;
  final Link _link;

  /// Executes a [GraphQLQuery], returning a typed response.
  Future<GraphQLResponse<T>> execute<T, U extends JsonSerializable>(
    GraphQLQuery<T, U> query, {
    Context context = const Context(),
  }) async {
    final request = Request(
      operation: Operation(
        document: query.document,
        operationName: query.operationName,
      ),
      variables: query.getVariablesMap(),
      context: context,
    );

    final response = await _link.request(request).first;

    return GraphQLResponse<T>(
      data: response.data == null ? null : query.parse(response.data ?? {}),
      errors: response.errors,
      context: response.context,
    );
  }

  /// Streams a [GraphQLQuery], returning a typed response stream.
  Stream<GraphQLResponse<T>> stream<T, U extends JsonSerializable>(
    GraphQLQuery<T, U> query, {
    Context context = const Context(),
  }) {
    final request = Request(
      operation: Operation(
        document: query.document,
        operationName: query.operationName,
      ),
      variables: query.getVariablesMap(),
      context: context,
    );

    return _link
        .request(request)
        .map(
          (response) => GraphQLResponse<T>(
            data: response.data == null
                ? null
                : query.parse(response.data ?? {}),
            errors: response.errors,
            context: response.context,
          ),
        );
  }

  /// Close the inline [Dio] client.
  ///
  /// Keep in mind this will not close clients whose Dartpollo client
  /// was instantiated from [DartpolloClient.fromLink]. If you're using
  /// this constructor, you need to close your own links.
  void dispose() => _dioLink?.close();
}
