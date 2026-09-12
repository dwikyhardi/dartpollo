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

This produces `Viewer$Query`, `VIEWER_QUERY_DOCUMENT`, `VIEWER_QUERY_DOCUMENT_OPERATION_NAME`, and—when helpers are enabled—`ViewerQuery`. Anonymous operations have a fallback name, but should not be the normal authoring style.

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

The generated argument class supplies `fromJson`, `toJson`, and equality props. Pass `json` to another client, or pass `variables` to the generated `SearchRepositoriesQuery` helper.

## Generate mutations

Mutations use the same response and argument pipeline:

<span class="filename">lib/graphql/update_viewer.graphql</span>

```graphql
mutation UpdateViewer($input: UpdateViewerInput!) {
  updateViewer(input: $input) {
    viewer {
      login
    }
  }
}
```

The output contains an `UpdateViewerArguments` object and an `UpdateViewerMutation` helper when helpers are enabled. Cache links do not automatically distinguish mutations; execute them without cache and evict affected query entries explicitly.

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

Multiple operations are supported, but one operation per file usually yields clearer generated imports and output ownership. Fragments may be shared between them; only transitively referenced fragments enter each operation document.

Continue with [generated output](../generated-output/) to inspect nullability and naming, [fragments](../fragments/) for shared selections, or the [generated API reference](../reference/generated-api/) for exact symbol patterns.
