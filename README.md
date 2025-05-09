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
  dartpollo: ^0.0.1

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
```

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

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
