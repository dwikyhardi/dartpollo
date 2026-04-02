import 'package:dartpollo_annotation/schema/schema_options.dart';
import 'package:gql/ast.dart';

import '../generator/data/data.dart';

/// Exception thrown when generation context validation fails
class GenerationContextValidationException implements Exception {
  GenerationContextValidationException(this.message);
  final String message;

  @override
  String toString() => 'GenerationContextValidationException: $message';
}

/// Immutable context containing all generation state and configuration.
/// Supports immutable updates through copyWith method.
class GenerationContext {
  const GenerationContext({
    required this.schemaMap,
    required this.path,
    this.currentType,
    this.currentFieldName,
    this.currentClassName,
    required this.generatedClasses,
    required this.inputsClasses,
    required this.fragments,
    required this.usedEnums,
    required this.usedInputObjects,
  });
  final SchemaMap schemaMap;
  final List<TypeName> path;
  final TypeDefinitionNode? currentType;
  final ClassPropertyName? currentFieldName;
  final ClassName? currentClassName;
  final List<Definition> generatedClasses;
  final List<QueryInput> inputsClasses;
  final List<FragmentDefinitionNode> fragments;
  final Set<EnumName> usedEnums;
  final Set<ClassName> usedInputObjects;

  /// Creates a new GenerationContext with updated values
  GenerationContext copyWith({
    SchemaMap? schemaMap,
    List<TypeName>? path,
    TypeDefinitionNode? currentType,
    ClassPropertyName? currentFieldName,
    ClassName? currentClassName,
    List<Definition>? generatedClasses,
    List<QueryInput>? inputsClasses,
    List<FragmentDefinitionNode>? fragments,
    Set<EnumName>? usedEnums,
    Set<ClassName>? usedInputObjects,
  }) {
    return GenerationContext(
      schemaMap: schemaMap ?? this.schemaMap,
      path: path ?? this.path,
      currentType: currentType ?? this.currentType,
      currentFieldName: currentFieldName ?? this.currentFieldName,
      currentClassName: currentClassName ?? this.currentClassName,
      generatedClasses: generatedClasses ?? this.generatedClasses,
      inputsClasses: inputsClasses ?? this.inputsClasses,
      fragments: fragments ?? this.fragments,
      usedEnums: usedEnums ?? this.usedEnums,
      usedInputObjects: usedInputObjects ?? this.usedInputObjects,
    );
  }

  /// Validates the generation context state for consistency
  void validate() {
    // Validate that path doesn't contain null or empty type names
    for (final typeName in path) {
      if (typeName.name.isEmpty) {
        throw GenerationContextValidationException(
          'Path cannot contain empty type names',
        );
      }
    }

    // Note: currentClassName and currentFieldName validation is handled by their constructors
    // which use hasValue() assertions, so we don't need to validate them here

    // Validate that generated classes don't have duplicate names
    final classNames = <String>{};
    for (final definition in generatedClasses) {
      if (definition is ClassDefinition) {
        final className = definition.name.name;
        if (classNames.contains(className)) {
          throw GenerationContextValidationException(
            'Duplicate class name found: $className',
          );
        }
        classNames.add(className);
      }
    }

    // Validate that input classes don't have duplicate names
    final inputNames = <String>{};
    for (final input in inputsClasses) {
      final inputName = input.name.name;
      if (inputNames.contains(inputName)) {
        throw GenerationContextValidationException(
          'Duplicate input class name found: $inputName',
        );
      }
      inputNames.add(inputName);
    }

    // Validate that fragments don't have duplicate names
    final fragmentNames = <String>{};
    for (final fragment in fragments) {
      final fragmentName = fragment.name.value;
      if (fragmentNames.contains(fragmentName)) {
        throw GenerationContextValidationException(
          'Duplicate fragment name found: $fragmentName',
        );
      }
      fragmentNames.add(fragmentName);
    }
  }

  /// Creates a new context with the current type set
  GenerationContext withCurrentType(TypeDefinitionNode? type) {
    return copyWith(currentType: type);
  }

  /// Creates a new context with an updated path
  GenerationContext withPath(List<TypeName> newPath) {
    return copyWith(path: newPath);
  }

  /// Creates a new context with an additional type added to the path
  GenerationContext withPathExtension(TypeName typeName) {
    return copyWith(path: [...path, typeName]);
  }

  /// Creates a new context with a new generated class added
  GenerationContext withGeneratedClass(Definition definition) {
    return copyWith(generatedClasses: [...generatedClasses, definition]);
  }

  /// Creates a new context with a new input class added
  GenerationContext withInputClass(QueryInput input) {
    return copyWith(inputsClasses: [...inputsClasses, input]);
  }

  /// Creates a new context with a used enum added
  GenerationContext withUsedEnum(EnumName enumName) {
    return copyWith(usedEnums: {...usedEnums, enumName});
  }

  /// Creates a new context with a used input object added
  GenerationContext withUsedInputObject(ClassName inputObjectName) {
    return copyWith(usedInputObjects: {...usedInputObjects, inputObjectName});
  }
}
