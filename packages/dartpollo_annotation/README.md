# dartpollo_annotation

[Documentation](https://dwikyhardi.github.io/dartpollo/) · [Getting started](https://dwikyhardi.github.io/dartpollo/getting-started/)

Shared types and annotations used by the [dartpollo](https://pub.dev/packages/dartpollo) GraphQL client and [dartpollo_generator](https://pub.dev/packages/dartpollo_generator) code generator.

## Overview

This package contains the core types that both the runtime client and the build-time code generator depend on:

- `GraphQLQuery` — Base class for all generated GraphQL query types
- `GraphQLResponse` — Typed response wrapper returned by the client
- `GeneratorOptions` — Configuration options for code generation
- `SchemaMap` / `ScalarMap` / `DartType` — Schema mapping types used in `build.yaml` configuration
- `DocumentNodeHelpers` — Utilities for working with GraphQL `DocumentNode`

## Usage

You typically **don't need to depend on this package directly**. It is automatically included as a transitive dependency when you add `dartpollo` or `dartpollo_generator` to your project.

If you import annotation types directly, declare the published dependency explicitly:

```yaml
dependencies:
  dartpollo_annotation: 0.1.0-alpha.7
```

Consumer examples target `alpha.7` (Dart `^3.10.0`). For generator setup, use the [complete quickstart](https://dwikyhardi.github.io/dartpollo/getting-started/).

## Why does this package exist?

It serves as the **shared contract** between the client and the generator, preventing circular dependencies:

```
dartpollo_annotation  ← minimal shared types
       ↑         ↑
 dartpollo    dartpollo_generator
 (runtime)      (build-time)
```
