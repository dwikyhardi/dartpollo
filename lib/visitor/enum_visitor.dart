import 'package:gql/ast.dart';
import 'base_visitor.dart';
import '../generator/data/enum_definition.dart';

/// Specialized visitor for handling GraphQL enum type definitions.
/// Processes enum nodes and generates enum definitions.
class EnumVisitor extends BaseVisitor<List<EnumDefinition>> {
  final List<EnumDefinition> _enums = [];

  @override
  List<EnumDefinition> get result => List.unmodifiable(_enums);

  @override
  void reset() {
    _enums.clear();
  }

  @override
  bool canHandle(Node node) {
    return node is EnumTypeDefinitionNode || node is DocumentNode;
  }

  @override
  void visitEnumTypeDefinitionNode(EnumTypeDefinitionNode node) {
    // TODO: Implement enum type definition processing
    // This will be implemented in task 2.1
    super.visitEnumTypeDefinitionNode(node);
  }
}
