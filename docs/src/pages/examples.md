---
layout: ../layouts/DocsLayout.astro
title: Examples
description: Choose between the runnable Pokémon and GitHub GraphQL tutorials.
---

<header class="page-lead">

# Examples

Choose a repository-backed tutorial based on whether you need a token-free first run or a real authenticated API integration.

</header>

## Pokémon: local and token-free

Use [the Pokémon tutorial](../guides/pokemon/) first when learning the generator. Its SDL, operations, fragments, and generated output are committed, so it works without network schema preparation or credentials.

<span class="filename">Terminal</span>

```bash
cd packages/dartpollo/example/pokemon
dart pub get
dart run build_runner build --delete-conflicting-outputs
dart run lib/main.dart
```

You will inspect `SimpleQuery$Query`, `SIMPLE_QUERY_QUERY_DOCUMENT`, `SimpleQueryQuery`, `BigQueryArguments(quantity: 5)`, shared fragments, and the alias-generated `charmander` property.

## GitHub: external schema and authentication

Use [the GitHub tutorial](../guides/github/) after the local flow works. It adds schema fetching, token handling, custom scalars, typed variables, union parsing, and two execution clients.

<span class="filename">Terminal</span>

```bash
GITHUB_TOKEN=your_token dart run tool/fetch_schema.dart \
  -e https://api.github.com/graphql \
  -o packages/dartpollo/example/github/github.schema.graphql \
  -a "Bearer $GITHUB_TOKEN"
```

The schema download is preparation, not part of normal generation. The tutorial never prints or commits the token.

## Compare the outcomes

| Tutorial | Schema | Authentication | Main concepts |
|---|---|---|---|
| Pokémon | Committed local SDL | None | mappings, variables, aliases, fragments, helpers |
| GitHub | Fetched local SDL | bearer token | custom scalars, unions, typed variables, two clients |

Both tutorials end with generated `.graphql.dart` and `.graphql.g.dart` files plus a typed runtime result. If either build fails, use the [troubleshooting reference](../troubleshooting/) before broadening globs or changing generated code.
