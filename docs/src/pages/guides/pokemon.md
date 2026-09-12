---
layout: ../../layouts/DocsLayout.astro
title: Pokémon tutorial
description: Run the committed Pokémon example from local SDL through generation and typed execution.
---

<header class="page-lead">

# Pokémon tutorial

Generate and execute typed Pokémon queries from repository files without fetching a schema or creating an API token.

</header>

## Prerequisites

Use this tutorial for the shortest end-to-end generator and optional-client path.

- Dart SDK `^3.10.0`
- A checkout of this repository
- Network access to install packages and execute the public Pokémon endpoint

Start in `packages/dartpollo/example/pokemon`.

## Inspect the local schema

Open `pokemon.schema.graphql` and find the `Query` fields used by the example: `pokemon(name:)` and `pokemons(first:)`. The builder reads this committed SDL locally; no introspection occurs during generation.

## Inspect the first operation

<span class="filename">graphql/simple_query.query.graphql</span>

```graphql
query simple_query {
  pokemon(name: "Charmander") {
    number
    types
  }
}
```

The operation is named, so its symbols remain predictable even though the GraphQL name uses snake case.

## Read each mapping

<span class="filename">build.yaml</span>

```yaml
options:
  optimize_document_nodes: true
  fragments_glob: graphql/**.fragment.graphql
  schema_mapping:
    - schema: pokemon.schema.graphql
      queries_glob: graphql/simple_query.query.graphql
    - schema: pokemon.schema.graphql
      queries_glob: graphql/big_query.query.graphql
    - schema: pokemon.schema.graphql
      queries_glob: graphql/fragment_query.query.graphql
    - schema: pokemon.schema.graphql
      queries_glob: graphql/fragments_glob.query.graphql
```

All four mappings use the same schema and exact operation paths. The global fragment glob makes committed fragment files available to each mapping.

The repository file also contains `use_graphql_data_class`. That key is currently unsupported and ignored; do not copy or teach it as an option.

## Install and generate

<span class="filename">Terminal</span>

```bash
cd packages/dartpollo/example/pokemon
dart pub get
dart run build_runner build --delete-conflicting-outputs
```

Inspect these outputs:

<span class="filename">Expected generated files</span>

```text
lib/__generated__/simple_query.graphql.dart
lib/__generated__/simple_query.graphql.g.dart
lib/__generated__/big_query.graphql.dart
lib/__generated__/big_query.graphql.g.dart
```

The first library contains `SimpleQuery$Query`, `SIMPLE_QUERY_QUERY_DOCUMENT`, and `SimpleQueryQuery`.

## Execute the basic query

<span class="filename">lib/main.dart</span>

```dart
final client = DartpolloClient('https://graphql-pokemon2.vercel.app');
final response = await client.execute(SimpleQueryQuery());
print(response.data?.pokemon?.number);
client.dispose();
```

Run the committed example:

<span class="filename">Terminal</span>

```bash
dart run lib/main.dart
```

Success means the program prints the simple-query response and a list of Pokémon without a generation or parsing error.

## Add typed variables and aliases

<span class="filename">graphql/big_query.query.graphql</span>

```graphql
query big_query($quantity: Int!) {
  charmander: pokemon(name: "Charmander") {
    number
    types
  }
  pokemons(first: $quantity) {
    number
    name
  }
}
```

Construct the required variable through the generated argument type:

<span class="filename">lib/main.dart</span>

```dart
final query = BigQueryQuery(
  variables: BigQueryArguments(quantity: 5),
);
final response = await client.execute(query);
print(response.data?.charmander?.number);
```

The alias `charmander` determines the generated response property. After this works, inspect `fragment_query.query.graphql` and `fragments_glob.query.graphql`, then continue with the [fragments guide](../../fragments/).

> **Troubleshooting:** If generation reports missing files, confirm the current directory is the Pokémon package and that `graphql/**` plus `pokemon.schema.graphql` remain in the target `sources`. Use the [troubleshooting reference](../../troubleshooting/) for exact messages.
