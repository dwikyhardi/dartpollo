---
layout: ../layouts/DocsLayout.astro
title: Dartpollo client
description: Execute generated GraphQLQuery helpers with the optional Dartpollo runtime client.
---

<header class="page-lead">

# Dartpollo client

Use the optional `DartpolloClient` when you want a small `gql_link` runner that turns generated operation helpers into typed response values.

</header>

## Install

Keep generator packages under development dependencies and add the client at runtime.

<span class="filename">pubspec.yaml</span>

```yaml
dependencies:
  dartpollo: ^0.1.0-alpha.7

dev_dependencies:
  build_runner: ^2.10.0
  dartpollo_generator: ^0.1.0-alpha.7
```

Leave `generate_helpers: true` so operations generate `GraphQLQuery` subclasses.

## Create and execute

The endpoint factory composes `DedupeLink` and `DioLink` for you.

<span class="filename">lib/graphql_client.dart</span>

```dart
import 'package:dartpollo/dartpollo.dart';

final client = DartpolloClient(
  'https://api.example.com/graphql',
  defaultHeaders: {'Authorization': 'Bearer $token'},
);

final response = await client.execute(ViewerQuery());

if (response.hasErrors) {
  print(response.errors);
}

print(response.data?.viewer.login);
client.dispose();
```

`execute` builds a `gql_exec.Request`, waits for the first link response, and calls the generated query's `parse` method when `data` is non-null.

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

Dispose the returned stream subscription when its consumer ends. Disposing the client does not replace ownership of each listener created by application code.

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

Cancellation is implemented through a Dio link context entry. A custom non-Dio link must preserve and explicitly support that entry, and cancellation cannot guarantee that a server stops work it already accepted.

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

Link order matters, and custom links must forward request context when they do not intentionally modify it. Add rotating authentication through the application-owned Dio interceptor shown above, or through a separate link package that explicitly supports your authentication model.

When using `fromLink`, your application owns link resources; `dispose()` closes only the inline `DioLink` created by the endpoint factory. Close application-owned Dio clients, subscription transports, stores, and stream subscriptions according to their own lifecycles.
