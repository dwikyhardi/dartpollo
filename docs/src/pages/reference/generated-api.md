---
layout: ../../layouts/DocsLayout.astro
title: Generated API
description: Exact naming patterns for generated models, arguments, constants, helpers, fragments, and serializers.
---

<header class="page-lead">

# Generated API

Look up generated class names, operation constants and helper methods.

</header>

## Operation symbol patterns

Use named operations so every integration symbol is stable and identifiable.

| GraphQL artifact | Example generated symbol | Availability |
|---|---|---|
| Query response | `Viewer$Query` | Always |
| Variables | `SearchRepositoriesArguments` | Operation has variables and queries/documents are enabled |
| Document | `VIEWER_QUERY_DOCUMENT` | `generate_queries` or helpers enabled |
| Operation name | `VIEWER_QUERY_DOCUMENT_OPERATION_NAME` | `generate_queries` or helpers enabled |
| Dartpollo query helper | `ViewerQuery` | `generate_helpers: true` |
| Dartpollo variable query helper | `SearchRepositoriesQuery` | `generate_helpers: true` |

<span class="filename">lib/graphql/viewer.graphql</span>

```graphql
query Viewer {
  viewer { login }
}
```

<span class="filename">lib/main.dart</span>

```dart
final data = Viewer$Query.fromJson(json);
final document = VIEWER_QUERY_DOCUMENT;
final name = VIEWER_QUERY_DOCUMENT_OPERATION_NAME;
final query = ViewerQuery();
```

Anonymous operations receive fallback names, but named operations are strongly recommended.

## Response and nested models

Response classes contain the fields selected by the operation. Nested names depend on `naming_scheme`, aliases and the parent type path.

GraphQL non-null fields are required/non-null in Dart. Nullable fields and nullable list items remain nullable independently.

## Arguments and inputs

Variables produce a named-parameter argument object:

<span class="filename">lib/main.dart</span>

```dart
final variables = SearchRepositoriesArguments(query: 'flutter');
final json = variables.toJson();
```

GraphQL non-null inputs are required even when GraphQL declares a default. Nullable constructor parameters serialize as explicit null when omitted under default serializer settings; they do not represent an absent variable. See [variables and defaults](../../operations-and-variables/#omission-null-and-defaults). Input objects and enums reached by those variables are emitted alongside the operation. Response and argument classes provide `fromJson`, `toJson`, and equality props.

## Documents and names

`VIEWER_QUERY_DOCUMENT` is already a `DocumentNode`. Pass it directly to an AST-compatible client; do not call `gql()` around it. The matching operation-name constant is the exact generated selection name to pass when a document contains or may contain multiple operations.

Keep `optimize_document_nodes: false` in `alpha.6`. Enabling it can:

- Replace inline enum arguments such as `status: ACTIVE` with `status: null`.
- Drop selection directives such as `@include` and `@skip`.
- Generate a missing `DocumentNodeHelpers` import when helpers are disabled.

Non-optimized output preserves these literals and directives. Test parsing when directives can omit response fields.

## Dartpollo helper contract

Generated helpers extend `GraphQLQuery<Response, Variables>` and provide:

| Member | Purpose |
|---|---|
| `document` | Generated operation AST |
| `operationName` | Named operation string |
| `variables` | Typed argument object, when present |
| `getVariablesMap()` | JSON-ready variable map |
| `parse(json)` | Generated response deserialization |

Mutation and subscription helpers follow the same contract with `Mutation` and `Subscription` suffixes.

## Fragments, enums, and wire names

Fragment output follows `<FragmentName>Mixin`, for example `UserIdentityMixin`. Only transitively referenced fragment definitions enter an operation document.

Generated enums include an `UNKNOWN` wire value mapped to Dart `unknown` unless enum-to-string conversion suppresses enum generation.

When a GraphQL field is a Dart keyword, the property receives a safe Dart identifier and `JsonKey` preserves the original wire name. GraphQL aliases determine the generated property and path name.

## Serialization files and imports

The main `.graphql.dart` library references a paired `.graphql.g.dart` part produced by `json_serializable`. Generated source directly imports `equatable`, `gql`, and `json_annotation`; generator-only consumers should declare those dependencies.

Never edit generated files. Rebuild after changing SDL, operations, or options. See [generated output](../../generated-output/) for the conceptual model and [generator options](../generator-options/) for feature switches.
