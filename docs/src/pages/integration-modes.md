---
layout: ../layouts/DocsLayout.astro
title: Integration modes
description: Choose between client-independent models, generated GraphQL documents, and Dartpollo client helpers.
---

<header class="page-lead">

# Integration modes

The generator has two independent switches. Choose them from the boundary you want—not from the client you happen to use today.

</header>

## Option matrix

<table class="option-matrix">
  <thead><tr><th>Helpers</th><th>Queries</th><th>Generated output</th><th>Best for</th></tr></thead>
  <tbody>
    <tr><td>false</td><td>false</td><td>Response, input, enum, and fragment models</td><td>Clients that own their request document separately</td></tr>
    <tr><td>false</td><td>true</td><td>Models plus <code>DocumentNode</code>, operation name, and arguments</td><td>Client-independent typed execution</td></tr>
    <tr><td>true</td><td>true</td><td>Everything above plus a <code>GraphQLQuery</code> subclass</td><td><code>DartpolloClient</code> and <code>DartpolloCachedClient</code></td></tr>
    <tr><td>true</td><td>false</td><td>Equivalent helper requirements still cause the operation document to be emitted</td><td>Avoid; helpers need the generated operation</td></tr>
  </tbody>
</table>

Both settings default to `true`.

## Models only

```yaml
options:
  generate_helpers: false
  generate_queries: false
```

This removes the `package:dartpollo/dartpollo.dart` import and the `GraphQLQuery` wrapper. Generated JSON models remain available:

```dart
final viewer = Viewer$Query.fromJson(responseData);
```

Choose this when another tool owns the query document or when you want the smallest generated API.

## Client-independent documents

```yaml
options:
  generate_helpers: false
  generate_queries: true
```

In addition to models, the generator emits:

```dart
final VIEWER_QUERY_DOCUMENT_OPERATION_NAME = 'Viewer';
final VIEWER_QUERY_DOCUMENT = DocumentNode(/* generated AST */);
```

Pass the document, operation name, and generated variables map to a client that accepts `gql` AST documents. Deserialize `response.data` with `Viewer$Query.fromJson`.

> Client APIs differ. Dartpollo generates the typed boundary; adapting a `DocumentNode` and response map to a third-party client is application code.

## Dartpollo helper

```yaml
options:
  generate_helpers: true
  generate_queries: true
```

The generated class extends `GraphQLQuery<Response, Variables>` and provides `document`, `operationName`, `getVariablesMap`, and `parse`. That wrapper is what the optional Dartpollo clients execute.

```dart
final response = await client.execute(ViewerQuery());
final login = response.data?.viewer.login;
```

<nav class="page-nav"><a href="../getting-started/">← Getting started</a><a href="../configuration/">Configuration →</a></nav>
