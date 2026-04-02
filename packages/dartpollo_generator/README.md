# dartpollo_generator

Code generator for the [dartpollo](https://pub.dev/packages/dartpollo) GraphQL client. Builds Dart types from GraphQL schemas and queries using Introspection Query.

## Installation

Add `dartpollo_generator` as a dev dependency alongside `dartpollo` and `build_runner`:

```yaml
dependencies:
  dartpollo: ^0.1.0

dev_dependencies:
  build_runner: ^2.10.0
  dartpollo_generator: ^0.1.0
```

## Setup

1. **Add your GraphQL schema** (e.g., `schema.graphql`) to your project root.

2. **Create a `build.yaml`** in your project root:

```yaml
targets:
  $default:
    sources:
      - $package$
      - lib/**
      - schema.graphql
    builders:
      dartpollo_generator|dartpollo:
        options:
          schema_mapping:
            - schema: schema.graphql
              queries_glob: lib/**/*.graphql
```

3. **Write your GraphQL queries** as `.graphql` files under `lib/`.

4. **Run the generator:**

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates `.graphql.dart` files containing typed query classes, input types, enums, and fragments.

## Configuration

The generator is configured via `build.yaml` under the `dartpollo_generator|dartpollo` builder key.

### Top-Level Options (`GeneratorOptions`)

| Option | Type | Default | Description |
|---|---|---|---|
| `generate_helpers` | `bool` | `true` | Whether to generate instances of `GraphQLQuery` helper classes |
| `generate_queries` | `bool` | `true` | Whether to generate query documents and operation names |
| `scalar_mapping` | `List<ScalarMap>` | `[]` | Custom scalar type mappings to Dart types (see [Scalar Mapping](#scalar-mapping)) |
| `fragments_glob` | `String?` | `null` | Glob pattern for shared fragment files applied to all queries |
| `schema_mapping` | `List<SchemaMap>` | `[]` | List of schema-to-query mappings (see [Schema Mapping](#schema-mapping)) |
| `ignore_for_file` | `List<String>` | `[]` | Linter rules to ignore in generated files (added as `// ignore_for_file:` comments) |
| `convert_enum_to_string` | `bool` | `false` | Convert GraphQL enums to plain `String` types instead of Dart enums |
| `optimize_document_nodes` | `bool` | `false` | Optimize `DocumentNode` generation using template-based helpers, reducing verbosity by 40-50% |

### Schema Mapping (`SchemaMap`)

Each entry in `schema_mapping` configures how a GraphQL schema maps to query files:

| Option | Type | Default | Description |
|---|---|---|---|
| `schema` | `String?` | — | Path to the GraphQL schema file |
| `queries_glob` | `String?` | — | Glob pattern for `.graphql` query files |
| `fragments_glob` | `String?` | `null` | Glob pattern for fragment files specific to this schema |
| `type_name_field` | `String` | `__typename` | The resolve type field used on this schema |
| `append_type_name` | `bool` | `false` | Whether to append the type name field to generated types |
| `convert_enum_to_string` | `bool` | `false` | Convert enums to strings for this specific schema mapping |
| `naming_scheme` | `NamingScheme` | `pathedWithTypes` | The naming scheme for generated class names |

#### Naming Schemes

| Value | Description |
|---|---|
| `pathedWithTypes` | (Default) Previous type names are used as prefix for nested classes. May generate duplication on certain schemas. |
| `pathedWithFields` | Previous field names are used as prefix for nested classes. |
| `simple` | Uses only the actual GraphQL class name. Will likely lead to duplication unless you use aliases. |

### Scalar Mapping (`ScalarMap`)

Each entry in `scalar_mapping` maps a GraphQL scalar type to a Dart type:

| Option | Type | Description |
|---|---|---|
| `graphql_type` | `String?` | The GraphQL scalar type name (e.g., `DateTime`, `JSON`) |
| `dart_type` | `DartType` | The Dart type to map to (see below) |
| `custom_parser_import` | `String?` | Import path for a custom parser if needed |

A `DartType` can be specified as a simple string (just the type name) or as an object:

| Option | Type | Description |
|---|---|---|
| `name` | `String?` | The Dart type name (e.g., `DateTime`, `Map<String, dynamic>`) |
| `imports` | `List<String>` | Package imports required for this type |

#### Scalar Mapping Example

```yaml
options:
  scalar_mapping:
    - graphql_type: timestamptz
      dart_type:
        name: DateTime
    - graphql_type: JSON
      dart_type:
        name: Map<String, dynamic>
    - graphql_type: BigDecimal
      dart_type:
        name: Decimal
        imports:
          - 'package:decimal/decimal.dart'
      custom_parser_import: 'package:my_app/parsers.dart'
```

### Full Configuration Example

```yaml
targets:
  $default:
    sources:
      - $package$
      - lib/**
      - schema.graphql
    builders:
      dartpollo_generator|dartpollo:
        options:
          generate_helpers: true
          generate_queries: true
          optimize_document_nodes: false
          convert_enum_to_string: false
          ignore_for_file:
            - type=lint
          fragments_glob: lib/fragments/**.graphql
          scalar_mapping:
            - graphql_type: timestamptz
              dart_type:
                name: DateTime
            - graphql_type: JSON
              dart_type:
                name: Map<String, dynamic>
          schema_mapping:
            - schema: schema.graphql
              queries_glob: lib/**/*.graphql
              naming_scheme: pathedWithTypes
              type_name_field: __typename
              append_type_name: false
```

See the [examples](https://github.com/dwikyhardi/dartpollo/tree/main/example) for more complete `build.yaml` configurations.

## Related Packages

- [dartpollo](https://pub.dev/packages/dartpollo) — The runtime GraphQL client
- [dartpollo_annotation](https://pub.dev/packages/dartpollo_annotation) — Shared types (transitive dependency)
