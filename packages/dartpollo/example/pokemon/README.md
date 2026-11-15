# Pokémon Example

[Documentation](https://dwikyhardi.github.io/dartpollo/) · [Getting started](https://dwikyhardi.github.io/dartpollo/getting-started/)

A dartpollo example using the [Pokémon GraphQL API](https://graphql-pokemon2.vercel.app).

Requires Dart `^3.10.0` and a repository checkout. The annotation override keeps local packages on the same unreleased revision. Execution calls a public endpoint; use the [offline fixture](../../../../docs/examples/developer-guide/) for deterministic consumer tests.

## Setup

1. **Install dependencies:**

```bash
dart pub get
```

2. **Generate GraphQL types:**

```bash
dart run build_runner build --delete-conflicting-outputs
```

3. **Run the example:**

```bash
dart run lib/main.dart
```

This queries the Pokémon API with a simple query and a big query (with variables), then prints the results.

## Configuration

See [`build.yaml`](build.yaml) for the generator configuration. This example demonstrates:

- **Multiple schema mappings** — separate entries for `simple_query`, `big_query`, `fragment_query`, and `fragments_glob`
- **Fragments** — shared fragments via `fragments_glob`
- **Ordinary document printing** — `optimize_document_nodes: false` preserves the tested enum and directive behavior
