---
layout: ../layouts/DocsLayout.astro
title: Mental model
description: How a schema and GraphQL operations become typed Dart code.
---

<header class="page-lead">

# Mental model

Dartpollo generates types from the fields your operations select. Your client sends the request; the generated code parses its response.

</header>

## The build pipeline

1. **Schema:** a local SDL file describes the API's types and fields.
2. **Operations:** `.graphql` files select the fields your application needs.
3. **Dartpollo Generator:** reads both and writes response models, input types and optional operation documents.
4. **json_serializable:** writes the `.g.dart` functions used by `fromJson` and `toJson`.

Connect the schema and operation in `build.yaml`:

<span class="filename">build.yaml</span>

```yaml
schema_mapping:
  - schema: github.schema.graphql
    queries_glob: lib/graphql/viewer.graphql
```

## Prepare the schema

The generator reads SDL from disk. If you need to download it from your API, do that before building; the [GitHub tutorial](../guides/github/#fetch-the-sdl-safely) shows how.

## Use the generated code

A query named `Viewer` generates `Viewer$Query`. With document generation enabled, it also provides:

- `VIEWER_QUERY_DOCUMENT`: the GraphQL document to send through your client.
- `VIEWER_QUERY_DOCUMENT_OPERATION_NAME`: the operation name, `Viewer`.

Parse the response's data object with the generated factory:

```dart
final data = Viewer$Query.fromJson({
  'viewer': {'id': 'user-1', 'login': 'octocat'},
});
print(data.viewer.login);
```

Your client handles authentication, transport and GraphQL errors. The generated models give you typed access to the returned fields.

## Where output lands

For `lib/graphql/viewer.graphql`, the builder writes:

```text
lib/__generated__/viewer.graphql.dart
lib/__generated__/viewer.graphql.g.dart
```

Rebuild after editing the schema or operations. Choose an [integration mode](../integration-modes/) to use these files with your client.
