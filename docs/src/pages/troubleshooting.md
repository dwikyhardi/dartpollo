---
layout: ../layouts/DocsLayout.astro
title: Troubleshooting
description: Resolve common Dartpollo Generator configuration, schema, fragment, scalar, and naming errors.
---

<header class="page-lead">

# Troubleshooting

Most generator failures identify a broken boundary between `build.yaml`, the schema, and the operation glob.

</header>

## Missing `schema_mapping`

**Message:** `Missing schema_mapping configuration option`

Add at least one entry under the builder's `options`. Every entry needs both `schema` and `queries_glob`.

## Missing files for a glob

**Message:** `Missing files for <pattern>`

Check all three places:

1. the path is relative to the package root;
2. at least one file matches the glob;
3. the target's `sources` includes the matched files.

Use exact operation paths while debugging broad globs.

## Query glob includes the schema

**Message:** `queries_glob configuration contains the path to the schema file`

Move the schema outside the operation directory or narrow `queries_glob`. A schema document cannot also be processed as an operation.

## Unknown scalar

**Message:** `schema file contains "X" scalar, but this scalar is not configured`

Add `X` to `scalar_mapping`. Built-in mappings cover `Boolean`, `Float`, `ID`, `UUID`, `JSONString`, `Int`, `GenericScalar`, and `String`.

## Missing root type

**Message:** `Can't find the "Query" root type`

Ensure the schema defines `Query`, `Mutation`, or `Subscription`, or declares custom roots explicitly:

```graphql
schema {
  query: RootQuery
  mutation: RootMutation
}
```

## Missing fragment

**Message:** `Can't find the "FragmentName" in "ClassName"`

The fragment must be in the operation document, the mapping's `fragments_glob`, or the global `fragments_glob`. Confirm the fragment file is also included by target `sources`.

## Duplicate generated classes

**Message:** `Two classes were generated with the same name`

Two different selection sets resolved to one Dart class name. Prefer `pathedWithTypes` or `pathedWithFields`, add GraphQL aliases, or separate the operations into different mappings.

## No operation in a GraphQL file

Files matched by `queries_glob` need a query, mutation, or subscription. Fragment-only files belong in `fragments_glob`.

## Missing `.g.dart`

Generated response files contain a `part` directive for JSON serializers. Run the complete builder chain:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Do not run the Dartpollo builder in isolation.

## Generated code imports Dartpollo unexpectedly

`generate_helpers` defaults to `true`. For another client, set:

```yaml
options:
  generate_helpers: false
  generate_queries: true
```

Rebuild after changing the option.

## Stale output after schema changes

Delete conflicts through `build_runner` rather than editing generated files:

```bash
dart run build_runner clean
dart pub get
dart run build_runner build --delete-conflicting-outputs
```

If the error remains, reduce the mapping to one exact schema and one exact operation, then expand it again.

<nav class="page-nav"><a href="../examples/">← Examples</a><a href="https://github.com/dwikyhardi/dartpollo/issues">Open an issue ↗</a></nav>
