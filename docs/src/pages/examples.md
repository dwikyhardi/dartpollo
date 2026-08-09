---
layout: ../layouts/DocsLayout.astro
title: Examples
description: Learn Dartpollo Generator through the repository Pokémon, GitHub, and multi-operation examples.
---

<header class="page-lead">

# Examples

The repository examples are executable references. Each one demonstrates a different generator concern.

</header>

## Pokémon

Use the Pokémon example first. It has a committed schema and operations, so no API token or schema download is required.

```bash
cd packages/dartpollo/example/pokemon
dart pub get
dart run build_runner build --delete-conflicting-outputs
dart run lib/main.dart
```

It demonstrates:

- multiple mappings against one schema;
- operation variables;
- shared fragments;
- optimized document output;
- generated response parsing and execution.

Review [`packages/dartpollo/example/pokemon/build.yaml`](https://github.com/dwikyhardi/dartpollo/tree/main/packages/dartpollo/example/pokemon) beside its `graphql/` and `lib/__generated__/` directories.

## GitHub GraphQL API

The GitHub example adds real authentication, a large external schema, custom scalars, and a custom Dio instance.

```bash
dart run tool/fetch_schema.dart \
  -e https://api.github.com/graphql \
  -o packages/dartpollo/example/github/github.schema.graphql \
  -a "Bearer YOUR_GITHUB_TOKEN"

cd packages/dartpollo/example/github
dart run build_runner build --delete-conflicting-outputs
GITHUB_TOKEN=your_token dart run lib/main.dart
```

The generator consumes the downloaded SDL file; it does not fetch a remote schema during normal builds.

## Multiple operations and deeper paths

The `monit` fixture exercises mutations, shared fragments, multiple operation files, and deeper operation directories. Its generated `__generated__` folder shows how automatic output placement follows the query glob.

## Build your own guide

When adapting an example:

1. Replace the schema.
2. Add one named operation.
3. Use an exact query path for the first `schema_mapping`.
4. Generate and inspect the symbols.
5. Broaden globs only after output placement is clear.

<nav class="page-nav"><a href="../caching/">← Caching</a><a href="../troubleshooting/">Troubleshooting →</a></nav>
