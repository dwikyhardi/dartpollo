import 'package:gql/ast.dart';
import 'base_visitor.dart';

/// Composer for combining multiple visitors to process GraphQL documents.
/// Coordinates visitor execution and provides type-safe result retrieval.
class VisitorComposer {
  final List<BaseVisitor> visitors;

  VisitorComposer(this.visitors);

  /// Visits a GraphQL document with all registered visitors
  void visitDocument(DocumentNode document) {
    for (final visitor in visitors) {
      if (visitor.canHandle(document)) {
        document.accept(visitor);
      }
    }
  }

  /// Gets the result from a specific visitor type
  T getResult<T>(Type visitorType) {
    final visitor = visitors.firstWhere(
      (v) => v.runtimeType == visitorType,
      orElse: () =>
          throw ArgumentError('Visitor of type $visitorType not found'),
    );

    if (visitor.result is! T) {
      throw ArgumentError('Visitor result is not of expected type $T');
    }

    return visitor.result as T;
  }
}
