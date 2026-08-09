---
layout: ../layouts/DocsLayout.astro
title: Configuration
description: Complete build.yaml configuration reference for Dartpollo Generator.
---

<header class="page-lead">

# Configuration

All generator options live under the `dartpollo_generator|dartpollo` builder key in `build.yaml`.

</header>

## Complete example

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
          generate_helpers: false
          generate_queries: true
          optimize_document_nodes: true
          convert_enum_to_string: false
          ignore_for_file:
            - deprecated_member_use
          fragments_glob: lib/graphql/fragments/*.graphql
          scalar_mapping:
            - graphql_type: DateTime
              dart_type: DateTime
            - graphql_type: JSON
              dart_type:
                name: Map<String, dynamic>
          schema_mapping:
            - schema: schema.graphql
              queries_glob: lib/graphql/operations/*.graphql
              fragments_glob: lib/graphql/shared/*.graphql
              naming_scheme: pathedWithTypes
              type_name_field: __typename
              append_type_name: false
```

## Top-level options

| Option | Type | Default | Purpose |
|---|---|---:|---|
| `generate_helpers` | `bool` | `true` | Generate `GraphQLQuery` subclasses for Dartpollo clients. |
| `generate_queries` | `bool` | `true` | Generate operation documents, names, and argument classes. |
| `scalar_mapping` | list | `[]` | Map non-built-in GraphQL scalars to Dart types. |
| `fragments_glob` | `String?` | `null` | Fragments available to every schema mapping. |
| `schema_mapping` | list | `[]` | Required schema-to-operation mappings. |
| `ignore_for_file` | list | `[]` | Extra lint names added to generated headers. |
| `convert_enum_to_string` | `bool` | `false` | Generate strings instead of Dart enums globally. |
| `optimize_document_nodes` | `bool` | `false` | Reduce emitted document AST verbosity. |

## Schema mapping

Each mapping pairs one schema glob with one operation glob. Multiple mappings can point to the same schema.

| Option | Default | Purpose |
|---|---:|---|
| `schema` | — | Required schema file or glob. |
| `queries_glob` | — | Required operation-file glob. |
| `fragments_glob` | `null` | Fragments available only to this mapping. |
| `type_name_field` | `__typename` | Field used to resolve abstract types. |
| `append_type_name` | `false` | Add the type-name field during document transformation. |
| `convert_enum_to_string` | `false` | Override enum generation for this mapping. |
| `naming_scheme` | `pathedWithTypes` | Strategy for nested generated class names. |

## Naming schemes

- **`pathedWithTypes`** prefixes nested classes with prior GraphQL type names. It is the safest default.
- **`pathedWithFields`** derives prefixes from field names, which can make operation-specific models easier to read.
- **`simple`** uses only the current type name. It is concise but can produce `DuplicatedClassesException`; aliases may be required.

## Output paths

Outputs are automatic. The generator derives an `__generated__` directory from `queries_glob` and writes `.graphql.dart` files. There is no supported `output` option in the current `SchemaMap` API.

## Source inclusion

Every schema, operation, and fragment must be included by the target's `sources`. If a glob is valid but excluded from `sources`, `build_runner` cannot expose it to the builder.

<nav class="page-nav"><a href="../integration-modes/">← Integration modes</a><a href="../generated-output/">Generated output →</a></nav>
