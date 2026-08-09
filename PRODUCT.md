# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

Astro, selected by the user, deployed as a static site on GitHub Pages.

## Users

Dart and Flutter developers evaluating or adopting Dartpollo for typed GraphQL access.

## Product Purpose

Dartpollo combines GraphQL code generation with a Dart client so developers can generate typed query models, execute them, and opt into configurable caching.

## Positioning

One monorepo provides the build-time generator, the runtime client, and their shared typed contract, with cache policies and streaming built into the client workflow.

## Operating Context

Developers add packages through pub, configure `build.yaml`, keep GraphQL schemas and operations in their application, run `build_runner`, and consume generated Dart types from Dart or Flutter code.

## Capabilities and Constraints

- Dart SDK 3.10 or later for published packages.
- Typed queries, mutations, fragments, inputs, enums, and responses.
- In-memory and Hive-backed caching with per-request policies and TTL.
- Dio-based HTTP transport, custom GQL link chains, streaming, cancellation, and typed transport errors.
- The packages are currently prerelease (`0.1.0-alpha.6`); documentation must not imply API stability.

## Evidence on Hand

Repository README files, package source, tests, example applications, changelogs, and published package metadata. No testimonials, benchmarks, customer logos, or production-adoption claims are available and none should be invented.

## Product Principles

- Lead with the shortest path from schema to typed response.
- Keep generated types and runtime execution understandable as one workflow.
- Make caching optional and explicit.
- Prefer working examples over marketing claims.
