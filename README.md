# DartPollo

[![Pub](https://img.shields.io/pub/v/dartpollo.svg)](https://pub.dev/packages/dartpollo)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Build Dart types from GraphQL schemas and queries using Introspection Query.

## Overview

DartPollo is a code generator that builds Dart types from GraphQL schemas and queries. It helps you integrate GraphQL into your Dart and Flutter applications by generating type-safe models from your GraphQL operations.

## Features

- Generate Dart classes from GraphQL schemas and queries
- Support for GraphQL fragments
- Support for GraphQL mutations and subscriptions
- Custom scalar mapping
- Integration with json_serializable for JSON serialization
- Type-safe GraphQL operations

## Installation

Add DartPollo to your `pubspec.yaml`:

```yaml
dependencies:
  dartpollo: ^0.1.0

dev_dependencies:
  build_runner: ^2.4.15
```

## Usage

### Basic Setup

1. Create a `build.yaml` file in your project root:

```yaml
targets:
  $default:
    builders:
      dartpollo:
        options:
          schema_mapping:
            - schema: your_schema.graphql
              queries_glob: lib/graphql/**.graphql
              output: lib/graphql/generated/
```

2. Create your GraphQL schema file (or use introspection to generate it)

3. Write your GraphQL queries in `.graphql` files:

Example GraphQL query file (`lib/graphql/get_user.graphql`):

```
# Replace this with your actual GraphQL query based on your schema
query GetUser($id: ID!) {
  # Fields will depend on your specific GraphQL schema
}
```

4. Run the build_runner to generate Dart code:

```bash
dart run build_runner build
```

5. Use the generated code in your application:

```dart
import 'package:your_package/graphql/generated/get_user.graphql.dart';

void main() {
  final query = GetUserQuery(variables: GetUserArguments(id: '123'));
  // Use the query with your GraphQL client
}
```

### Configuration Options

DartPollo can be configured with various options in your `build.yaml` file:

```yaml
targets:
  $default:
    builders:
      dartpollo:
        options:
          schema_mapping:
            - schema: your_schema.graphql
              queries_glob: lib/graphql/**.graphql
              output: lib/graphql/generated/
          scalar_mapping:
            - graphql_type: Date
              dart_type: DateTime
          custom_parser_import: 'package:your_package/graphql/parsers.dart'
          fragments_glob: 'lib/graphql/fragments/**.graphql'
          naming_scheme: pathedWithTypes # or simple
          use_graphql_data_class: false # Enable GraphQLDataClass base class
          combine_mutation_args: false # Enable combined mutation arguments (see below)
```

#### GraphQLDataClass Base Class

DartPollo supports a `GraphQLDataClass` base class that provides a consistent foundation for generated GraphQL model classes. This feature is **Flutter-compatible** and does not use reflection, making it safe for all Dart platforms including Flutter mobile, web, and desktop.

**Enable the feature:**

```yaml
targets:
  $default:
    builders:
      dartpollo:
        options:
          use_graphql_data_class: true
          # ... other options
```

**Generated classes structure:**
```dart
@JsonSerializable(explicitToJson: true)
class SimpleQuery$Query$Pokemon extends GraphQLDataClass with EquatableMixin {
  SimpleQuery$Query$Pokemon();
  
  factory SimpleQuery$Query$Pokemon.fromJson(Map<String, dynamic> json) =>
      _$SimpleQuery$Query$PokemonFromJson(json);
  
  String? number;
  List<String?>? types;
  
  @override
  List<Object?> get props => [number, types];
  
  @override
  Map<String, dynamic> toJson() => _$SimpleQuery$Query$PokemonToJson(this);
}
```

**Benefits:**
- **Flutter-compatible** - no reflection or mirrors used
- Consistent base class for all GraphQL data models
- Maintains full compatibility with `json_serializable`
- Automatic generation of `props` and `toJson()` methods
- Zero breaking changes for existing code
- Works on all Dart platforms (mobile, web, desktop, server)

**Note:** This feature generates explicit `props` and `toJson()` methods for each class, ensuring compatibility with Flutter's AOT compilation while maintaining clean, readable code.

#### Combined Mutation Arguments

DartPollo supports combining GraphQL mutation and arguments classes into a single, more ergonomic class. This feature eliminates redundant boilerplate code by merging separate `*Arguments` and `*Mutation` classes.

**Benefits:**
- **~50% reduction** in generated classes for mutation operations
- **Single-step instantiation** instead of two-step process
- More intuitive API with parameters directly in mutation constructor
- Maintained type safety and GraphQL variable mapping

**Enable the feature:**

```yaml
targets:
  $default:
    builders:
      dartpollo:
        options:
          combine_mutation_args: true
          # ... other options
```

**Traditional Pattern** (default: `combine_mutation_args: false`):
```dart
// Two separate classes generated
final variables = SubmitReimbursementApprovalArguments(
  reimbursementId: 'some-id',
  isApproved: true,
);
final mutation = SubmitReimbursementApprovalMutation(variables: variables);
```

**Combined Pattern** (`combine_mutation_args: true`):
```dart
// Single combined class - no separate Arguments class!
final mutation = SubmitReimbursementApprovalMutation(
  reimbursementId: 'some-id',
  isApproved: true,
);
```

**Generated Code Structure:**
```dart
class SubmitReimbursementApprovalMutation extends GraphQLQuery<
    SubmitReimbursementApproval$Mutation, JsonSerializable> {
  SubmitReimbursementApprovalMutation({
    required this.reimbursementId,
    required this.isApproved,
    this.declineReason,
    // ... other parameters
  });
  
  final String reimbursementId;
  final bool isApproved;
  final String? declineReason;
  
  @override
  Map<String, dynamic> getParameterVariablesMap() => {
    'reimbursementId': reimbursementId,
    'isApproved': isApproved,
    'declineReason': declineReason,
    // ... other mappings
  };
  
  @override
  List<Object?> get props => [
    document, operationName,
    reimbursementId, isApproved, declineReason,
    // ... other parameters
  ];
}
```

**Migration:** The feature is **disabled by default** for backward compatibility. No migration is required for existing projects.

## Examples

Check the `example` directory for complete examples of using DartPollo with different GraphQL servers.

## Custom Scalars

You can map GraphQL scalar types to Dart types using the `scalar_mapping` configuration:

```yaml
scalar_mapping:
  - graphql_type: Date
    dart_type: DateTime
    use_custom_parser: true
  - graphql_type: JSON
    dart_type: Map<String, dynamic>
```

If `use_custom_parser` is set to `true`, you need to provide custom parsing functions in a separate file and reference it with `custom_parser_import`.

## Architecture

DartPollo uses a modular, service-oriented architecture that separates concerns for better maintainability and testability:

### Core Components

- **Generator Modules** (`lib/generator/`): Specialized generators for different GraphQL constructs
  - `EnumGenerator`: Handles GraphQL enum generation
  - `ClassGenerator`: Handles GraphQL object type generation
  - `InputGenerator`: Handles GraphQL input object generation
  - `FragmentProcessor`: Handles GraphQL fragment processing

- **Service Layer** (`lib/services/`): Business logic and coordination
  - `GenerationService`: Orchestrates the overall generation process
  - `SchemaService`: Handles schema operations and type lookups
  - `FileService`: Manages file operations and path utilities

- **Context System** (`lib/context/`): Immutable state management
  - `GenerationContext`: Maintains generation state and configuration
  - `SchemaContext`: Holds schema-related information
  - `ValidationContext`: Manages errors and warnings

- **Visitor Pattern** (`lib/visitor/`): AST traversal and processing
  - `BaseVisitor`: Abstract interface for all visitors
  - Specialized visitors for different GraphQL node types
  - `VisitorComposer`: Combines multiple visitors for complex operations

### Migration Guide

The public API remains unchanged, but internal architecture has been significantly improved:

- **For Users**: No changes required - all existing configurations and usage patterns continue to work
- **For Contributors**: New modular structure makes it easier to:
  - Add new GraphQL features
  - Write focused unit tests
  - Understand and modify specific functionality
  - Extend the visitor pattern for custom processing

### Development

To work with the new architecture:

1. **Adding new GraphQL features**: Create or extend generator modules in `lib/generator/`
2. **Modifying generation logic**: Update the appropriate service in `lib/services/`
3. **Adding validation**: Extend the context system in `lib/context/`
4. **Custom AST processing**: Implement new visitors in `lib/visitor/`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

The new modular architecture makes it easier to contribute:
- Each module has focused responsibilities
- Comprehensive unit tests for each component
- Clear separation between public API and internal implementation

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
