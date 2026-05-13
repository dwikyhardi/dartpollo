## 0.1.0-alpha.3

- Dropped unused workspace dependencies from `pubspec.yaml`
- Bumped `dartpollo_annotation` constraint to `^0.1.0-alpha.3`
- Updated example projects (GitHub, Pokémon) to consume the latest generator output (Freezed-style headers, `// dart format off`)

## 0.1.0-alpha.2

- Migrated HTTP layer from `gql_http_link` / `http` to `gql_dio_link` / `dio` for both `DartpolloClient` and `DartpolloCachedClient`
- Added support for custom `Dio` instance via `client` parameter (replaces `httpClient`)
- Added `defaultHeaders` parameter to both clients for convenient header configuration
- Added `useGETForQueries` parameter to send queries as GET requests (useful for CDN caching)
- Added `serializableErrors` parameter for Flutter isolate compatibility
- Added `withCancelToken(CancelToken)` context extension for request cancellation
- Re-exported DioLink exception types (`DioLinkServerException`, `DioLinkTimeoutException`, `DioLinkCanceledException`, `DioLinkParserException`, `DioLinkUnkownException`) for typed error handling
- Re-exported `Dio` and `CancelToken` from `dartpollo.dart` barrel file
- Fixed `dispose()` to use `DioLink.close()` instead of `DioLink.client.close()` for proper cleanup
- Updated `DartpolloCachedClient.fromLink` to accept `DioLink` instead of `HttpLink`
- Updated example projects (GitHub, Pokémon) to use Dio-based client
- Improved DartDoc documentation across all public APIs
- Updated README with comprehensive usage examples and API reference

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
