import 'package:dartpollo/generator.dart';
import 'package:dartpollo/generator/data/data.dart';
import 'package:dartpollo/generator/data/enum_value_definition.dart';
import 'package:dartpollo/generator/data/nullable.dart';
import 'package:dartpollo/generator/ephemeral_data.dart';
import 'package:dartpollo/generator/helpers.dart';
import 'package:dartpollo/generator/graphql_helpers.dart' as gql;
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
      final enumName = EnumName(name: node.name.value);

      final nextContext = context.sameTypeWithNoPath(
        alias: enumName,
        ofUnion: Nullable<TypeDefinitionNode?>(null),
      );

      logFn(context, nextContext.align, '-> Enum');
      logFn(context, nextContext.align,
          '<- Generated enum ${enumName.namePrintable}.');

      return EnumDefinition(
        name: enumName,
        values: node.values
            .map((ev) => EnumValueDefinition(
                  name: EnumValueName(name: ev.name.value),
                  annotations: proceedDeprecated(ev.directives),
                ))
            .toList()
          ..add(unknown),
      );
    };
  }

  @override
  void visitInputObjectTypeDefinitionNode(InputObjectTypeDefinitionNode node) {
    inputObjects[node.name.value] = () {
      final name = ClassName(name: node.name.value);
      final nextContext = context.sameTypeWithNoPath(
        alias: name,
        ofUnion: Nullable<TypeDefinitionNode?>(null),
      );

      logFn(context, nextContext.align, '-> Input class');
      logFn(context, nextContext.align,
          '┌ ${nextContext.path}[${node.name.value}]');
      final properties = <ClassProperty>[];

      properties.addAll(node.fields.map((i) {
        final nextType =
            gql.getTypeByName(nextContext.typeDefinitionNodeVisitor, i.type);
        return createClassProperty(
          fieldName: ClassPropertyName(name: i.name.value),
          context: nextContext.nextTypeWithNoPath(
            nextType: node,
            nextClassName: ClassName(name: nextType.name.value),
            nextFieldName: ClassName(name: i.name.value),
            ofUnion: Nullable<TypeDefinitionNode?>(null),
          ),
          markAsUsed: false,
        );
      }));

      logFn(context, nextContext.align,
          '└ ${nextContext.path}[${node.name.value}]');
      logFn(context, nextContext.align,
          '<- Generated input class ${name.namePrintable}.');

      return ClassDefinition(
        isInput: true,
        name: name,
        properties: properties,
      );
    };
  }
}
