---
layout: ../layouts/DocsLayout.astro
title: Configuration
description: Map GraphQL files to generated Dart code and configure shared options.
---

<header class="page-lead">

# Configuration

Use `build.yaml` to choose your schema, operations and generated output.

</header>

## Start with one exact mapping

This configuration generates models and documents for `viewer.graphql`:

<span class="filename">build.yaml</span>

```yaml
targets:
  $default:
    sources:
      - $package$
      - pubspec.yaml
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

The output is `lib/__generated__/viewer.graphql.dart` and its `.g.dart` serializer. Include every schema, operation and fragment file in the target's `sources`.

## Add shared options

Options outside `schema_mapping` apply to all mappings. Each mapping can also set its own fragments, naming scheme and type discriminator:

<span class="filename">build.yaml</span>

```yaml
options:
  generate_helpers: false
  generate_queries: true
  optimize_document_nodes: false
  scalar_mapping:
    - graphql_type: DateTime
      dart_type: DateTime
  schema_mapping:
    - schema: schema.graphql
      queries_glob: lib/graphql/viewer.graphql
      fragments_glob: lib/graphql/fragments/*.graphql
      naming_scheme: pathedWithTypes
      type_name_field: __typename
      append_type_name: false
```

Use `generate_helpers: true` for the Dartpollo client. Keep it false for clients such as `package:graphql`. Leave `optimize_document_nodes` false in `alpha.6`; see [document limitations](../reference/generated-api/#documents-and-names).

The [option reference](../reference/generator-options/) lists every setting and default.

## Add more operations

Each mapping produces one library containing all of its matched operations. Use a separate exact-path mapping for each file when you want separate generated libraries. See [project organization](../multiple-schemas/#organize-several-operations) for a folder tree and shared fragments.

## Refresh the schema and regenerate

Save your API's schema as a local SDL file. For GitHub, follow the [schema download instructions](../guides/github/#fetch-the-sdl-safely); for other APIs, use their SDL export or an introspection-to-SDL tool.

Keep the schema and operations in version control so builds use the same inputs. After changing either file, a fragment or the configuration, regenerate and check your application:

```bash
dart run build_runner build
dart analyze --fatal-infos
dart test
```

Review changes to generated types, especially removed fields and changed nullability. If you commit generated files, include their updates with the schema changes. See [troubleshooting](../troubleshooting/#stale-output) if old output remains after a build.

## Releases and upgrades

These guides use **0.1.0-alpha.6** and require Dart `^3.10.0`. Before upgrading, read the [generator](https://github.com/dwikyhardi/dartpollo/blob/main/packages/dartpollo_generator/CHANGELOG.md), [runtime](https://github.com/dwikyhardi/dartpollo/blob/main/packages/dartpollo/CHANGELOG.md) and [annotation](https://github.com/dwikyhardi/dartpollo/blob/main/packages/dartpollo_annotation/CHANGELOG.md) changelogs. Prerelease updates may change the generated API.

Choose a version available on pub.dev, update your package constraints, then run `dart pub get`, regenerate and run your tests.

### Test an unreleased checkout

To work on Dartpollo itself, follow the [local package setup](https://github.com/dwikyhardi/dartpollo/tree/main/docs/examples/developer-guide#test-local-packages). It explains path dependencies and the annotation override needed for the checkout.
