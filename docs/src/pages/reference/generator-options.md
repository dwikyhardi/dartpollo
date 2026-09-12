---
layout: ../../layouts/DocsLayout.astro
title: Generator options
description: Exhaustive Dartpollo Generator option types, defaults, scopes, effects, and caveats.
---

<header class="page-lead">

# Generator options

Check the supported `build.yaml` surface and its current defaults before changing generated output.

</header>

## Top-level options

Use top-level options for behavior shared by the builder or all schema mappings.

| Option | Type | Default | Scope | Effect and caveat |
|---|---|---:|---|---|
| `generate_helpers` | `bool` | `true` | Builder | Emits Dartpollo `GraphQLQuery` wrappers and the Dartpollo import. Helpers require documents, so constants are emitted even when `generate_queries` is false. |
| `generate_queries` | `bool` | `true` | Builder | Emits argument classes, operation-name constants, and `DocumentNode` constants. |
| `scalar_mapping` | list | `[]` | Builder | Maps custom GraphQL scalar names to Dart types. Every unknown scalar reached by an operation must be mapped. |
| `fragments_glob` | `String?` | `null` | All mappings | Makes matching fragments available globally; files must also be in target `sources`. |
| `schema_mapping` | list | `[]` | Builder | Associates schemas and operations. The model defaults to empty, but at least one mapping is required in practice. |
| `ignore_for_file` | list of `String` | `[]` | Generated files | Adds lint identifiers to generated file headers. |
| `convert_enum_to_string` | `bool` | `false` | All mappings | Suppresses generated enum typing. A global true value effectively applies to every mapping. |
| `optimize_document_nodes` | `bool` | `false` | Documents | Prints a smaller AST representation. In `alpha.7`, avoid true with `generate_helpers: false` because optimized output references `DocumentNodeHelpers` without its supplying import. |

<span class="filename">build.yaml</span>

```yaml
options:
  generate_helpers: false
  generate_queries: true
  optimize_document_nodes: false
  schema_mapping:
    - schema: schema.graphql
      queries_glob: lib/graphql/viewer.graphql
```

There is no supported `output` option. `use_graphql_data_class` is not part of the current options model.

## Schema mapping options

Use a mapping to isolate one schema and operation set.

| Option | Type | Default | Required | Effect and caveat |
|---|---|---:|---:|---|
| `schema` | `String` | — | yes | Local SDL file or glob. Normal builds do not fetch it from an endpoint. |
| `queries_glob` | `String` | — | yes | Operation file or glob. It must not include the schema or generated output. |
| `fragments_glob` | `String?` | `null` | no | Adds fragments only for this mapping. |
| `type_name_field` | `String` | `__typename` | no | Selects the field used to dispatch interfaces and unions. |
| `append_type_name` | `bool` | `false` | no | Adds the discriminator field to selection sets; it does not rename types. |
| `convert_enum_to_string` | `bool` | `false` | no | Converts enums for this mapping unless global conversion already applies. |
| `naming_scheme` | enum | `pathedWithTypes` | no | Controls nested class names. `simple` can collide. |

## Naming scheme values

| Value | Generated-name context | Use this when |
|---|---|---|
| `pathedWithTypes` | Parent GraphQL type path | Default choice; strongest collision resistance. |
| `pathedWithFields` | Parent field path | Field paths better distinguish operation-specific shapes. |
| `simple` | Current type only | Only when the schema and selections cannot produce duplicate class names. |

## Scalar mapping fields

A scalar entry pairs `graphql_type` with a simple Dart type string or a structured Dart type definition. Structured definitions can declare the type `name` and required `imports`. `custom_parser_import` points generated `JsonKey` annotations at application-owned conversion functions.

<span class="filename">build.yaml</span>

```yaml
scalar_mapping:
  - graphql_type: DateTime
    dart_type: DateTime
  - graphql_type: Decimal
    dart_type:
      name: Decimal
      imports:
        - package:decimal/decimal.dart
    custom_parser_import: package:your_app/graphql/parsers.dart
```

Parser names encode source type, destination type, list layers, and nullability. See [GraphQL features](../../graphql-features/) for an exact generated name.

## Output and source rules

Output is derived automatically from `queries_glob`. `lib/graphql/viewer.graphql` produces `lib/__generated__/viewer.graphql.dart` and its `.g.dart`. Broad globs can yield surprising basenames, so exact operation paths are recommended.

All schema, query, and fragment matches must be visible through the target `sources`. See [configuration](../../configuration/) for a practical workflow and [troubleshooting](../../troubleshooting/) for exact validation errors.
