import 'package:gql/ast.dart';

import '../generator/data/class_definition.dart';
import '../generator/data/class_property.dart';
import '../generator/graphql_helpers.dart';
import '../schema/schema_options.dart';
import '../visitor/type_definition_node_visitor.dart';
import 'base_visitor.dart';

/// Specialized visitor for handling GraphQL object type definitions.
/// Processes object type nodes and generates class definitions.
class ClassVisitor extends BaseVisitor<List<ClassDefinition>> {
  /// Creates a new ClassVisitor with required dependencies.
  ClassVisitor({
    required TypeDefinitionNodeVisitor typeDefinitionVisitor,
    required GeneratorOptions options,
  }) : _typeDefinitionVisitor = typeDefinitionVisitor,
       _options = options;
  final List<ClassDefinition> _classes = [];
  final TypeDefinitionNodeVisitor _typeDefinitionVisitor;
  final GeneratorOptions _options;

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
    final className = ClassName(name: node.name.value);

    // Convert GraphQL fields to class properties
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

    // Create class definition
    final classDefinition = ClassDefinition(
      name: className,
      properties: properties,
    );

    _classes.add(classDefinition);
    super.visitObjectTypeDefinitionNode(node);
  }
}
