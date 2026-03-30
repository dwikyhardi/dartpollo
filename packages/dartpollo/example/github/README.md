# GitHub Example

A dartpollo example using the [GitHub GraphQL API](https://docs.github.com/en/graphql).

## Prerequisites

- Dart SDK `>=3.4.0 <4.0.0`
- A [GitHub Personal Access Token](https://github.com/settings/tokens) with `repo` scope

## Setup

1. **Install dependencies:**

```bash
dart pub get
```

2. **Fetch the GitHub GraphQL schema:**

The schema is not committed to the repository due to its size. Use the included fetch tool with your GitHub token:

```bash
dart run ../../tool/fetch_schema.dart \
  -e https://api.github.com/graphql \
  -o github.schema.graphql \
  -a "Bearer YOUR_GITHUB_TOKEN"
```

Alternatively, download it from the [GitHub GraphQL API public schema](https://docs.github.com/en/graphql/overview/public-schema) and save it as `github.schema.graphql` in this directory.

3. **Generate GraphQL types:**

```bash
dart run build_runner build --delete-conflicting-outputs
```

4. **Set your GitHub token and run the example:**

```bash
export GITHUB_TOKEN=your_token_here
dart run lib/main.dart
```

This searches GitHub repositories for "flutter" and prints the results.

## Configuration

See [`build.yaml`](build.yaml) for the generator configuration, including custom scalar mappings for GitHub-specific types (`GitObjectID`, `URI`, `DateTime`, etc.).

For full configuration options, see the [dartpollo_generator README](../../packages/dartpollo_generator/README.md).
