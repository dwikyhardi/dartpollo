import 'package:gql/ast.dart';

import '../generator/data/enum_definition.dart';
import '../generator/data/enum_value_definition.dart';
import 'base_visitor.dart';

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
    final enumName = EnumName(name: node.name.value);

    // Convert GraphQL enum values to enum value definitions
    final enumValues = node.values.map((valueNode) {
      final valueName = EnumValueName(name: valueNode.name.value);
      return EnumValueDefinition(name: valueName);
    }).toList();

    // Create enum definition
    final enumDefinition = EnumDefinition(
      name: enumName,
      values: enumValues,
    );

    _enums.add(enumDefinition);
    super.visitEnumTypeDefinitionNode(node);
  }
}
