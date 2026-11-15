# GitHub Example

[Documentation](https://dwikyhardi.github.io/dartpollo/) · [Getting started](https://dwikyhardi.github.io/dartpollo/getting-started/)

A dartpollo example using the [GitHub GraphQL API](https://docs.github.com/en/graphql).

## Prerequisites

- Dart SDK `^3.10.0` for this example; `^3.12.1` for the root workspace
- A [GitHub Personal Access Token](https://github.com/settings/tokens) with access to the repositories you query

The example uses local runtime/generator paths and an annotation override for the unreleased checkout. It is separate from the [published consumer fixture](../../../../docs/examples/developer-guide/).

## Setup

1. **Install dependencies:**

```bash
dart pub get
```

2. **Fetch the GitHub GraphQL schema:**

The schema is not committed. Install root workspace dependencies with `dart pub get` using Dart `^3.12.1` before using the repository fetch tool. Export `GITHUB_TOKEN`, then run this command from the example directory:

```bash
dart run ../../../../tool/fetch_schema.dart \
  -e https://api.github.com/graphql \
  -o github.schema.graphql \
  -a "Bearer $GITHUB_TOKEN"
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

For full configuration options, see the [dartpollo_generator README](../../../dartpollo_generator/README.md).
