---
layout: ../layouts/DocsLayout.astro
title: Mental model
description: Understand how local SDL, schema mappings, Dartpollo Generator, and json_serializable form the generation pipeline.
---

<header class="page-lead">

# Mental model

Follow a GraphQL operation from local SDL to generated types, a generated document, and a client-parsed data map.

</header>

## The build pipeline

Use this model when deciding whether a concern belongs in schema preparation, generation, serialization, or runtime execution.

1. The builder reads GraphQL SDL already present in the package. It does not fetch remote schemas during a normal build.
2. Each `schema_mapping` associates one schema glob with an operation glob and optional fragment globs.
3. Dartpollo resolves operations against that schema and emits response/input types plus optional `DocumentNode` constants and Dartpollo helpers.
4. `json_serializable` reads the generated annotations and emits the paired `.g.dart` serializers.
5. Application code executes the generated document through its selected client and parses the returned `data` map.

<span class="filename">build.yaml</span>

```yaml
schema_mapping:
  - schema: github.schema.graphql
    queries_glob: lib/graphql/viewer.graphql
```

This mapping is a build-time relationship, not a network endpoint.

## Schema preparation is separate

The GitHub example does not commit its large schema. Its preparation step writes SDL to disk before generation:

<span class="filename">Terminal</span>

```bash
dart run tool/fetch_schema.dart \
  -e https://api.github.com/graphql \
  -o packages/dartpollo/example/github/github.schema.graphql \
  -a "Bearer $GITHUB_TOKEN"
```

After that command, the builder reads `github.schema.graphql` locally. Keep tokens in environment variables and never commit or print them.

## Generated and runtime boundaries

With `generate_helpers: false` and `generate_queries: true`, output includes a response factory and document but no import of `package:dartpollo`:

<span class="filename">lib/__generated__/viewer.graphql.dart</span>

```dart
final VIEWER_QUERY_DOCUMENT_OPERATION_NAME = 'Viewer';
final VIEWER_QUERY_DOCUMENT = DocumentNode(/* generated AST */);

abstract class Viewer$Query {
  factory Viewer$Query.fromJson(Map<String, dynamic> json) =
      _Viewer$Query.fromJson;
}
```

The exact generated class body can vary with schema shape and naming options; the public naming patterns above remain the integration points.

At runtime, a client sends the document and receives a response. The client owns transport errors and protocol behavior; the generated `fromJson` owns typed parsing of the non-null `data` map.

<span class="filename">lib/main.dart</span>

```dart
final result = await client.query(/* generated document */);
final data = Viewer$Query.fromJson(result.data!);
```

## Where output lands

Output placement is automatic. For an operation at `lib/graphql/viewer.graphql`, the builder writes:

<span class="filename">Generated paths</span>

```text
lib/__generated__/viewer.graphql.dart
lib/__generated__/viewer.graphql.g.dart
```

Broad wildcard globs can make output derivation surprising because the basename follows the final glob segment. Start with exact operation paths, then broaden mappings only when the resulting locations are clear.

The next decision is the [integration mode](../integration-modes/). See [multiple schemas](../multiple-schemas/) for mapping isolation and the [generated API reference](../reference/generated-api/) for integration symbols.
