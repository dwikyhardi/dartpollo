---
layout: ../layouts/DocsLayout.astro
title: GraphQL features
description: Generate Dart types for fragments, scalars, enums, abstract types, mutations, and subscriptions.
---

<header class="page-lead">

# GraphQL features

The generator walks each operation against the schema and emits the Dart types that operation reaches.

</header>

## Fragments

Fragments can live beside an operation, in a mapping-specific glob, or in the global `fragments_glob`.

```yaml
options:
  fragments_glob: lib/graphql/common/*.fragment.graphql
  schema_mapping:
    - schema: schema.graphql
      queries_glob: lib/graphql/account/*.graphql
      fragments_glob: lib/graphql/account/fragments/*.graphql
```

Global fragments apply to every mapping. Mapping fragments apply only to that schema/operation pair. A referenced fragment that is not in the operation or either configured glob raises `MissingFragmentException`.

## Custom scalars

Every non-built-in scalar used by an operation needs a mapping.

```yaml
scalar_mapping:
  - graphql_type: DateTime
    dart_type: DateTime
  - graphql_type: JSON
    dart_type:
      name: Map<String, dynamic>
  - graphql_type: Decimal
    dart_type:
      name: Decimal
      imports:
        - package:decimal/decimal.dart
    custom_parser_import: package:your_app/graphql/parsers.dart
```

Add packages referenced by custom imports to your application's dependencies.

## Enums

By default, GraphQL enums become Dart enums. Set `convert_enum_to_string: true` globally or per schema mapping when forward compatibility with unknown server values is more important than enum exhaustiveness.

## Interfaces and unions

Abstract GraphQL types need a runtime type field. Dartpollo uses `__typename` by default. Set `append_type_name: true` when operations do not already select it, or change `type_name_field` for schemas using another resolver field.

## Mutations

Mutations generate response models and typed inputs using the same pipeline as queries. The helper suffix becomes `Mutation` and the operation type is retained in the generated document.

## Subscriptions

Subscriptions generate a `Subscription` helper and typed response model. Transport support belongs to the client. The optional Dartpollo client exposes `stream`, but the configured `Link` must support the subscription protocol you use.

## Multiple schemas

Add one `schema_mapping` entry per operation glob. Mappings can use different schemas, fragments, naming schemes, enum behavior, and type-name fields within the same Dart package.

<nav class="page-nav"><a href="../generated-output/">← Generated output</a><a href="../dartpollo-client/">Optional client →</a></nav>
