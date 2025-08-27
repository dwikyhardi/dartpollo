import 'package:equatable/equatable.dart';
import 'package:gql/ast.dart';
import 'package:json_annotation/json_annotation.dart';

/// A GraphQL query abstraction. This class should be extended automatically
/// by Dartpollo and used with [DartpolloClient].
abstract class GraphQLQuery<T, U extends JsonSerializable> extends Equatable {
  /// Instantiates a query or mutation.
  GraphQLQuery({this.variables});

  /// Typed query/mutation variables.
  final U? variables;

  /// AST representation of the document to be executed.
  late final DocumentNode document;

  /// Operation name used for this query/mutation.
  final String? operationName = null;

  /// Parses a JSON map into the response type.
  T parse(Map<String, dynamic> json);

  /// Get variables as a JSON map from constructor parameters.
  /// This method should be overridden by combined mutation classes
  /// to provide parameter-based variable mapping.
  Map<String, dynamic> getParameterVariablesMap() => {};

  /// Get variables as a JSON map.
  /// Uses parameter-based mapping if available, otherwise falls back to variables field.
  Map<String, dynamic> getVariablesMap() {
    final parameterVars = getParameterVariablesMap();
    if (parameterVars.isNotEmpty) {
      return parameterVars;
    }
    return variables?.toJson() ?? {};
  }
}
