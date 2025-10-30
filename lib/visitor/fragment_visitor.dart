import 'package:gql/ast.dart';

import '../generator/data/class_property.dart';
import '../generator/data/fragment_class_definition.dart';
import '../generator/graphql_helpers.dart';
import '../schema/schema_options.dart';
import '../visitor/type_definition_node_visitor.dart';
import 'base_visitor.dart';

/// Specialized visitor for handling GraphQL fragment definitions.
/// Processes fragment nodes and generates fragment class definitions.
class FragmentVisitor extends BaseVisitor<List<FragmentClassDefinition>> {
  /// Creates a new FragmentVisitor with required dependencies.
  FragmentVisitor({
    required TypeDefinitionNodeVisitor typeDefinitionVisitor,
    required GeneratorOptions options,
  }) : _typeDefinitionVisitor = typeDefinitionVisitor,
       _options = options;
  final List<FragmentClassDefinition> _fragments = [];
  final TypeDefinitionNodeVisitor _typeDefinitionVisitor;
  final GeneratorOptions _options;

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
    final fragmentName = FragmentName(name: node.name.value);

    // Get the type that this fragment is defined on
    final fragmentType = getTypeByName(
      _typeDefinitionVisitor,
      node.typeCondition.on,
    );

    // Convert GraphQL fields to class properties
    final properties = node.selectionSet.selections.whereType<FieldNode>().map((
      field,
    ) {
      final fieldName = ClassPropertyName(name: field.name.value);

      // Find the field definition in the fragment's target type
      FieldDefinitionNode? fieldDefinition;
      if (fragmentType is ObjectTypeDefinitionNode) {
        fieldDefinition = fragmentType.fields.firstWhere(
          (f) => f.name.value == field.name.value,
        );
      } else if (fragmentType is InterfaceTypeDefinitionNode) {
        fieldDefinition = fragmentType.fields.firstWhere(
          (f) => f.name.value == field.name.value,
        );
      }

      if (fieldDefinition == null) {
        throw Exception(
          'Field "${field.name.value}" not found in type "${fragmentType.name.value}"',
        );
      }

      final fieldType = buildTypeName(
        fieldDefinition.type,
        _options,
        typeDefinitionNodeVisitor: _typeDefinitionVisitor,
      );

      return ClassProperty(
        name: fieldName,
        type: fieldType,
      );
    }).toList();

    // Only create fragment class definition if there are properties
    // Empty fragments are not useful for code generation
    if (properties.isNotEmpty) {
      final fragmentDefinition = FragmentClassDefinition(
        name: fragmentName,
        properties: properties,
      );

      _fragments.add(fragmentDefinition);
    }

    super.visitFragmentDefinitionNode(node);
  }
}
