---
layout: ../layouts/DocsLayout.astro
title: Generated output
description: Understand the Dart models, arguments, documents, and helpers produced by Dartpollo Generator.
---

<header class="page-lead">

# Generated output

One operation produces a library containing only the response graph and inputs that operation uses.

</header>

## Response models

For this operation:

```graphql
query Viewer {
  viewer {
    login
  }
}
```

The generator creates nested JSON-serializable types similar to:

```dart
@JsonSerializable(explicitToJson: true)
class Viewer$Query extends JsonSerializable with EquatableMixin {
  late Viewer$Query$User viewer;

  factory Viewer$Query.fromJson(Map<String, dynamic> json) =>
      _$Viewer$QueryFromJson(json);
}

@JsonSerializable(explicitToJson: true)
class Viewer$Query$User extends JsonSerializable with EquatableMixin {
  late String login;
}
```

Class names depend on `naming_scheme`, aliases, and the path through the selection set.

## Arguments and input objects

Operations with variables generate an argument type. Input objects and enums referenced by those variables are emitted alongside it.

```graphql
query Repository($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) {
    id
  }
}
```

With helpers enabled, construct the generated query using its generated arguments. With helpers disabled, serialize the generated argument object and pass the map to your client.

## Operation constants

When `generate_queries` or `generate_helpers` is enabled, the library includes:

- a `DocumentNode` containing the operation AST;
- the operation name;
- an argument class when variables exist.

`optimize_document_nodes: true` changes how the AST is printed, not the GraphQL operation's behavior.

## Dartpollo query helper

When `generate_helpers` is enabled, a generated class extends:

```dart
GraphQLQuery<ResponseType, VariablesType>
```

It exposes:

| Member | Purpose |
|---|---|
| `document` | Generated GraphQL AST. |
| `operationName` | Name from the operation definition. |
| `variables` | Typed generated arguments, when present. |
| `getVariablesMap()` | JSON-ready variable map. |
| `parse(json)` | Converts response data into the generated response type. |

## Generated headers

Generated files deliberately include `// GENERATED CODE`, coverage exclusion, lint exclusions, and `// dart format off`. Do not edit them; change the schema, operation, or generator options and rebuild.

<nav class="page-nav"><a href="../configuration/">← Configuration</a><a href="../graphql-features/">GraphQL features →</a></nav>
