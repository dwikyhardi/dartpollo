---
layout: ../layouts/DocsLayout.astro
title: Integration modes
description: Choose what to generate for your GraphQL client.
---

<header class="page-lead">

# Integration modes

Choose what Dartpollo generates based on the client you use.

</header>

## Generation settings

`generate_helpers` and `generate_queries` both default to `true`.

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
final viewer = Viewer$Query.fromJson({
  'viewer': {'id': 'user-1', 'login': 'octocat'},
});
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

This mode generates operation documents and names:

<span class="filename">lib/__generated__/viewer.graphql.dart</span>

```dart
final VIEWER_QUERY_DOCUMENT_OPERATION_NAME = 'Viewer';
final VIEWER_QUERY_DOCUMENT = DocumentNode(/* generated AST */);
```

Keep optimization false in `alpha.6`; see [document limitations](../reference/generated-api/#documents-and-names).

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

Follow the [Dartpollo client guide](../dartpollo-client/) to execute these helpers.

## Client compatibility

Choose one runtime per package: `graphql` 5.2.x requires `gql_dedupe_link` 2.x, while Dartpollo `alpha.6` requires 4.x. These versions cannot be installed together. The generator works with either client.
