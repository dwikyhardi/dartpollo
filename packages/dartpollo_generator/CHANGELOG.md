## 0.1.0-alpha.4

- Raised minimum Dart SDK constraint to `^3.10.0`
- Bumped `build` to `^4.0.6`, `dart_style` to `^3.1.8`, `source_gen` to `^4.2.3`, and `json_annotation` to `^4.12.0`
- Pinned `gql_code_builder` to `0.13.4`
- Bumped dev dependencies: `build_test` to `^3.5.15`, `pedantic_mono` to `^1.35.0`, `test` to `^1.31.1`

## 0.1.0-alpha.3

- Emit Freezed-style headers in generated code: `// coverage:ignore-file`, `// ignore_for_file: type=lint` with the freezed lint list, so consumers don't see lints or coverage hits on generated files
- Append `// dart format off` (dart_style 2.3.7+) to generated files so `dart format` becomes a no-op on generator output (matches `freezed`)
- Dropped unused workspace dependencies from `pubspec.yaml`
- Bumped `dartpollo_annotation` constraint to `^0.1.0-alpha.3`
- Reformatted `print_helpers_test` for consistent readability; scoped `dart format` script to `packages/`
- Aligned package version with `dartpollo` and `dartpollo_annotation` (skipped `alpha.2`)

## 0.1.0-alpha.1

- Initial release as standalone package
- Code generator extracted from `dartpollo` monolith
- Generates Dart types from GraphQL schemas via Introspection Query
- Auto-generates output paths (no `output` config needed)
- Supports fragments, mutations, subscriptions, custom scalars
