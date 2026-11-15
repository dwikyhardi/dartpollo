---
layout: ../layouts/DocsLayout.astro
title: Operations and variables
description: Generate typed queries, mutations, subscriptions, arguments, and multiple named operations.
---

<header class="page-lead">

# Operations and variables

Write named GraphQL operations and turn their variable definitions into typed, JSON-serializable argument objects.

</header>

## Name every operation

Use named operations for predictable symbols, operation selection, logs, and cache keys.

<span class="filename">lib/graphql/viewer.graphql</span>

```graphql
query Viewer {
  viewer {
    login
  }
}
```

This produces `Viewer$Query`, `VIEWER_QUERY_DOCUMENT`, `VIEWER_QUERY_DOCUMENT_OPERATION_NAME` and, with helpers enabled, `ViewerQuery`.

## Pass typed variables

The GitHub example searches repositories through a required string variable:

<span class="filename">lib/graphql/search_repositories.graphql</span>

```graphql
query SearchRepositories($query: String!) {
  search(query: $query, type: REPOSITORY, first: 10) {
    nodes {
      __typename
    }
  }
}
```

GraphQL non-null inputs become required named Dart parameters. Nullable inputs remain optional.

<span class="filename">lib/main.dart</span>

```dart
final variables = SearchRepositoriesArguments(query: 'flutter');
final json = variables.toJson();
```

Pass `json` to your client’s variables parameter, or pass the typed `variables` object to `SearchRepositoriesQuery`.

## Omission, null and defaults

With the default serializer settings, an omitted nullable Dart argument becomes JSON `null`. For this operation:

```graphql
query Users($limit: Int = 10, $size: Int! = 5) {
  users(limit: $limit, size: $size) { id }
}
```

```dart
final variables = UsersArguments(size: 5).toJson();
// {'limit': null, 'size': 5}
```

Sending `limit: null` prevents GraphQL from using the default `10`. The Dart constructor also requires `size`, despite its GraphQL default. GraphQL defaults do not become Dart constructor defaults.

To use the server default with `package:graphql`, remove that variable from the map:

```dart
final variables = UsersArguments(size: 5).toJson();
variables.remove('limit');
// Pass variables to QueryOptions.variables: {'size': 5}.
```

Remove only keys you intend to omit: an explicit null may be needed to clear a value. This technique works when you supply the variables map directly. Generated Dartpollo helpers accept typed arguments and serialize them internally.

Nullable input fields behave the same way. For `bio: String = "Hello"`, `ProfileInput(displayName: 'Ada').toJson()` includes `'bio': null`. Remove `bio` from that nested map to use the schema default. Setting `include_if_null: false` changes serialization globally and prevents you from distinguishing omission from an intentional null.

## Construct a nested mutation input

Add these definitions to the schema from Getting started. The [example project](../examples/#offline-developer-recipes) contains the complete setup.

```graphql
enum Visibility { PUBLIC PRIVATE }

input ProfileInput {
  displayName: String!
  bio: String = "Hello"
}

input UpdateViewerInput {
  profile: ProfileInput!
  visibility: Visibility!
}

type Mutation {
  updateViewer(input: UpdateViewerInput!): User!
}
```

Add `visibility: Visibility!` to `User`. Save the operation and map its exact path just like Viewer:

<span class="filename">lib/graphql/update_viewer.graphql</span>

```graphql
mutation UpdateViewer($input: UpdateViewerInput!) {
  updateViewer(input: $input) {
    id
    login
    visibility
  }
}
```

Import `__generated__/update_viewer.graphql.dart` in your application. Construction uses the generated input and enum types:

```dart
final variables = UpdateViewerArguments(
  input: UpdateViewerInput(
    profile: ProfileInput(displayName: 'Ada', bio: 'Builds Dart tools'),
    visibility: Visibility.public,
  ),
);
```

`variables.toJson()` produces:

```json
{
  "input": {
    "profile": {"displayName": "Ada", "bio": "Builds Dart tools"},
    "visibility": "PUBLIC"
  }
}
```

Inside an async function using the [`package:graphql` client](../graphql-client/):

```dart
final result = await client.mutate<UpdateViewer$Mutation>(
  MutationOptions<UpdateViewer$Mutation>(
    document: UPDATE_VIEWER_MUTATION_DOCUMENT,
    operationName: UPDATE_VIEWER_MUTATION_DOCUMENT_OPERATION_NAME,
    variables: variables.toJson(),
    parserFn: UpdateViewer$Mutation.fromJson,
    fetchPolicy: FetchPolicy.noCache,
  ),
);
if (result.hasException) throw result.exception!;
final data = result.parsedData;
if (data == null) throw StateError('Mutation returned no data');
print(data.updateViewer.visibility);
```

With Dartpollo helpers enabled, use `UpdateViewerMutation(variables: variables)`. If you use `DartpolloCachedClient`, run mutations with `networkOnly` and evict affected query entries; see [mutation caching](../caching/#mutations-and-invalidation).

## Generate subscriptions

<span class="filename">lib/graphql/viewer_changed.graphql</span>

```graphql
subscription ViewerChanged {
  viewerChanged {
    login
  }
}
```

Generation produces typed subscription response data and a `Subscription` helper. Transport support is separate: use a client and link chain that implement your server's subscription protocol, and consume every event rather than only the first.

## Keep multiple operations identifiable

One matched GraphQL document may contain multiple operations. Each named operation receives its own response type and constants in the generated library.

<span class="filename">lib/graphql/account.graphql</span>

```graphql
query Viewer {
  viewer { login }
}

query Repository($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) { id }
}
```

Multiple operations are supported. Use one exact mapping per operation file when you want separate libraries; one mapping aggregates all of its matched files into one library. See [project organization](../multiple-schemas/#organize-several-operations). Fragments may be shared between them; only transitively referenced fragments enter each operation document.

Continue with [generated output](../generated-output/) to inspect nullability and naming, [fragments](../fragments/) for shared selections, or the [generated API reference](../reference/generated-api/) for exact symbol patterns.
