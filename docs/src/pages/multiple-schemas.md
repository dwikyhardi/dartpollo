---
layout: ../layouts/DocsLayout.astro
title: Multiple schemas
description: Isolate schema mappings, output paths, fragments, naming, enum behavior, and type discriminators.
---

<header class="page-lead">

# Multiple schemas

Generate operations for independent GraphQL APIs without sharing schema-specific fragments or type behavior accidentally.

</header>

## Create one mapping per operation set

Use separate mappings when a package talks to more than one schema or when operation groups need independent generation behavior.

<span class="filename">build.yaml</span>

```yaml
options:
  generate_helpers: false
  generate_queries: true
  schema_mapping:
    - schema: schemas/github.graphql
      queries_glob: lib/graphql/github/viewer.graphql
      fragments_glob: lib/graphql/github/fragments/*.graphql
      naming_scheme: pathedWithTypes
      type_name_field: __typename
    - schema: schemas/catalog.graphql
      queries_glob: lib/graphql/catalog/products.graphql
      fragments_glob: lib/graphql/catalog/fragments/*.graphql
      convert_enum_to_string: true
      append_type_name: true
```

Each mapping can independently select fragments, enum conversion, discriminator field, discriminator insertion, and naming scheme.

## Predict automatic output

Output is derived from `queries_glob`; there is no `output` option. An exact path such as:

<span class="filename">Mapped operation</span>

```text
lib/graphql/viewer.graphql
```

produces:

<span class="filename">Generated files</span>

```text
lib/__generated__/viewer.graphql.dart
lib/__generated__/viewer.graphql.g.dart
```

The builder derives the output basename from the final glob segment. Broad wildcard patterns can therefore place or name output differently than expected. Prefer exact operation paths until each mapping's result is verified.

## Prevent collisions

Multiple operations inside one matched document are supported. Across complex selection trees, `pathedWithTypes` is the safe naming default because it carries parent type context into nested names.

The `simple` scheme uses less context and is collision-prone. If two different classes receive the same generated name, use `pathedWithTypes`, introduce meaningful GraphQL aliases, or separate operations into different mapped documents.

## Keep global options truly global

Top-level `fragments_glob` exposes fragments to every mapping, and top-level `convert_enum_to_string: true` effectively converts enums for all mappings. Put schema-specific behavior inside each mapping instead.

Global scalar mappings are appropriate only when the same GraphQL scalar name has the same Dart meaning across APIs. If two endpoints use the same scalar name with different wire formats, keep their generated packages or configuration boundaries separate.

Successful isolation means each operation resolves only against its intended schema and writes a distinct generated library. Next, connect those libraries through [`package:graphql`](../graphql-client/) or inspect all naming rules in the [generated API reference](../reference/generated-api/).
