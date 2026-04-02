## 0.1.0-alpha.1

### Breaking Changes

- Package decoupled into monorepo: `dartpollo` (client), `dartpollo_generator` (code gen), `dartpollo_annotation` (shared types)
- Code generator moved to separate `dartpollo_generator` package — add it as a dev dependency
- `build.yaml` builder key changed from `dartpollo:` to `dartpollo_generator|dartpollo:`
- Shared types (`GraphQLQuery`, `GraphQLResponse`, etc.) moved to `dartpollo_annotation` (re-exported from `dartpollo` barrel — no import changes needed)

## 0.0.2

- Added general build options
- Fix some lint errors

## 0.0.1

- Initial release
- Generate Dart types from GraphQL schemas and queries
- Support for fragments, mutations, subscriptions
- Custom scalar mapping
- json_serializable integration
