---
layout: ../layouts/DocsLayout.astro
title: Multiple schemas
description: Isolate schema mappings, output paths, fragments, naming, enum behavior, and type discriminators.
---

<header class="page-lead">

# Multiple schemas

Use separate mappings for different APIs or groups of operations.

</header>

## Create one mapping per operation set

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

Each mapping can set its own fragments, naming scheme, enum handling and type discriminator.

## Generated paths

Output paths are generated automatically. This operation path:

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

## Organize several operations

Each mapping combines its matched operations into one library. Use exact file paths for separate outputs: `lib/graphql/*.graphql` produces a literal `*.graphql.dart` basename in `alpha.6`.

For example, two operations can share a fragment and generate separate libraries:

```text
schema.graphql
lib/
├── graphql/
│   ├── viewer.graphql
│   ├── update_viewer.graphql
│   └── fragments/user_identity.graphql
└── __generated__/
    ├── viewer.graphql.dart
    ├── viewer.graphql.g.dart
    ├── update_viewer.graphql.dart
    └── update_viewer.graphql.g.dart
```

Under your existing builder options, configure these two entries:

```yaml
schema_mapping:
  - schema: schema.graphql
    queries_glob: lib/graphql/viewer.graphql
  - schema: schema.graphql
    queries_glob: lib/graphql/update_viewer.graphql
    fragments_glob: lib/graphql/fragments/*.graphql
```

The mutation spreads `UserIdentity` for its `id` and `login` selections. The fragment file contains no operation and belongs only in `fragments_glob`. Both operations and fragments are covered by the quickstart's `lib/**` target sources.

Application files under `lib/` can import each generated library directly:

```dart
import '__generated__/viewer.graphql.dart';
import '__generated__/update_viewer.graphql.dart';
```

Use Dart import prefixes when libraries expose the same type name. If mappings produce the same output path, give their operation files distinct filenames.

## Prevent collisions

The default `pathedWithTypes` naming scheme includes parent type names to reduce collisions.

The `simple` scheme uses less context and is collision-prone. If two different classes receive the same generated name, use `pathedWithTypes`, introduce meaningful GraphQL aliases, or separate operations into different mapped documents.

## Shared options

Top-level `fragments_glob` exposes fragments to every mapping, and top-level `convert_enum_to_string: true` effectively converts enums for all mappings. Put schema-specific behavior inside each mapping instead.

Share a scalar mapping only when the APIs use the same wire format for that scalar. If their formats differ, generate code in separate packages.

See the [option reference](../reference/generator-options/) for settings available to each mapping.
