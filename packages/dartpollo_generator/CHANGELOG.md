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
