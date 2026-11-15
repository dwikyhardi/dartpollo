---
layout: ../layouts/DocsLayout.astro
title: Dartpollo client
description: Execute generated GraphQLQuery helpers with the optional Dartpollo runtime client.
---

<header class="page-lead">

# Dartpollo client

Execute generated query helpers with the optional Dartpollo HTTP client.

</header>

## Install

Start with [Getting started](../getting-started/), then add `dartpollo` as shown below. Use it without `graphql` 5.2.x; their [link dependencies conflict](../integration-modes/#client-compatibility).

<span class="filename">pubspec.yaml</span>

```yaml
dependencies:
  dartpollo: 0.1.0-alpha.6
  equatable: ^2.0.8
  gql: ^1.0.1
  json_annotation: ^4.12.0

dev_dependencies:
  build_runner: ^2.10.0
  dartpollo_generator: 0.1.0-alpha.6
  json_serializable: ^6.11.0
```

Change `generate_helpers` to `true` in the complete quickstart configuration; keep `generate_queries: true` and `optimize_document_nodes: false`. Run `dart pub get` and `dart run build_runner build` again to generate `ViewerQuery`.

## Create and execute

This program sends the Viewer query from Getting started to GitHub:

<span class="filename">lib/main.dart</span>

```dart
import 'dart:io';

import 'package:dartpollo/dartpollo.dart';

import '__generated__/viewer.graphql.dart';

Future<void> main() async {
  final token = Platform.environment['GITHUB_TOKEN'];
  if (token == null || token.isEmpty) {
    throw StateError('Set GITHUB_TOKEN before running this example');
  }
  final client = DartpolloClient(
    'https://api.github.com/graphql',
    defaultHeaders: {'Authorization': 'Bearer $token'},
  );
  try {
    final response = await client.execute(ViewerQuery());
    if (response.hasErrors) throw StateError('GraphQL: ${response.errors}');
    final data = response.data;
    if (data == null) throw StateError('GitHub returned no viewer data');
    print(data.viewer.login);
  } finally {
    client.dispose();
  }
}
```

With `GITHUB_TOKEN` set in your environment, run `dart run lib/main.dart`. Subsequent snippets are excerpts using this client or application-owned values.

## Responses and failures

`GraphQLResponse<T>` contains typed `data`, GraphQL `errors`, `hasErrors`, and the link `Context`.

GraphQL protocol errors are response values; transport, link, timeout, cancellation, and parsing failures are thrown. Partial non-null data is still parsed when GraphQL errors are present.

<span class="filename">lib/viewer_error_handling.dart</span>

```dart
try {
  final response = await client.execute(ViewerQuery());
} on DioLinkServerException catch (error) {
  print(error.statusCode);
} on DioLinkTimeoutException {
  // Retry or report a timeout.
} on DioLinkCanceledException {
  // Request was cancelled.
} on DioLinkParserException {
  // The transport response could not be parsed.
}
```

## Execute versus stream

- `execute` consumes the first event from the link stream.
- `stream` maps every event through the generated parser.

Use `stream` for subscriptions, multipart/custom streaming links, and `cacheAndNetwork`, where more than one value matters.

Cancel stream subscriptions when you stop using them.

## Cancellation

<span class="filename">lib/viewer_request.dart</span>

```dart
import 'package:gql_dio_link/gql_dio_link.dart';
import 'package:dio/dio.dart';
import 'package:gql_exec/gql_exec.dart';

final token = CancelToken();

final pending = client.execute(
  ViewerQuery(),
  context: const Context().withCancelToken(token),
);

token.cancel('Screen disposed');
```

The cancel token works with Dio transport. A custom transport must implement its own cancellation support.

## Custom Dio

Pass an existing `Dio` for interceptors, dynamic authentication, timeouts, proxies, or logging.

<span class="filename">lib/graphql_client.dart</span>

```dart
import 'package:dartpollo/dartpollo.dart';
import 'package:dio/dio.dart';

final dio = Dio()
  ..interceptors.add(AuthInterceptor());

final client = DartpolloClient(
  endpoint,
  client: dio,
  useGETForQueries: true,
  serializableErrors: true,
);
```

## Custom link chain

Custom link packages are separate dependencies; import each link from the package that defines it.

<span class="filename">lib/graphql_links.dart</span>

```dart
import 'package:dartpollo/dartpollo.dart';
import 'package:gql_dio_link/gql_dio_link.dart';
import 'package:gql_dedupe_link/gql_dedupe_link.dart';
import 'package:gql_link/gql_link.dart';

final link = Link.from([
  DedupeLink(),
  DioLink(endpoint, client: dio),
]);

final client = DartpolloClient.fromLink(link);
```

Links process requests in order. Custom links must forward the request context so features such as cancellation keep working.

With `fromLink`, close your custom links and transports yourself. See [resource ownership](../transport-and-links/#resource-ownership).
