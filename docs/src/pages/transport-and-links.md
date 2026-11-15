---
layout: ../layouts/DocsLayout.astro
title: Transport and links
description: Configure Dio, authentication, GET requests, custom links, subscriptions, and ownership.
---

<header class="page-lead">

# Transport and links

Configure HTTP requests with Dio, or provide custom links for routing and subscriptions.

</header>

## Configure Dio

Pass a `Dio` instance to configure authentication, timeouts, proxies or logging.

<span class="filename">lib/graphql_transport.dart</span>

```dart
import 'package:dartpollo/dartpollo.dart';
import 'package:dio/dio.dart';

final dio = Dio(
  BaseOptions(connectTimeout: const Duration(seconds: 10)),
)
  ..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.headers['Authorization'] = 'Bearer ${await readToken()}';
        handler.next(options);
      },
    ),
  );

final client = DartpolloClient(
  'https://api.example.com/graphql',
  client: dio,
  useGETForQueries: true,
);
```

`useGETForQueries` applies only to query operations; mutations continue to use POST. GET URLs can expose variables in browser, proxy, and server logs, and large operations can exceed URL limits, so enable it only when the endpoint and intermediaries support it.

Static `defaultHeaders` are useful for fixed values. Prefer a Dio interceptor for rotating credentials because it runs when each request is sent.

## Compose a link chain

The standard client factory composes `DedupeLink` with `DioLink`. Build that chain explicitly when you need another link before or after transport.

<span class="filename">lib/graphql_links.dart</span>

```dart
import 'package:dartpollo/dartpollo.dart';
import 'package:gql_dio_link/gql_dio_link.dart';
import 'package:gql_dedupe_link/gql_dedupe_link.dart';
import 'package:gql_link/gql_link.dart';

final httpLink = DioLink(
  'https://api.example.com/graphql',
  client: dio,
);

final link = Link.from([
  DedupeLink(),
  httpLink,
]);

final client = DartpolloClient.fromLink(link);
```

Requests pass through links from left to right; responses return in the opposite direction. The Dio interceptor above adds the authorization header.

Import each custom link from its own package. Forward the document, variables, operation name and context so later links receive a complete request.

## Subscriptions and multiple responses

`DioLink` is an HTTP transport. For subscriptions, route subscription requests to a subscription-capable application link and send queries and mutations to the Dio chain, then pass the combined link to `DartpolloClient.fromLink`.

Consume `client.stream(...)` for subscriptions, multipart responses, and any link that emits more than once. `client.execute(...)` awaits only the first event and then stops listening, so it cannot represent later subscription events.

## Cancellation

Attach a Dio cancel token through request context when using `DioLink`.

<span class="filename">lib/viewer_request.dart</span>

```dart
import 'package:dartpollo/dartpollo.dart';
import 'package:gql_dio_link/gql_dio_link.dart';
import 'package:dio/dio.dart';
import 'package:gql_exec/gql_exec.dart';

final cancelToken = CancelToken();

final pending = client.execute(
  ViewerQuery(),
  context: const Context().withCancelToken(cancelToken),
);

cancelToken.cancel('Viewer screen disposed');
```

Cancellation is cooperative. `DioLink` reads this context entry, but a custom transport or intermediate link must preserve and explicitly support it; cancelling the token does not guarantee that an upstream server stops work already accepted.

## Resource ownership

Call `dispose()` when the client is no longer used. A client created by the endpoint factory closes the inline Dio transport it created; a client created with `fromLink` does not assume ownership of application-provided links, sockets, stores, or other resources.

Keep references to custom transports and close them according to their own APIs after active streams have ended. Avoid disposing shared Dio or subscription links while another client still uses them.