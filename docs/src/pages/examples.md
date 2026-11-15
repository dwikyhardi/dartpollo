---
layout: ../layouts/DocsLayout.astro
title: Examples
description: Run offline developer recipes, then choose a live Pokémon or GitHub integration.
---

<header class="page-lead">

# Examples

Run examples for generated models, client integration and testing.

</header>

## Offline developer recipes

The [example project](https://github.com/dwikyhardi/dartpollo/tree/main/docs/examples/developer-guide) covers nested mutation inputs, enums, unions, custom scalars and shared fragments.

From the repository root:

```bash
cd docs/examples/developer-guide
dart pub get
dart run build_runner build
dart analyze --fatal-infos
dart run lib/main.dart
dart test
```

The program prints `octocat`. Tests use fixed responses and fake links, so they need no server or credentials.

## Test response parsing

Parse sample response data and assert the fields your application uses:

<span class="filename">test/viewer_test.dart</span>

<!-- example: test/viewer_test.dart -->
```dart
import 'package:dartpollo_developer_guide/__generated__/viewer.graphql.dart';
import 'package:test/test.dart';

void main() {
  test('parses the data object, not the GraphQL response envelope', () {
    final response = {
      'data': {
        'viewer': {'id': 'user-1', 'login': 'octocat'},
      },
    };
    final viewer = Viewer$Query.fromJson(response['data']!);
    expect(viewer.viewer.login, 'octocat');
    expect(viewer.viewer.id, 'user-1');
  });
}
```

Add `test` as a dev dependency when copying this into your own package, and adjust the application import. Run it with `dart test`.

## Test requests without a server

Use `Link.function` to return a fixed response. This excerpt tests [loadViewer](../graphql-client/#execute-a-typed-query) inside an async test:

```dart
final link = Link.function((request, [forward]) {
  expect(request.operation.operationName, 'Viewer');
  return Stream.value(Response(
    data: {'viewer': {'id': 'user-1', 'login': 'octocat'}},
    response: const {},
  ));
});
addTearDown(link.dispose);
final client = GraphQLClient(link: link, cache: GraphQLCache());
expect((await loadViewer(client)).viewer.login, 'octocat');
```

See `test/recipes_test.dart` in the example project for complete tests covering errors, mutation variables, scalars and unions.

## Pokémon: public endpoint, local SDL

The [Pokémon tutorial](../guides/pokemon/) includes its schema and needs no token. Running it sends requests to a public endpoint.

```bash
cd packages/dartpollo/example/pokemon
dart pub get
dart run build_runner build
dart run lib/main.dart
```

## GitHub: external schema and authentication

The [GitHub tutorial](../guides/github/) adds schema preparation, a token, custom scalar mappings and concrete union consumption. Export `GITHUB_TOKEN` in your environment. With the workspace SDK (`^3.12.1`), run `dart pub get` at the repository root before the schema-fetch command:

```bash
dart run tool/fetch_schema.dart \
  -e https://api.github.com/graphql \
  -o packages/dartpollo/example/github/github.schema.graphql \
  -a "Bearer $GITHUB_TOKEN"
```

For a single GitHub query using your own client, follow the [package:graphql guide](../graphql-client/).

After adding operations, follow [project organization](../multiple-schemas/#organize-several-operations) and [schema maintenance](../configuration/#refresh-the-schema-and-regenerate). For errors, use [troubleshooting](../troubleshooting/).
