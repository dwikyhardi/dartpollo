---
layout: ../layouts/DocsLayout.astro
title: GraphQL features
description: Configure scalars, enums, abstract types, type discriminators, and Dart-safe names.
---

<header class="page-lead">

# GraphQL features

Use custom scalars, enums, interfaces and unions in generated Dart code.

</header>

## Built-in scalars

Use built-in mappings without additional configuration:

| GraphQL scalar | Generated Dart shape |
|---|---|
| `Boolean` | `bool` |
| `Float` | `double` |
| `ID` | `String` |
| `UUID` | `String` |
| `JSONString` | JSON-compatible value |
| `Int` | `int` |
| `GenericScalar` | JSON-compatible value |
| `String` | `String` |

Add a mapping for any other scalar used by your operations.

## Custom scalars and parsers

A custom scalar needs a Dart type and functions to convert it to and from JSON. This example wraps a string as `AccountId`.

Add the scalar declaration to your SDL and extend the quickstart’s `User` definition:

```graphql
scalar AccountId

type User {
  id: ID!
  login: String!
  accountId: AccountId!
  linkedIds: [AccountId]
}
```

Then create the operation file:

<span class="filename">lib/graphql/accounts.graphql</span>

```graphql
query Accounts {
  viewer { accountId linkedIds }
}
```

Add this under the builder's `options`. Replace `dartpollo_developer_guide` with your package name:

<span class="filename">build.yaml</span>

```yaml
scalar_mapping:
  - graphql_type: AccountId
    dart_type:
      name: AccountId
      imports:
        - package:dartpollo_developer_guide/graphql/account_id.dart
    custom_parser_import: package:dartpollo_developer_guide/graphql/account_id.dart
```

<span class="filename">lib/graphql/account_id.dart</span>

<!-- example: lib/graphql/account_id.dart -->
```dart
class AccountId {
  const AccountId(this.value);

  final String value;
}

AccountId fromGraphQLAccountIdToDartAccountId(String value) => AccountId(value);

String fromDartAccountIdToGraphQLAccountId(AccountId value) => value.value;

List<AccountId?>?
fromGraphQLListNullableAccountIdNullableToDartListNullableAccountIdNullable(
  List<Object?>? values,
) => values
    ?.map((value) => value == null ? null : AccountId(value as String))
    .toList();

List<String?>?
fromDartListNullableAccountIdNullableToGraphQLListNullableAccountIdNullable(
  List<AccountId?>? values,
) => values?.map((value) => value?.value).toList();
```

The generator derives converter names from the type, list structure and nullability. `AccountId!` uses the first pair above; `[AccountId]` uses the nullable-list pair. Supply matching functions for each shape used by your operations.

Map `lib/graphql/accounts.graphql` in `build.yaml` and rebuild. You can then parse and serialize the scalar through the generated model:

```dart
final data = Accounts$Query.fromJson({
  'viewer': {
    'accountId': 'account-1',
    'linkedIds': ['account-2', null],
  },
});
print(data.viewer.accountId.value); // account-1
final json = data.toJson(); // restores the original string values and nulls
```

The converters preserve null lists and null items. Add format validation if your API requires it. The [example project](../examples/#offline-developer-recipes) includes round-trip tests.

## Enums and unknown values

By default, GraphQL enums become Dart enums. Generated enums include an `UNKNOWN` wire value mapped to Dart `unknown`, preserving deserialization when a server adds a value the client has not generated yet.

For example, a response value of `"FUTURE_VALUE"` becomes `Visibility.unknown`. Handle that fallback when reading responses. For inputs, send a value your schema accepts, such as `Visibility.public` (`"PUBLIC"`).

To generate strings instead of enum types, set:

<span class="filename">build.yaml</span>

```yaml
options:
  convert_enum_to_string: true
```

This top-level setting applies to every mapping.

## Interfaces and unions

Select `__typename` so the parser can identify each concrete result type:

<span class="filename">lib/graphql/search_repositories.graphql</span>

```graphql
search(query: $query, type: REPOSITORY, first: 10) {
  nodes {
    __typename
    ... on Repository {
      nameWithOwner
    }
  }
}
```

Set `append_type_name: true` to add `__typename` automatically. Use a custom `type_name_field` only if your API provides a different discriminator.

### Consume concrete results

For the example project's `Search` query, select repository results with `whereType`:

```dart
final names = (data.search ?? [])
    .whereType<Search$Query$SearchResult$Repository>()
    .map((repository) => repository.name)
    .toList();
```

`data` is a `Search$Query`. `?? []` handles a null list; `whereType` filters null items and other result types. Use the concrete class name from your generated code. See the [GitHub example](../guides/github/#understand-union-dispatch) for a nested union selection.

## Dart-safe names

GraphQL names are converted to valid Dart identifiers. When a field conflicts with a Dart keyword, the generated property uses a safe identifier while `JsonKey` preserves the original wire name. Aliases also participate in generated property and path names.

Nested class names depend on `naming_scheme`: keep `pathedWithTypes` as the collision-resistant default. `simple` is shorter but can raise `DuplicatedClassesException` when different selections resolve to the same Dart class name.

Continue with [multiple schemas](../multiple-schemas/) for isolated mapping behavior, or check the [generated API reference](../reference/generated-api/) and [troubleshooting](../troubleshooting/).
