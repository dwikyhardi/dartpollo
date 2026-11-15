# Dartpollo

[Documentation](https://dwikyhardi.github.io/dartpollo/) · [Getting started](https://dwikyhardi.github.io/dartpollo/getting-started/)

Generate typed Dart models and operation documents from local GraphQL SDL and operations. Use the generated API with your preferred compatible client, or add the optional Dartpollo runtime and whole-operation cache.

## Packages

| Package | Purpose |
|---|---|
| [dartpollo_generator](packages/dartpollo_generator/) | build_runner generator for response/input types, enums, fragments and documents |
| [dartpollo_annotation](packages/dartpollo_annotation/) | Shared configuration and query/response contracts |
| [dartpollo](packages/dartpollo/) | Optional Dio/gql_link runtime and whole-operation cache |

## Start with generated types

The [complete quickstart](https://dwikyhardi.github.io/dartpollo/getting-started/) creates five files, generates the serializers and prints `octocat` without a token or GraphQL server.

Consumer examples are verified against published `0.1.0-alpha.6` (Dart `^3.10.0`). The `0.1.0-alpha.7` release adds documentation links and updated READMEs without changing package APIs.

```yaml
dependencies:
  equatable: ^2.0.8
  gql: ^1.0.1
  json_annotation: ^4.12.0

dev_dependencies:
  build_runner: ^2.10.0
  dartpollo_generator: 0.1.0-alpha.6
  json_serializable: ^6.11.0
```

Set `generate_helpers: false`, `generate_queries: true`, and `optimize_document_nodes: false` in the complete quickstart configuration. Map exact operation paths for predictable output, then run:

```bash
dart pub get
dart run build_runner build
dart run lib/main.dart
```

Choose [package:graphql](https://dwikyhardi.github.io/dartpollo/graphql-client/) or the [Dartpollo runtime](https://dwikyhardi.github.io/dartpollo/dartpollo-client/) as your integration. Their documented runtime versions have incompatible link dependencies, so do not install both in one package. Dartpollo uses `DartpolloClient(endpoint)` or `DartpolloClient.fromLink(link)`.

## Examples and maintenance

- [Offline developer recipes](docs/examples/developer-guide/): nested inputs, enums, unions, custom scalars and fake-link consumer tests, using published dependencies.
- [Pokémon](packages/dartpollo/example/pokemon/): local SDL and token-free public endpoint; uses checkout packages.
- [GitHub](packages/dartpollo/example/github/): schema preparation, authentication and concrete union results; uses checkout packages.
- [Configuration and upgrades](https://dwikyhardi.github.io/dartpollo/configuration/): schema refresh, regeneration, release boundaries and unreleased checkout setup.

## Development

The root workspace and CI require Dart `^3.12.1`. The consumer packages declare `^3.10.0`; pub selects dependencies compatible with the installed SDK.

```bash
dart pub get
dart run melos bootstrap
dart run melos exec --concurrency=1 -- dart test
dart run melos exec --concurrency=3 -- dart analyze --fatal-infos
dart format packages/
```

Run the [documentation checks](docs/examples/developer-guide/README.md#documentation-checks) before changing examples. See [LICENSE](LICENSE) for licensing.
