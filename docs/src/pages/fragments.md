---
layout: ../layouts/DocsLayout.astro
title: Fragments
description: Reuse local, mapping-level, and global fragments while generating typed mixins and complete documents.
---

<header class="page-lead">

# Fragments

Share GraphQL selections while keeping generated models and operation documents complete and traceable.

</header>

## Keep a fragment beside an operation

Use an in-file fragment when one operation owns the selection.

<span class="filename">lib/graphql/viewer.graphql</span>

```graphql
query Viewer {
  viewer {
    ...UserIdentity
  }
}

fragment UserIdentity on User {
  id
  login
}
```

The generated response model includes the fragment fields and fragment output follows the `<FragmentName>Mixin` pattern, such as `UserIdentityMixin`.

## Share fragments through globs

Global fragments are available to every mapping. Mapping-level fragments are available only to their schema/operation pair.

<span class="filename">build.yaml</span>

```yaml
options:
  fragments_glob: lib/graphql/common/*.fragment.graphql
  schema_mapping:
    - schema: schema.graphql
      queries_glob: lib/graphql/account/viewer.graphql
      fragments_glob: lib/graphql/account/fragments/*.graphql
```

Use global fragments only when their schema types genuinely apply across all mappings; otherwise keep them mapping-specific.

## Documents include transitive dependencies

If an operation references `UserIdentity`, and that fragment references `AvatarFields`, both definitions enter the operation `DocumentNode`. Unrelated configured fragments do not.

<span class="filename">lib/graphql/common/user.fragment.graphql</span>

```graphql
fragment UserIdentity on User {
  id
  login
  ...AvatarFields
}

fragment AvatarFields on User {
  avatarUrl
}
```

The observable generated document is executable on its own because every transitively referenced definition is included.

## Resolve missing fragments

A spread must resolve from one of three places:

1. the operation file;
2. the mapping's `fragments_glob`;
3. the top-level `fragments_glob`.

The fragment file must also be included by the build target's `sources`. Otherwise generation raises `MissingFragmentException` with a message beginning `Can't find the "FragmentName" in "ClassName"`.

Fragment-only files belong in `fragments_glob`, not `queries_glob`; a matched query file with no operation raises `MissingOperationException`.

Continue with [GraphQL features](../graphql-features/) for abstract types and scalars, or consult [troubleshooting](../troubleshooting/) for exact failure recovery.
