---
layout: ../layouts/DocsLayout.astro
title: Use package:graphql
description: Execute Dartpollo-generated documents and parse typed results with package:graphql 5.2.4.
---

<header class="page-lead">

# Use package:graphql

Send generated documents with `package:graphql` and receive typed results.

</header>

## Install dependencies

Start from [Getting started](../getting-started/). Keep its schema, Viewer operation and `build.yaml`, then add `graphql`:

Use this client without the Dartpollo runtime; their [link dependencies conflict](../integration-modes/#client-compatibility).

<span class="filename">pubspec.yaml</span>

```yaml
dependencies:
  equatable: ^2.0.8
  gql: ^1.0.1
  graphql: ^5.2.4
  json_annotation: ^4.12.0

dev_dependencies:
  build_runner: ^2.10.0
  dartpollo_generator: 0.1.0-alpha.6
  json_serializable: ^6.11.0
```

## Configure the generator

<span class="filename">build.yaml</span>

```yaml
options:
  generate_helpers: false
  generate_queries: true
  optimize_document_nodes: false
```

This generates documents, typed variables and response models. Keep optimization false because of the [document limitations](../reference/generated-api/#documents-and-names).

## Execute a typed query

The Viewer fields from Getting started also exist on GitHub. Save this complete program beside your generated directory:

<span class="filename">lib/github.dart</span>

<!-- example: lib/github.dart -->
```dart
import 'dart:io';

import 'package:graphql/client.dart';

import '__generated__/viewer.graphql.dart';

Future<Viewer$Query> loadViewer(GraphQLClient client) async {
  final result = await client.query<Viewer$Query>(
    QueryOptions<Viewer$Query>(
      document: VIEWER_QUERY_DOCUMENT,
      operationName: VIEWER_QUERY_DOCUMENT_OPERATION_NAME,
      parserFn: Viewer$Query.fromJson,
      fetchPolicy: FetchPolicy.noCache,
    ),
  );
  if (result.hasException) throw result.exception!;
  final viewer = result.parsedData;
  if (viewer == null) throw StateError('GitHub returned no viewer data');
  return viewer;
}

Future<void> main() async {
  final token = Platform.environment['GITHUB_TOKEN'];
  if (token == null || token.isEmpty) {
    throw StateError('Set GITHUB_TOKEN before running this example');
  }

  final httpLink = HttpLink('https://api.github.com/graphql');
  final link = AuthLink(getToken: () async => 'Bearer $token').concat(httpLink);
  final client = GraphQLClient(link: link, cache: GraphQLCache());

  try {
    final viewer = await loadViewer(client);
    print(viewer.viewer.login);
  } finally {
    await httpLink.dispose();
  }
}
```

Set `GITHUB_TOKEN` in your environment, then run:

```bash
dart pub get
dart run build_runner build
dart run lib/github.dart
```

The program prints your GitHub login. Before adding other GitHub operations, [download the full schema](../guides/github/#fetch-the-sdl-safely).

`document` takes the generated `DocumentNode` directly. `parserFn` converts response data into `Viewer$Query`, available through `parsedData`. This example uses `FetchPolicy.noCache`; [configure normalized caching](#normalized-caching) when you need it.

The following snippets run inside an async function with a configured client and the matching generated imports.

## Send generated variables

<span class="filename">lib/search.dart</span>

```dart
final variables = SearchRepositoriesArguments(query: 'flutter');

final result = await client.query<SearchRepositories$Query>(
  QueryOptions<SearchRepositories$Query>(
    document: SEARCH_REPOSITORIES_QUERY_DOCUMENT,
    operationName:
        SEARCH_REPOSITORIES_QUERY_DOCUMENT_OPERATION_NAME,
    variables: variables.toJson(),
    parserFn: SearchRepositories$Query.fromJson,
  ),
);
```

`toJson()` converts the arguments to GraphQL variable values. Check `hasException` before using `parsedData`.

## Mutations and subscriptions

Mutations use `MutationOptions<T>` with `client.mutate<T>(...)`; pass the generated document, name, `variables.toJson()`, and response factory in the same positions.

Subscriptions use `SubscriptionOptions<T>` with `client.subscribe<T>(...)`. The configured link must support the server's subscription protocol; `HttpLink` alone is not a subscription transport.

## Normalized caching

`GraphQLCache` stores entities by identity. Select `__typename` and the identifier fields needed by your cache configuration. Interfaces and unions may also need `possibleTypes` so the cache can match fragments to concrete types.

Continue with the [GitHub tutorial](../guides/github/) for schema preparation and union parsing, or compare the optional [Dartpollo client](../dartpollo-client/).
