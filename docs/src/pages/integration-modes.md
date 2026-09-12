---
layout: ../layouts/DocsLayout.astro
title: Integration modes
description: Choose the exact generated boundary for models, documents, and optional Dartpollo helpers.
---

<header class="page-lead">

# Integration modes

Choose the smallest generated API that supplies the types and operation artifacts your GraphQL client needs.

</header>

## Option matrix

Use this choice before writing `build.yaml`; both switches default to `true`.

<table class="option-matrix">
  <thead><tr><th>Helpers</th><th>Queries</th><th>Generated result</th><th>Use this when</th></tr></thead>
  <tbody>
    <tr><td>false</td><td>false</td><td>Response, input, enum, and fragment types</td><td>Another tool owns the request document</td></tr>
    <tr><td>false</td><td>true</td><td>Types, arguments, operation name, and <code>DocumentNode</code></td><td>Using <code>package:graphql</code> or another AST-compatible client</td></tr>
    <tr><td>true</td><td>false</td><td>Documents and Dartpollo wrappers are still emitted</td><td>Avoid this ambiguous combination</td></tr>
    <tr><td>true</td><td>true</td><td>All generated artifacts plus <code>GraphQLQuery</code> wrappers</td><td>Using the optional Dartpollo clients</td></tr>
  </tbody>
</table>

Helpers require operation documents, so `generate_helpers: true` still causes constants to be emitted when `generate_queries: false`.

## Models only

<span class="filename">build.yaml</span>

```yaml
options:
  generate_helpers: false
  generate_queries: false
```

This removes the Dartpollo import and query wrapper. Parse a data map directly:

<span class="filename">lib/main.dart</span>

```dart
final viewer = Viewer$Query.fromJson(responseData);
```

No operation constant or argument class is available in this mode, so application code must supply its own document and variable map.

## Client-independent documents

<span class="filename">build.yaml</span>

```yaml
options:
  generate_helpers: false
  generate_queries: true
  optimize_document_nodes: false
```

The output includes exact integration points:

<span class="filename">lib/__generated__/viewer.graphql.dart</span>

```dart
final VIEWER_QUERY_DOCUMENT_OPERATION_NAME = 'Viewer';
final VIEWER_QUERY_DOCUMENT = DocumentNode(/* generated AST */);
```

`generate_helpers: false` removes the Dartpollo dependency. In `alpha.7`, also leave `optimize_document_nodes` false: optimized output references `DocumentNodeHelpers`, but generator-only output does not emit the import that supplies it.

Follow the complete [`package:graphql` guide](../graphql-client/) for `document`, `operationName`, `parserFn`, and typed variables.

## Dartpollo helpers

<span class="filename">build.yaml</span>

```yaml
options:
  generate_helpers: true
  generate_queries: true
```

A wrapper such as `ViewerQuery` exposes `document`, `operationName`, `getVariablesMap`, and `parse` to `DartpolloClient`:

<span class="filename">lib/main.dart</span>

```dart
final response = await client.execute(ViewerQuery());
print(response.data?.viewer.login);
```

The runtime remains optional. Read [Dartpollo client](../dartpollo-client/) only when its execution and link model fits your application, and use the [generated API reference](../reference/generated-api/) to compare symbols across modes.
