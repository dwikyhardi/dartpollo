import 'package:gql/ast.dart';
import 'base_visitor.dart';
import '../generator/data/fragment_class_definition.dart';

/// Specialized visitor for handling GraphQL fragment definitions.
/// Processes fragment nodes and generates fragment class definitions.
class FragmentVisitor extends BaseVisitor<List<FragmentClassDefinition>> {
  final List<FragmentClassDefinition> _fragments = [];

  @override
  List<FragmentClassDefinition> get result => List.unmodifiable(_fragments);

  @override
  void reset() {
    _fragments.clear();
  }

  @override
  bool canHandle(Node node) {
    return node is FragmentDefinitionNode || node is DocumentNode;
  }

  @override
  void visitFragmentDefinitionNode(FragmentDefinitionNode node) {
    // TODO: Implement fragment definition processing
    // This will be implemented in task 4.1
    super.visitFragmentDefinitionNode(node);
  }
}
