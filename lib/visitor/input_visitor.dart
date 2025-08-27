import 'package:gql/ast.dart';
import 'base_visitor.dart';
import '../generator/data/class_definition.dart';

/// Specialized visitor for handling GraphQL input object type definitions.
/// Processes input object nodes and generates input class definitions.
class InputVisitor extends BaseVisitor<List<ClassDefinition>> {
  final List<ClassDefinition> _inputClasses = [];

  @override
  List<ClassDefinition> get result => List.unmodifiable(_inputClasses);

  @override
  void reset() {
    _inputClasses.clear();
  }

  @override
  bool canHandle(Node node) {
    return node is InputObjectTypeDefinitionNode || node is DocumentNode;
  }

  @override
  void visitInputObjectTypeDefinitionNode(InputObjectTypeDefinitionNode node) {
    // TODO: Implement input object type definition processing
    // This will be implemented in task 5.1
    super.visitInputObjectTypeDefinitionNode(node);
  }
}
