# DartPollo

[![Pub](https://img.shields.io/pub/v/dartpollo.svg)](https://pub.dev/packages/dartpollo)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Build Dart types from GraphQL schemas and queries using Introspection Query.

## Overview

DartPollo is a powerful code generator for Dart and Flutter that streamlines the use of GraphQL. It automatically builds Dart types from your GraphQL schemas and queries, enabling you to work with type-safe models and integrate seamlessly with GraphQL APIs.

## Features

- **Code Generation**: Automatically generate Dart classes from your GraphQL schemas, queries, mutations, and subscriptions.
- **Fragment Support**: Full support for GraphQL fragments to reuse parts of your queries.
- **Custom Scalar Mapping**: Define custom mappings from GraphQL scalar types to your own Dart types.
- **`json_serializable` Integration**: Seamlessly integrates with `json_serializable` for robust JSON serialization and deserialization.
- **Type Safety**: Ensure your GraphQL operations are type-safe, reducing runtime errors and improving developer experience.

## Installation

Add DartPollo to your `pubspec.yaml` file:

```yaml
dependencies:
  dartpollo: ^0.1.0

dev_dependencies:
  build_runner: ^2.4.15
```

## Usage

### Basic Setup

1.  **Create a `build.yaml` file** in your project's root directory to configure the generator:

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

2.  **Provide a GraphQL schema file**. You can either write one manually or generate it using introspection.

3.  **Write your GraphQL queries** in `.graphql` files. For example, create `lib/graphql/get_user.graphql`:

    ```graphql
    # Replace this with your actual GraphQL query based on your schema
    query GetUser($id: ID!) {
      # Fields will depend on your specific GraphQL schema
    }
    ```

4.  **Run the build runner** to generate the Dart code:

    ```bash
    dart run build_runner build
    ```

5.  **Use the generated code** in your application:

    ```dart
    import 'package:your_package/graphql/generated/get_user.gql.dart';

    void main() {
      final query = GetUserQuery(variables: GetUserArguments(id: '123'));
      // Use the query with your GraphQL client
    }
    ```

### Configuration Options

You can customize DartPollo's behavior with additional options in your `build.yaml`:

```yaml
targets:
  $default:
    builders:
      dartpollo:
        options:
          # Define custom scalar type mappings
          scalar_mapping:
            - graphql_type: Date
              dart_type: String
          # Glob pattern for shared fragment files
          fragments_glob: 'lib/graphql/fragments/**.graphql'
          # Reduces DocumentNode verbosity by 40-50%
          optimize_document_nodes: true
          # Convert enums to strings instead of enum types (default: false)
          convert_enum_to_string: false
          schema_mapping:
            - schema: your_schema.graphql
              queries_glob: lib/graphql/**.graphql
              output: lib/graphql/generated/
              # Naming schemes: pathedWithTypes, pathedWithFields, or simple
              naming_scheme: pathedWithTypes
```

## Examples

The `example` directory contains complete examples of using DartPollo with different GraphQL servers:

* **Pokemon Example** (`example/pokemon/`): Demonstrates basic usage with GraphQL queries, fragments, and the `GraphQLDataClass` feature.
* **GitHub Example** (`example/github/`): Shows integration with the GitHub GraphQL API.
* **GraphBrainz Example** (`example/graphbrainz/`): Illustrates usage with the MusicBrainz GraphQL API.
* **Hasura Example** (`example/hasura/`): Demonstrates integration with a Hasura GraphQL backend.

Each example includes a full `build.yaml` configuration, GraphQL schema, query definitions, and the generated Dart code.

## Custom Scalars

You can map custom GraphQL scalar types to your own Dart types using the `scalar_mapping` configuration. This is useful for handling complex types like file uploads or custom date formats.

**Example `build.yaml` for Custom Scalars:**

```yaml
scalar_mapping:
  - graphql_type: DateTime
    dart_type: DateTime
  - graphql_type: Upload
    custom_parser_import: 'package:your_package/graphql/parsers.dart'
    use_custom_parser: true
    dart_type:
      name: MultipartFile
      imports:
        - 'package:http/http.dart'
```

* **`graphql_type`**: The name of the GraphQL scalar type from your schema (e.g., "Upload").
* **`custom_parser_import`**: The path to a Dart file with custom parsing functions for serialization and deserialization.
* **`dart_type.name`**: The target Dart class name to represent the scalar (e.g., `MultipartFile`).
* **`dart_type.imports`**: A list of imports required for the Dart type.
* **`use_custom_parser`**: When `true`, DartPollo will use your custom parsing functions instead of the default serialization.

## Architecture

DartPollo is built with a modular, service-oriented architecture that promotes maintainability and testability.

### Core Components

* **Generator Modules** (`lib/generator/`): Specialized generators for GraphQL constructs like enums, classes, inputs, and fragments.
* **Service Layer** (`lib/services/`): Handles business logic and coordinates the generation process.
* **Context System** (`lib/context/`): Manages immutable state and configuration during generation.
* **Schema Management** (`lib/schema/`): Processes and validates the GraphQL schema.
* **Transformer Layer** (`lib/transformer/`): Provides utilities for code transformation and generation.
* **Visitor Pattern** (`lib/visitor/`): Traverses the GraphQL AST to process nodes.

### Migration Guide

The public API is stable, but the internal architecture has been significantly improved for better modularity.

* **For Users**: No changes are required. Existing configurations will continue to work.
* **For Contributors**: The new structure makes it easier to add features, write tests, and extend functionality.

### Development

To contribute to the new architecture:

1.  **Add new GraphQL features**: Extend the generator modules in `lib/generator/`.
2.  **Modify generation logic**: Update the services in `lib/services/`.
3.  **Add validation**: Enhance the context system in `lib/context/`.
4.  **Custom AST processing**: Implement new visitors in `lib/visitor/`.

## Contributing

Contributions are welcome\! Please feel free to submit a pull request. The modular architecture is designed to make it easy to contribute.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.