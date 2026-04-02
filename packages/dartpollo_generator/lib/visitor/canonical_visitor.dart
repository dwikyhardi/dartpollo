import 'package:dartpollo_generator/generator/data/data.dart';
import 'package:dartpollo_generator/generator/enum_generator.dart';
import 'package:dartpollo_generator/generator/ephemeral_data.dart';
import 'package:dartpollo_generator/generator/input_generator.dart';
import 'package:gql/ast.dart';

/// class definition lazy generator
typedef ClassDefinitionGenerator = ClassDefinition Function();

/// class definition lazy generator
typedef EnumDefinitionGenerator = EnumDefinition Function();

/// Visits canonical types Enums and InputObjects
class CanonicalVisitor extends RecursiveVisitor {
  /// Constructor
  CanonicalVisitor({
    required this.context,
  });

  /// Current context
  final Context context;

  /// List of visited input objects
  final Map<String, ClassDefinitionGenerator> inputObjects = {};

  /// List of visited enums
  final Map<String, EnumDefinitionGenerator> enums = {};

  @override
  void visitEnumTypeDefinitionNode(EnumTypeDefinitionNode node) {
    enums[node.name.value] = () {
      return EnumGenerator.generateEnum(node, context);
    };
  }

  @override
  void visitInputObjectTypeDefinitionNode(InputObjectTypeDefinitionNode node) {
    inputObjects[node.name.value] = () {
      return InputGenerator.generateInputClass(node, context);
    };
  }
}
