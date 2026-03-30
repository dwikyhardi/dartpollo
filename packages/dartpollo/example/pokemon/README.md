# Pokémon Example

A dartpollo example using the [Pokémon GraphQL API](https://graphql-pokemon2.vercel.app).

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
- **Optimized document nodes** — `optimize_document_nodes: true`
