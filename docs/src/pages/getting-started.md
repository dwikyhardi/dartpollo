---
layout: ../layouts/DocsLayout.astro
title: Getting started
description: Configure Dartpollo Generator and produce typed Dart models from one local GraphQL operation.
---

<header class="page-lead">

# Getting started

Generate and verify typed Dart models and a `DocumentNode` without installing the Dartpollo runtime client.

</header>

## Prerequisites

Use this path when you have a local GraphQL SDL schema and want generated types for an existing client.

- Dart SDK `^3.10.0`
- One local schema in SDL format
- One named query, mutation, or subscription

Normal builds do not fetch a remote schema. If your API exposes only introspection, download the SDL before this workflow.

## Add generator dependencies

`dartpollo_generator` and the two builders are development dependencies. Generated source imports `equatable`, `gql`, and `json_annotation`, so declare those packages directly. `dartpollo_annotation` remains transitive.

<span class="filename">pubspec.yaml</span>

```yaml
dependencies:
  equatable: ^2.0.8
  gql: ^1.0.1
  json_annotation: ^4.12.0

dev_dependencies:
  build_runner: ^2.10.0
  dartpollo_generator: ^0.1.0-alpha.7
  json_serializable: ^6.11.0
```

## Create the schema and operation

<span class="filename">schema.graphql</span>

```graphql
type Query {
  viewer: User!
}

type User {
  id: ID!
  login: String!
}
```

<span class="filename">lib/graphql/viewer.graphql</span>

```graphql
query Viewer {
  viewer {
    id
    login
  }
}
```

Named operations produce predictable classes and constants. Anonymous operations have a fallback name, but are harder to identify in generated APIs and logs.

## Configure the builder

Client-independent generation requires `generate_helpers: false`. Keep `generate_queries: true` to emit the AST, operation-name constant, and argument class when variables exist.

<span class="filename">build.yaml</span>

```yaml
targets:
  $default:
    sources:
      - $package$
      - lib/**
      - schema.graphql
    builders:
      dartpollo_generator|dartpollo:
        options:
          generate_helpers: false
          generate_queries: true
          optimize_document_nodes: false
          schema_mapping:
            - schema: schema.graphql
              queries_glob: lib/graphql/viewer.graphql
```

Prefer one exact operation path per mapping while learning. There is no supported `output` option; output placement is derived from `queries_glob`.

## Run both builders

<span class="filename">Terminal</span>

```bash
dart pub get
dart run build_runner build
```

Dartpollo Generator writes the main library, then `json_serializable` writes its part file:

<span class="filename">Expected files</span>

```text
lib/
├── graphql/
│   └── viewer.graphql
└── __generated__/
    ├── viewer.graphql.dart
    └── viewer.graphql.g.dart
```

If the `.g.dart` file is absent, run the complete builder chain rather than the Dartpollo builder in isolation.

## Verify the generated API

The main output should contain:

- `Viewer$Query`, with `fromJson`, `toJson`, and equality props;
- `VIEWER_QUERY_DOCUMENT`, already typed as a `DocumentNode`;
- `VIEWER_QUERY_DOCUMENT_OPERATION_NAME`, whose value is `Viewer`.

<span class="filename">lib/main.dart</span>

```dart
import 'package:your_app/__generated__/viewer.graphql.dart';

final viewer = Viewer$Query.fromJson(responseData);
print(viewer.viewer.login);
```

Successful generation means both files compile and your editor resolves typed `viewer.login`. Continue with the [mental model](../mental-model/) or connect the output to [`package:graphql`](../graphql-client/). For every option and caveat, use the [generator option reference](../reference/generator-options/).
