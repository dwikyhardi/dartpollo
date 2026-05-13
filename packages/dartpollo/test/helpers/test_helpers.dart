import 'package:dartpollo_annotation/schema/graphql_query.dart';
import 'package:gql/language.dart';
import 'package:gql_exec/gql_exec.dart';
import 'package:gql_link/gql_link.dart';
import 'package:json_annotation/json_annotation.dart';

/// A simple test query with no variables.
class SimpleQuery extends GraphQLQuery<Map<String, dynamic>, JsonSerializable> {
  SimpleQuery() : super() {
    document = parseString('query Simple { hello }');
  }

  @override
  final String? operationName = 'Simple';

  @override
  Map<String, dynamic> parse(Map<String, dynamic> json) => json;

  @override
  Map<String, dynamic> getVariablesMap() => {};

  @override
  List<Object?> get props => [];
}

/// A test query with variables.
class TestQueryWithVars
    extends GraphQLQuery<Map<String, dynamic>, JsonSerializable> {
  TestQueryWithVars(this.vars) : super() {
    document = parseString(
      'query TestQuery(\$id: ID!) { user(id: \$id) { name } }',
    );
  }

  final Map<String, dynamic> vars;

  @override
  final String? operationName = 'TestQuery';

  @override
  Map<String, dynamic> parse(Map<String, dynamic> json) => json;

  @override
  Map<String, dynamic> getVariablesMap() => vars;

  @override
  List<Object?> get props => [vars];
}

/// A mock Link that returns a single response with given data.
class MockLink extends Link {
  MockLink(this.data);

  final Map<String, dynamic> data;

  @override
  Stream<Response> request(Request request, [NextLink? forward]) {
    return Stream.value(
      Response(data: data, response: const {}, context: request.context),
    );
  }
}

/// A mock Link that captures the request for inspection.
class CapturingLink extends Link {
  CapturingLink({required this.data});

  final Map<String, dynamic> data;
  Request? capturedRequest;

  @override
  Stream<Response> request(Request request, [NextLink? forward]) {
    capturedRequest = request;
    return Stream.value(
      Response(data: data, response: const {}, context: request.context),
    );
  }
}

/// A mock Link that returns multiple responses.
class MultiResponseLink extends Link {
  MultiResponseLink(this.responses);

  final List<Map<String, dynamic>> responses;

  @override
  Stream<Response> request(Request request, [NextLink? forward]) {
    return Stream.fromIterable(
      responses.map(
        (data) =>
            Response(data: data, response: const {}, context: request.context),
      ),
    );
  }
}

/// A mock Link that returns null data.
class NullDataLink extends Link {
  @override
  Stream<Response> request(Request request, [NextLink? forward]) {
    return Stream.value(
      Response(response: const {}, context: request.context),
    );
  }
}

/// A mock Link that returns a response with errors.
class ErrorResponseLink extends Link {
  @override
  Stream<Response> request(Request request, [NextLink? forward]) {
    return Stream.value(
      Response(
        response: const {},
        errors: const [GraphQLError(message: 'Test error')],
        context: request.context,
      ),
    );
  }
}
