---
layout: ../layouts/DocsLayout.astro
title: Getting started
description: Install Dartpollo Generator and generate typed Dart models from a GraphQL operation.
---

<header class="page-lead">

# Getting started

Generate typed Dart models from one schema and one operation. This path does **not** require the Dartpollo runtime client.

</header>

## Requirements

- Dart SDK `^3.10.0`
- A GraphQL schema in SDL format
- One or more named GraphQL operations

## Install the generator

Add the generator and `build_runner` as development dependencies. Generated models directly reference `equatable`, `gql`, and `json_annotation`, so declare those as runtime dependencies when you use the models without `package:dartpollo`.

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

> `dartpollo_generator` currently brings some of these packages transitively, but declaring packages imported by generated source keeps your dependency boundary explicit.

## Add a schema and operation

Save your schema somewhere included by the build target:

```graphql
# schema.graphql
type Query {
  viewer: User!
}

type User {
  id: ID!
  login: String!
}
```

Create a named operation:

```graphql
# lib/graphql/viewer.graphql
query Viewer {
  viewer {
    id
    login
  }
}
```

## Configure `build.yaml`

This configuration generates models and operation documents without generating a Dartpollo client helper.

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
          schema_mapping:
            - schema: schema.graphql
              queries_glob: lib/graphql/*.graphql
```

The schema must not match `queries_glob`. The query glob must resolve to at least one operation file.

## Run the builders

```bash
dart run build_runner build --delete-conflicting-outputs
```

The generator derives an output under `lib/__generated__/` from the query glob. `json_serializable` then creates the paired `.g.dart` serializers.

```text
lib/
├── graphql/
│   └── viewer.graphql
└── __generated__/
    ├── viewer.graphql.dart
    └── viewer.graphql.g.dart
```

## Use the generated model

After your GraphQL client returns a JSON data map, deserialize it with the generated response type:

```dart
import 'package:your_app/__generated__/viewer.graphql.dart';

final data = Viewer$Query.fromJson(result.data!);
print(data.viewer.login);
```

The exact way you send `ViewerQueryDocument` depends on the GraphQL client you choose. See [Integration modes](../integration-modes/) for the boundaries Dartpollo can generate.

<nav class="page-nav"><a href="../">← Overview</a><a href="../integration-modes/">Integration modes →</a></nav>
