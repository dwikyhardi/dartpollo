---
layout: ../layouts/DocsLayout.astro
title: Caching
description: Understand DartpolloCachedClient policies, TTL, stores, invalidation, and limitations.
---

<header class="page-lead">

# Caching

Use `DartpolloCachedClient` when whole-operation response caching is sufficient and you can manage freshness, isolation, and mutation invalidation explicitly.

</header>

## Create a cached client

<span class="filename">lib/graphql_client.dart</span>

```dart
final client = DartpolloCachedClient(
  endpoint,
  cacheStore: InMemoryCacheStore(maxSize: 100),
  defaultCachePolicy: CachePolicy.cacheFirst,
  defaultCacheTtl: Duration(minutes: 5),
);
```

The default store is an unbounded in-memory store. The default policy is `cacheFirst`; a null default TTL means entries do not expire.

## Policy behavior

| Policy | Cache hit | Cache miss | Network data |
|---|---|---|---|
| `cacheFirst` | Return cache | Request network | Write to cache |
| `networkFirst` | Used only after a thrown network/link failure | Rethrow network failure | Write to cache |
| `cacheOnly` | Return cache | Empty stream | No request |
| `networkOnly` | Ignore cache read | Request network | **Still writes** to cache |
| `cacheAndNetwork` | Emit cache, then request network | Request network | Emit and cache network data |

> `execute(...cacheOnly...)` throws `StateError` on a cache miss because it awaits the first event of an empty stream. Use `stream` when an empty result is a valid outcome.

Use `stream`, not `execute`, for `cacheAndNetwork`; `execute` returns only the first emission.

## Per-request policy and TTL

<span class="filename">lib/viewer_request.dart</span>

```dart
final response = await client.execute(
  ViewerQuery(),
  context: const Context().withCache(
    policy: CachePolicy.networkFirst,
    ttl: Duration(minutes: 10),
  ),
);
```

Shortcuts include `withoutCache()`, `cacheOnly()`, and `cacheAndNetwork()`.

Current limitation: `withCacheTtl(null)` leaves the context unchanged, so it cannot override a non-null client default to “never expire.”

## Mutations and invalidation

The cache link does not distinguish queries from mutations. With the default `cacheFirst`, a mutation can be cached under its operation and variables. Bypass cache reads with `networkOnly` for mutations, then evict affected query entries explicitly; mutation results do not invalidate or merge cached query data automatically.

<span class="filename">lib/update_viewer.dart</span>

```dart
await client.execute(
  UpdateViewerMutation(variables: input),
  context: const Context().withoutCache(),
);

await client.evictCache(ViewerQuery());
```

## Direct cache access

<span class="filename">lib/cache_maintenance.dart</span>

```dart
final cached = await client.readCache(ViewerQuery());

await client.writeCache(
  ViewerQuery(),
  {'viewer': {'login': 'octocat'}},
  ttl: Duration(minutes: 10),
);

await client.evictCache(ViewerQuery());
await client.clearCache();
final stats = client.getCacheStats();
```

`writeCache` accepts a raw GraphQL data map. Its null TTL means that manually written entry does not expire; it does not inherit the client default.

## Stores

### In memory

`InMemoryCacheStore(maxSize: n)` uses entry-count LRU eviction. Reads refresh recency. Omit `maxSize` for an unbounded ephemeral store.

### Hive

<span class="filename">lib/graphql_cache.dart</span>

```dart
Hive.init(appDataPath);
final store = await HiveCacheStore.open('graphql_cache');
final client = DartpolloCachedClient(endpoint, cacheStore: store);

// Shutdown
client.dispose();
await store.close();
```

The client does not close its store. Hive removes expired or corrupt entries lazily and offers `compact`, `getStats`, and `isOpen`.

### Custom store

Implement synchronous `get`, `set`, `delete`, `clear`, and `getAll` on `CacheStore`. Implementations should filter and remove expired `CacheEntry` values.

## Cache isolation

The key hashes operation name, printed document, and JSON variables. It does **not** include endpoint, headers, authenticated user, or arbitrary request context. Do not share one store namespace across users or endpoints; clear or isolate stores when identity changes.
