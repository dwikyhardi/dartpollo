---
layout: ../layouts/DocsLayout.astro
title: Configuration
description: Build a practical schema mapping and choose generator options deliberately.
---

<header class="page-lead">

# Configuration

Configure one predictable schema-to-operation mapping before expanding to fragments, multiple schemas, or broader globs.

</header>

## Start with one exact mapping

Use an exact operation path when first configuring a package or diagnosing output placement.

<span class="filename">build.yaml</span>

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
          schema_mapping:
            - schema: schema.graphql
              queries_glob: lib/graphql/viewer.graphql
```

Every schema, operation, and fragment must also be included by the target's `sources`. A valid glob outside those sources is invisible to `build_runner`.

## Add shared behavior deliberately

Top-level values apply across mappings. Mapping-level values isolate schema-specific behavior.

<span class="filename">build.yaml</span>

```yaml
options:
  generate_helpers: false
  generate_queries: true
  optimize_document_nodes: false
  convert_enum_to_string: false
  ignore_for_file:
    - deprecated_member_use
  fragments_glob: lib/graphql/common/*.graphql
  scalar_mapping:
    - graphql_type: DateTime
      dart_type: DateTime
  schema_mapping:
    - schema: schema.graphql
      queries_glob: lib/graphql/viewer.graphql
      fragments_glob: lib/graphql/viewer-fragments/*.graphql
      type_name_field: __typename
      append_type_name: false
      naming_scheme: pathedWithTypes
```

The observable output is `lib/__generated__/viewer.graphql.dart` plus its `.g.dart` serializer. No supported `output` option exists.

## Understand scope and defaults

Both generation switches default to `true`. `scalar_mapping`, `schema_mapping`, and `ignore_for_file` default to empty lists; `fragments_glob` defaults to null; enum conversion and document optimization default to false.

Mapping defaults are `type_name_field: __typename`, `append_type_name: false`, and `naming_scheme: pathedWithTypes`. Although `schema_mapping` initializes as an empty list, generation requires at least one usable mapping in practice.

See the [generator option reference](../reference/generator-options/) for the exhaustive type/default/scope table.

## Avoid non-obvious traps

- Helpers require documents, so `generate_helpers: true` emits operation constants even if `generate_queries` is false.
- `generate_helpers: false` removes the Dartpollo import and wrapper.
- Global `convert_enum_to_string: true` effectively applies to every mapping.
- `append_type_name` modifies GraphQL selection sets; it does not rename generated Dart types.
- `use_graphql_data_class` is not a current option and should be removed from copied example configuration.
- In `alpha.7`, do not combine `optimize_document_nodes: true` with `generate_helpers: false`.

## Expand only when paths are clear

Broad wildcards can produce surprising basenames because output derivation follows the final glob segment. Multiple operations inside one matched document are supported, but separate operation files keep generated libraries and rebuilds easier to reason about.

Continue with [operations and variables](../operations-and-variables/) or isolate independent APIs with [multiple schemas](../multiple-schemas/). For failures, use [troubleshooting](../troubleshooting/).
