---
layout: ../layouts/DocsLayout.astro
title: Generated output
description: Read generated response models, arguments, serializers, documents, helpers, and output paths.
---

<header class="page-lead">

# Generated output

Identify every generated artifact and predict its Dart shape from the operation's fields, aliases, lists, and nullability.

</header>

## Response models follow the selection

Use generated response types instead of recreating API models by hand.

<span class="filename">lib/graphql/viewer.graphql</span>

```graphql
query Viewer {
  viewer {
    login
  }
}
```

The committed GitHub output exposes `Viewer$Query`. Nested type names depend on the configured naming scheme and the path through the selection set.

<span class="filename">lib/main.dart</span>

```dart
final data = Viewer$Query.fromJson(json);
print(data.viewer.login);
final roundTrip = data.toJson();
```

Response classes provide `fromJson`, `toJson`, and equality props through generated serialization and Equatable support.

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

With helpers enabled, `ViewerQuery` and `SearchRepositoriesQuery` extend the Dartpollo `GraphQLQuery` boundary. They expose the document, operation name, serialized variables, and response parser.

<span class="filename">lib/main.dart</span>

```dart
final response = await client.execute(
  SearchRepositoriesQuery(
    variables: SearchRepositoriesArguments(query: 'flutter'),
  ),
);
```

Disable helpers for client-independent output. In `alpha.7`, optimized documents are not compatible with that generator-only import set.

## Generated files are disposable

`lib/graphql/viewer.graphql` maps to `lib/__generated__/viewer.graphql.dart` and `lib/__generated__/viewer.graphql.g.dart`. The main file contains generated headers, annotations, models, and documents; the part file contains serializers. Never edit either file directly—change schema, operations, or configuration and rebuild.

Continue with [fragments](../fragments/) and [GraphQL features](../graphql-features/), or use the [generated API reference](../reference/generated-api/) for exact naming patterns.
