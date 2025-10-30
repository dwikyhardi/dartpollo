import 'package:gql/ast.dart';

import '../generator/data/class_definition.dart';
import '../generator/data/class_property.dart';
import '../generator/graphql_helpers.dart';
import '../schema/schema_options.dart';
import '../visitor/type_definition_node_visitor.dart';
import 'base_visitor.dart';

/// Specialized visitor for handling GraphQL input object type definitions.
/// Processes input object nodes and generates input class definitions.
class InputVisitor extends BaseVisitor<List<ClassDefinition>> {
  /// Creates a new InputVisitor with required dependencies.
  InputVisitor({
    required TypeDefinitionNodeVisitor typeDefinitionVisitor,
    required GeneratorOptions options,
  }) : _typeDefinitionVisitor = typeDefinitionVisitor,
       _options = options;
  final List<ClassDefinition> _inputClasses = [];
  final TypeDefinitionNodeVisitor _typeDefinitionVisitor;
  final GeneratorOptions _options;

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
    final className = ClassName(name: node.name.value);

    // Convert GraphQL input fields to class properties
    final properties = node.fields.map((field) {
      final fieldName = ClassPropertyName(name: field.name.value);
      final fieldType = buildTypeName(
        field.type,
        _options,
        typeDefinitionNodeVisitor: _typeDefinitionVisitor,
      );

      return ClassProperty(
        name: fieldName,
        type: fieldType,
      );
    }).toList();

    // Create input class definition
    final classDefinition = ClassDefinition(
      name: className,
      properties: properties,
      isInput: true,
    );

    _inputClasses.add(classDefinition);
    super.visitInputObjectTypeDefinitionNode(node);
  }
}
