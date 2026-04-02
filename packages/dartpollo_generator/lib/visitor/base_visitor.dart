import 'package:gql/ast.dart';

/// Abstract base visitor interface that defines the contract for all
/// specialized visitors in the generation process.
abstract class BaseVisitor<T> extends RecursiveVisitor {
  /// Gets the result of the visitor's processing
  T get result;

  /// Resets the visitor state for reuse
  void reset();

  /// Determines if this visitor can handle the given node type
  bool canHandle(Node node);
}
