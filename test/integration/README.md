# Integration Tests for Batched AppendTypename Processing

This directory contains comprehensive integration tests that validate the batched AppendTypename processing implementation against the requirements specified in the design document.

## Test Coverage

### 1. Batched AppendTypename Integration Tests (`batched_append_typename_integration_test.dart`)

This test suite provides comprehensive coverage of the core functionality:

#### Core Functionality Tests
- **Simple Query Processing**: Validates that batched and individual processing produce identical results for basic queries
- **Complex Nested Selections**: Tests deeply nested GraphQL queries with multiple levels of selection sets
- **Fragment Processing**: Ensures fragments are processed correctly with AppendTypename transformations
- **Typename Field Deduplication**: Validates that existing typename fields are not duplicated

#### Advanced Scenarios
- **Multiple Document Processing**: Tests batching of diverse document types (queries, mutations, subscriptions)
- **Mixed Typename Scenarios**: Handles documents with partial or existing typename fields
- **Transformer Sequencing**: Validates correct order when AppendTypename is combined with other transformers
- **Edge Cases**: Tests minimal documents, empty selections, and boundary conditions

#### Performance and Caching
- **Cache Consistency**: Ensures cached results match fresh processing
- **Large Batch Processing**: Tests performance with significant document volumes
- **Memory Efficiency**: Validates memory usage patterns

### 2. Performance Comparison Tests (`batched_vs_individual_performance_test.dart`)

Dedicated performance benchmarking suite:

#### Performance Metrics
- **Processing Time Comparison**: Measures batched vs individual processing times
- **Memory Usage Analysis**: Tracks cache efficiency and memory consumption
- **Scalability Testing**: Tests performance across different complexity levels
- **Fragment Processing Efficiency**: Specific benchmarks for fragment handling

#### Test Scenarios
- **Large Document Sets**: 180+ documents of varying complexity
- **Repeated Document Caching**: Tests cache hit rates with duplicate documents
- **Complexity Scaling**: Validates performance across different nesting levels
- **Fragment Batch Processing**: Dedicated fragment performance tests

## Requirements Coverage

### Requirement 3.1: Output Consistency
✅ **Covered by**: All comparison tests in both test files
- Tests validate identical output between batched and individual processing
- Structural comparison of AST nodes ensures functional equivalence
- Edge cases and complex scenarios are thoroughly tested

### Requirement 3.2: Fragment Processing Consistency
✅ **Covered by**: Fragment-specific tests in both files
- Fragment processing tests ensure batched results match individual processing
- Complex fragment scenarios with nested selections are validated
- Fragment deduplication and typename field handling is tested

### Requirement 3.3: Nested Selection Handling
✅ **Covered by**: Complex nested query tests
- Deep nesting scenarios validate AppendTypename application at all levels
- Inline fragments and fragment spreads are tested
- Mixed selection types (fields, fragments, inline fragments) are covered

### Requirement 3.4: Deduplication Correctness
✅ **Covered by**: Deduplication-specific test cases
- Tests validate that existing typename fields are not duplicated
- Mixed scenarios with partial typename fields are tested
- Validation functions ensure exactly one typename field per selection set

## Test Architecture

### Comparison Strategy
The tests use a dual-processing approach:
1. **Individual Processing**: Simulates the old behavior by applying transformers sequentially
2. **Batched Processing**: Uses the new BatchedASTProcessor implementation
3. **Result Comparison**: Structural comparison ensures identical output

### Validation Functions
- `_compareDocuments()`: Deep structural comparison of document ASTs
- `_compareFragments()`: Fragment-specific comparison logic
- `_validateTypenameFieldsInDocument()`: Ensures typename fields are present
- `_validateNoDuplicateTypenameInDocument()`: Prevents field duplication

### Test Data Generation
Comprehensive test data covers:
- Simple queries with basic selections
- Complex nested queries with multiple levels
- Queries with fragment spreads and inline fragments
- Mutations with nested input structures
- Subscriptions with real-time data patterns
- Edge cases with minimal or empty selections

## Performance Characteristics

Based on test results:
- **Batched Processing**: Maintains competitive performance with individual processing
- **Cache Efficiency**: Demonstrates significant benefits for repeated documents
- **Memory Usage**: Efficient memory patterns with proper cache management
- **Scalability**: Performance scales well with document complexity and volume

## Usage

Run all integration tests:
```bash
dart test test/integration/batched_append_typename_integration_test.dart test/integration/batched_vs_individual_performance_test.dart
```

Run with performance output:
```bash
dart test test/integration/batched_vs_individual_performance_test.dart --reporter=expanded
```

## Validation

These tests serve as the primary validation mechanism for the batched AppendTypename implementation, ensuring:
1. **Correctness**: Output matches individual processing exactly
2. **Performance**: Batched processing maintains or improves performance
3. **Reliability**: Edge cases and complex scenarios are handled properly
4. **Regression Prevention**: Comprehensive coverage prevents future regressions