---
layout: ../../layouts/DocsLayout.astro
title: GitHub tutorial
description: Fetch GitHub SDL, configure custom scalars, generate typed operations, and execute them through two client paths.
---

<header class="page-lead">

# GitHub tutorial

Generate typed GitHub queries and print repository names.

</header>

## Prerequisites

This tutorial runs the example in `packages/dartpollo/example/github` using the local Dartpollo packages.

- Dart SDK `^3.12.1` for the repository tools
- A GitHub token available as `GITHUB_TOKEN`
- Network access to GitHub's GraphQL endpoint

Download the schema before generating; it is not included in the repository.

## Fetch the SDL safely

Run `dart pub get` from the repository root, then download the schema using your token:

<span class="filename">Terminal</span>

```bash
export GITHUB_TOKEN=your_token
dart run tool/fetch_schema.dart \
  -e https://api.github.com/graphql \
  -o packages/dartpollo/example/github/github.schema.graphql \
  -a "Bearer $GITHUB_TOKEN"
```

This writes `packages/dartpollo/example/github/github.schema.graphql`. Keep your token out of committed files.

## Review scalar mappings

<span class="filename">packages/dartpollo/example/github/build.yaml</span>

```yaml
options:
  scalar_mapping:
    - graphql_type: GitObjectID
      dart_type: String
    - graphql_type: URI
      dart_type: String
    - graphql_type: GitRefname
      dart_type: String
    - graphql_type: DateTime
      dart_type: DateTime
  schema_mapping:
    - schema: github.schema.graphql
      queries_glob: lib/graphql/search_repositories.graphql
    - schema: github.schema.graphql
      queries_glob: lib/graphql/viewer.graphql
```

Every scalar reached by an operation must be built in or mapped. The two exact mappings produce separate generated libraries.

## Generate both operations

<span class="filename">Terminal</span>

```bash
cd packages/dartpollo/example/github
dart pub get
dart run build_runner build --delete-conflicting-outputs
```

Expected output:

<span class="filename">Generated files</span>

```text
lib/__generated__/viewer.graphql.dart
lib/__generated__/viewer.graphql.g.dart
lib/__generated__/search_repositories.graphql.dart
lib/__generated__/search_repositories.graphql.g.dart
```

`Viewer$Query` models the current login. `SearchRepositoriesArguments(query: 'flutter')` serializes the required variable.

## Understand union dispatch

<span class="filename">lib/graphql/search_repositories.graphql</span>

```graphql
query search_repositories($query: String!) {
  search(first: 10, type: REPOSITORY, query: $query) {
    nodes {
      __typename
      ... on Repository {
        name
      }
    }
  }
}
```

GitHub returns a union for search nodes. The selected `__typename` lets generated parsing dispatch repository results to the concrete generated Repository type.

## Execute with package:graphql

For this alternative, follow the [`package:graphql` setup](../../graphql-client/) in a separate package. Generate the search operation with helpers disabled and import its generated library. Inside an async function:

<span class="filename">lib/graphql_client_example.dart</span>

```dart
final variables = SearchRepositoriesArguments(query: 'flutter');
final result = await client.query<SearchRepositories$Query>(
  QueryOptions<SearchRepositories$Query>(
    document: SEARCH_REPOSITORIES_QUERY_DOCUMENT,
    operationName:
        SEARCH_REPOSITORIES_QUERY_DOCUMENT_OPERATION_NAME,
    variables: variables.toJson(),
    parserFn: SearchRepositories$Query.fromJson,
  ),
);

if (result.hasException) throw result.exception!;
final data = result.parsedData;
if (data == null) throw StateError('GitHub returned no search data');
final names = (data.search.nodes ?? [])
    .whereType<
      SearchRepositories$Query$SearchResultItemConnection$SearchResultItem$Repository
    >()
    .map((repository) => repository.name);
for (final name in names) {
  print(name);
}
```

## Execute with optional Dartpollo

The committed example keeps helpers enabled and adds the token through a Dio interceptor:

<span class="filename">lib/main.dart</span>

```dart
final query = SearchRepositoriesQuery(
  variables: SearchRepositoriesArguments(query: 'flutter'),
);
final response = await client.execute(query);
```

Run it with the environment variable still set:

<span class="filename">Terminal</span>

```bash
GITHUB_TOKEN="$GITHUB_TOKEN" dart run lib/main.dart
```

The program prints repository names. Close clients and custom transports when you finish using them.

> **Troubleshooting:** A schema-missing error means the preparation output is absent or outside target sources. An unknown-scalar error means GitHub added a used scalar that is not mapped. Use the [troubleshooting reference](../../troubleshooting/) for exact generator messages.
