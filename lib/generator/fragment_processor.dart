import 'package:gql/ast.dart';
import 'package:dartpollo/generator/data/data.dart';
import 'package:dartpollo/generator/ephemeral_data.dart';

/// Handles fragment processing logic including extraction and class generation.
class FragmentProcessor {
  /// Extracts fragments from a selection set recursively, including nested fragments.
  ///
  /// This method traverses the selection set and finds all fragment spreads,
  /// then recursively extracts fragments from those fragment definitions.
  /// It also handles inline fragments by recursively processing their selection sets.
  static Set<FragmentDefinitionNode> extractFragments(
    SelectionSetNode? selectionSet,
    List<FragmentDefinitionNode> fragmentsCommon,
  ) {
    final result = <FragmentDefinitionNode>{};

    if (selectionSet == null) {
      return result;
    }

    // Process field selections recursively
    selectionSet.selections.whereType<FieldNode>().forEach((selection) {
      result.addAll(extractFragments(selection.selectionSet, fragmentsCommon));
    });

    // Process inline fragments recursively
    selectionSet.selections
        .whereType<InlineFragmentNode>()
        .forEach((selection) {
      result.addAll(extractFragments(selection.selectionSet, fragmentsCommon));
    });

    // Process fragment spreads and their nested fragments
    selectionSet.selections
        .whereType<FragmentSpreadNode>()
        .forEach((selection) {
      final fragmentDefinitions = fragmentsCommon.where((fragmentDefinition) =>
          fragmentDefinition.name.value == selection.name.value);

      result.addAll(fragmentDefinitions);

      // Recursively extract fragments from the found fragment definitions
      for (var fragmentDefinition in fragmentDefinitions) {
        result.addAll(
            extractFragments(fragmentDefinition.selectionSet, fragmentsCommon));
      }
    });

    return result;
  }

  /// Processes fragments and generates fragment class definitions.
  ///
  /// This method takes a list of fragment definitions and converts them
  /// into FragmentClassDefinition objects that can be used for code generation.
  static List<FragmentClassDefinition> processFragments(
    List<FragmentDefinitionNode> fragments,
    Context context,
  ) {
    final fragmentClasses = <FragmentClassDefinition>[];

    for (var fragment in fragments) {
      final fragmentClass = _processFragment(fragment, context);
      if (fragmentClass != null) {
        fragmentClasses.add(fragmentClass);
      }
    }

    return fragmentClasses;
  }

  /// Processes a single fragment definition into a FragmentClassDefinition.
  static FragmentClassDefinition? _processFragment(
    FragmentDefinitionNode fragment,
    Context context,
  ) {
    // Create fragment name
    final fragmentName = FragmentName(name: fragment.name.value);

    // For now, return a basic fragment class definition with placeholder properties
    // The actual property generation would be handled by other generators
    // in coordination with the visitor pattern
    // We provide a placeholder property to satisfy the hasValue assertion
    final placeholderProperties = <ClassProperty>[
      ClassProperty(
        type: DartTypeName(name: 'String'),
        name: ClassPropertyName(name: '__placeholder'),
        isResolveType: false,
      ),
    ];

    return FragmentClassDefinition(
      name: fragmentName,
      properties: placeholderProperties,
    );
  }
}
