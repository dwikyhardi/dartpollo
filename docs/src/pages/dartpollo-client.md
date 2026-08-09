---
layout: ../layouts/DocsLayout.astro
title: Dartpollo client
description: Execute generated GraphQLQuery helpers with the optional Dartpollo runtime client.
---

<header class="page-lead">

# Dartpollo client

`DartpolloClient` is an optional `gql_link` runner for generated helpers. Use it when its Dio transport and link composition match your application.

</header>

## Install

Keep generator packages under development dependencies and add the client at runtime.

```yaml
dependencies:
  dartpollo: ^0.1.0-alpha.7

dev_dependencies:
  build_runner: ^2.10.0
  dartpollo_generator: ^0.1.0-alpha.7
```

Leave `generate_helpers: true` so operations generate `GraphQLQuery` subclasses.

## Create and execute

```dart
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

## Cancellation

```dart
final token = CancelToken();

final pending = client.execute(
  ViewerQuery(),
  context: const Context().withCancelToken(token),
);

token.cancel('Screen disposed');
```

Cancellation is implemented through a Dio link context entry. A custom non-Dio link must explicitly support that entry.

## Custom Dio

Pass an existing `Dio` for interceptors, dynamic authentication, timeouts, proxies, or logging.

```dart
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

```dart
final link = Link.from([
  DedupeLink(),
  AuthLink(getToken: readToken),
  DioLink(endpoint),
]);

final client = DartpolloClient.fromLink(link);
```

When using `fromLink`, your application owns link resources; `dispose()` closes only the inline `DioLink` created by the factory constructor.

<nav class="page-nav"><a href="../graphql-features/">← GraphQL features</a><a href="../caching/">Caching →</a></nav>
