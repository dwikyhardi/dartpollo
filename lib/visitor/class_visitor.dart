import 'package:gql/ast.dart';
import 'base_visitor.dart';
import '../generator/data/class_definition.dart';

/// Specialized visitor for handling GraphQL object type definitions.
/// Processes object type nodes and generates class definitions.
class ClassVisitor extends BaseVisitor<List<ClassDefinition>> {
  final List<ClassDefinition> _classes = [];

  @override
  List<ClassDefinition> get result => List.unmodifiable(_classes);

  @override
  void reset() {
    _classes.clear();
  }

  @override
  bool canHandle(Node node) {
    return node is ObjectTypeDefinitionNode || node is DocumentNode;
  }

  @override
  void visitObjectTypeDefinitionNode(ObjectTypeDefinitionNode node) {
    // TODO: Implement object type definition processing
    // This will be implemented in task 3.1
    super.visitObjectTypeDefinitionNode(node);
  }
}
