---
layout: ../layouts/DocsLayout.astro
title: Generated output
description: Read generated response models, arguments, serializers, documents, helpers, and output paths.
---

<header class="page-lead">

# Generated output

See how operation fields become Dart models, variables and documents.

</header>

## Response models follow the selection

<span class="filename">lib/graphql/viewer.graphql</span>

```graphql
query Viewer {
  viewer {
    login
  }
}
```

This query generates `Viewer$Query`. Nested type names include the parent type path by default.

<span class="filename">lib/main.dart</span>

```dart
final data = Viewer$Query.fromJson(json);
print(data.viewer.login);
final roundTrip = data.toJson();
```

Response classes provide `fromJson`, `toJson`, and value equality through Equatable.

## Nullability stays visible

- GraphQL non-null fields become required, non-null Dart fields.
- Nullable fields become nullable Dart fields.
- List nullability and item nullability are modeled independently.
- GraphQL non-null input values become required named constructor parameters.

<span class="filename">schema.graphql</span>

```graphql
type Query {
  names: [String!]!
  nicknames: [String]
}
```

The generated shapes are equivalent to `List<String>` for `names` and `List<String?>?` for `nicknames`.

## Aliases become Dart paths

The Pokémon `big_query` aliases a selected Pokémon as `charmander`:

<span class="filename">big_query.query.graphql</span>

```graphql
charmander: pokemon(name: "Charmander") {
  name
}
```

The response property follows the alias, so application code reads `data.charmander`. Aliases can also resolve generated-name collisions without changing the wire field selected from the server.

## Arguments and constants

With `generate_queries: true`, the GitHub output includes:

- `SearchRepositoriesArguments` for variables;
- `SEARCH_REPOSITORIES_QUERY_DOCUMENT` for the AST;
- `SEARCH_REPOSITORIES_QUERY_DOCUMENT_OPERATION_NAME` for operation selection.

<span class="filename">lib/main.dart</span>

```dart
final variables = SearchRepositoriesArguments(query: 'flutter');
final document = SEARCH_REPOSITORIES_QUERY_DOCUMENT;
```

The document is already a `DocumentNode`; do not wrap it with `gql()`.

## Optional wrappers

With helpers enabled, classes such as `ViewerQuery` extend `GraphQLQuery`. They bundle the document, operation name, variables and parser for the Dartpollo client.

<span class="filename">lib/main.dart</span>

```dart
final response = await client.execute(
  SearchRepositoriesQuery(
    variables: SearchRepositoriesArguments(query: 'flutter'),
  ),
);
```

## Regenerate after changes

Edit your schema, operations or configuration, then rerun `build_runner`. It rewrites the `.graphql.dart` models and documents and the `.graphql.g.dart` serializers.

Continue with [fragments](../fragments/) and [GraphQL features](../graphql-features/), or use the [generated API reference](../reference/generated-api/) for exact naming patterns.
