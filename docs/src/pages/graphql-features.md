---
layout: ../layouts/DocsLayout.astro
title: GraphQL features
description: Configure scalars, enums, abstract types, type discriminators, and Dart-safe names.
---

<header class="page-lead">

# GraphQL features

Generate Dart-safe representations for GraphQL scalars, enums, interfaces, unions, lists, and names.

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

An unknown scalar used by an operation fails generation instead of silently degrading its type.

## Custom scalars and parsers

Map custom schema scalars to application-owned Dart types and import their conversion functions.

<span class="filename">build.yaml</span>

```yaml
options:
  scalar_mapping:
    - graphql_type: MyUuid
      dart_type:
        name: MyUuid
        imports:
          - package:your_app/graphql/my_uuid.dart
      custom_parser_import: package:your_app/graphql/parsers.dart
```

Parser names are derived from the complete generated shape. The application must supply matching functions such as `fromGraphQLMyUuidToDartMyUuid`. Lists and nullable layers lengthen the name; generator tests verify this exact example:

<span class="filename">lib/graphql/parsers.dart</span>

```dart
List<MyUuid?>? fromGraphQLListNullableMyUuidNullableToDartListNullableMyUuidNullable(
  List<Object?>? value,
) => /* application conversion */;
```

The generated `JsonKey` also references the inverse `fromDartListNullableMyUuidNullableToGraphQLListNullableMyUuidNullable`. A missing parser import or function is a Dart compile error after generation.

## Enums and unknown values

By default, GraphQL enums become Dart enums. Generated enums include an `UNKNOWN` wire value mapped to Dart `unknown`, preserving deserialization when a server adds a value the client has not generated yet.

Set `convert_enum_to_string: true` when the application explicitly prefers strings over generated enum typing:

<span class="filename">build.yaml</span>

```yaml
options:
  convert_enum_to_string: true
```

The global setting effectively applies to every mapping. String conversion suppresses enum types and their exhaustive Dart API.

## Interfaces and unions

Abstract GraphQL selections dispatch to concrete generated types using the mapping's `type_name_field`, which defaults to `__typename`.

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

If operations omit the discriminator, set `append_type_name: true` to modify generated selection sets automatically. This option adds a GraphQL field; it does not rename Dart classes. A custom `type_name_field` must identify the concrete type values your schema returns.

## Dart-safe names

GraphQL names are converted to valid Dart identifiers. When a field conflicts with a Dart keyword, the generated property uses a safe identifier while `JsonKey` preserves the original wire name. Aliases also participate in generated property and path names.

Nested class names depend on `naming_scheme`: keep `pathedWithTypes` as the collision-resistant default. `simple` is shorter but can raise `DuplicatedClassesException` when different selections resolve to the same Dart class name.

Continue with [multiple schemas](../multiple-schemas/) for isolated mapping behavior, or check the [generated API reference](../reference/generated-api/) and [troubleshooting](../troubleshooting/).
