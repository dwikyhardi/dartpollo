---
layout: ../layouts/DocsLayout.astro
title: Troubleshooting
description: Resolve source-backed Dartpollo Generator, serializer, integration, and cache failures.
---

<header class="page-lead">

# Troubleshooting

Match an exact generator or runtime symptom to the smallest configuration, source, or cache correction.

</header>

## Missing required configuration

**Message:** ``Missing `schema_mapping` configuration option. check `build.yaml` configuration``

Add at least one mapping under the builder's `options`.

**Message:** ``Missing `schema` configuration option. check `build.yaml` configuration``

**Message:** ``Missing `queries_glob` configuration option. check `build.yaml` configuration``

Every mapping requires both local SDL and an operation path or glob.

<span class="filename">build.yaml</span>

```yaml
schema_mapping:
  - schema: schema.graphql
    queries_glob: lib/graphql/viewer.graphql
```

## No files match a glob

**Message:** `Missing files for <pattern>`

Confirm the path is package-relative, at least one file matches, and the build target's `sources` includes it. Reduce wildcards to one exact file while diagnosing.

## Schema matched as an operation

**Message:** ``One of your `queries_glob` configuration contains the path to the `schema` file!``

Move the schema outside the operation path or narrow `queries_glob`. A schema document cannot also be generated as an operation.

## Unknown scalar

**Message:** ``Your `schema` file contains "X" scalar, but this scalar is not configured on `build.yaml`!``

Add `X` to `scalar_mapping`. Built-ins cover `Boolean`, `Float`, `ID`, `UUID`, `JSONString`, `Int`, `GenericScalar`, and `String`.

## Missing operation root

**Message:** `Can't find the "Query" root type.`

The same exception may name `Mutation` or `Subscription`. Ensure the SDL defines the required root or declares its custom name:

<span class="filename">schema.graphql</span>

```graphql
schema {
  query: RootQuery
  mutation: RootMutation
}
```

## Missing fragment

**Message:** `Can't find the "FragmentName" in "ClassName".`

Place the fragment in the operation file, mapping-level `fragments_glob`, or global `fragments_glob`, and include the file in target `sources`.

## Duplicate generated classes

**Message:** ``Two classes were generated with the same name `Name` but with different selection set.``

Prefer `pathedWithTypes` or `pathedWithFields`, add meaningful GraphQL aliases, or split operations into distinct mapped files. The `simple` naming scheme is the most collision-prone.

## GraphQL file has no operation

**Message:** `GraphQL file contains no operations (query, mutation, or subscription).`

Files matched by `queries_glob` need at least one operation. Move fragment-only files to `fragments_glob`.

## Missing serializer part

**Symptom:** The generated `.graphql.dart` references a `.graphql.g.dart` file that does not exist.

Run the complete builder chain, not the Dartpollo builder alone:

<span class="filename">Terminal</span>

```bash
dart pub get
dart run build_runner build
```

## Stale output

**Symptom:** Generated types no longer match the schema or operation after a change.

Do not edit generated files. Clean and rebuild the builder graph:

<span class="filename">Terminal</span>

```bash
dart run build_runner clean
dart pub get
dart run build_runner build
```

Then reduce the mapping to one exact schema and operation if stale conflicts remain.

## Unexpected Dartpollo import

**Symptom:** Generator-only output imports `package:dartpollo/dartpollo.dart`.

`generate_helpers` defaults to true. Disable it and rebuild:

<span class="filename">build.yaml</span>

```yaml
options:
  generate_helpers: false
  generate_queries: true
  optimize_document_nodes: false
```

## Optimized generator-only import failure

**Symptom:** Output references `DocumentNodeHelpers` without the import that defines it.

This is an `alpha.7` limitation when `optimize_document_nodes: true` is combined with `generate_helpers: false`. Leave optimization false for client-independent generation.

## `cacheOnly` execution miss

**Symptom:** `execute` throws `StateError` with `CachePolicy.cacheOnly`.

A cache miss is an empty stream, and `execute` waits for its first event. Use `stream` when an empty result is valid, or choose a policy that can reach the network.

## Cached data crosses users or endpoints

**Symptom:** A response written under one identity or endpoint appears for another.

Cache keys include operation name, printed document, and JSON variables. They exclude endpoint, headers, authenticated user, and arbitrary context. Never share a store namespace across users or endpoints; clear or isolate it when identity changes.

For configuration details, use the [generator option reference](../reference/generator-options/). For runtime behavior, continue with [caching](../caching/).
