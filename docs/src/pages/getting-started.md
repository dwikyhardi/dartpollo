---
layout: ../layouts/DocsLayout.astro
title: Getting started
description: Install a published generator, create typed Dart models, and run a token-free example.
---

<header class="page-lead">

# Getting started

Generate typed Dart models and a GraphQL document, then parse a response and print `octocat`. This first program uses fixed response data, so it needs no API token or running GraphQL server.

</header>

## Create a package

Use Dart SDK `^3.10.0`.

```bash
mkdir dartpollo_quickstart
cd dartpollo_quickstart
mkdir -p lib/graphql
```

Create the following five files. This example uses `0.1.0-alpha.6`.

## Add generator dependencies

<span class="filename">pubspec.yaml</span>

```yaml
name: dartpollo_quickstart
publish_to: none

environment:
  sdk: ^3.10.0

dependencies:
  equatable: ^2.0.8
  gql: ^1.0.1
  json_annotation: ^4.12.0

dev_dependencies:
  build_runner: ^2.10.0
  dartpollo_generator: 0.1.0-alpha.6
  json_serializable: ^6.11.0
```

The first three dependencies are used by generated code. `build_runner` runs the generator and `json_serializable` writes the JSON serializers.

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

## Configure generation

<span class="filename">build.yaml</span>

```yaml
targets:
  $default:
    sources:
      - $package$
      - pubspec.yaml
      - lib/**
      - schema.graphql
    builders:
      dartpollo_generator|dartpollo:
        options:
          generate_helpers: false
          generate_queries: true
          optimize_document_nodes: false
          ignore_for_file:
            - must_be_immutable
          schema_mapping:
            - schema: schema.graphql
              queries_glob: lib/graphql/viewer.graphql
```

`generate_helpers: false` lets you use the generated code with your own client. `generate_queries: true` adds the GraphQL document and typed variables.

`ignore_for_file` handles a [known generated-model warning](../troubleshooting/#generated-code-analyzer-warnings). Keep optimization false; see [document limitations](../reference/generated-api/#documents-and-names).

## Parse a response

<span class="filename">lib/main.dart</span>

```dart
import '__generated__/viewer.graphql.dart';

void main() {
  final viewer = Viewer$Query.fromJson({
    'viewer': {'id': 'user-1', 'login': 'octocat'},
  });
  print(viewer.viewer.login);
}
```

Pass the GraphQL response's **data object** to `fromJson`, not the outer `{ "data": ... }` envelope.

## Generate and run

```bash
dart pub get
dart run build_runner build
dart analyze --fatal-infos
dart run lib/main.dart
```

Dartpollo writes the model/document library, then `json_serializable` writes its serializers:

```text
lib/
├── graphql/viewer.graphql
├── main.dart
└── __generated__/
    ├── viewer.graphql.dart
    └── viewer.graphql.g.dart
```

Expected program output:

```text
octocat
```

If the `.g.dart` file is missing, check that `json_serializable` is installed and rerun `build_runner`.

Next, send a request with [`package:graphql`](../graphql-client/) or the [Dartpollo client](../dartpollo-client/). Explore mutations, unions and scalars in the [example project](../examples/#offline-developer-recipes).
