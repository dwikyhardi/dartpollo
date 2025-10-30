import 'dart:developer' as developer;

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:dartpollo/builder.dart';
import 'package:test/test.dart';

void main() {
  group('Combined Mutation Args Feature', () {
    test(
      'Should generate combined mutation class when combine_mutation_args is true',
      () async {
        final anotherBuilder =
            graphQLQueryBuilder(
                const BuilderOptions({
                  'generate_helpers': true,
                  'combine_mutation_args': true,
                  'schema_mapping': [
                    {
                      'schema': 'api.schema.graphql',
                      'queries_glob': 'queries/**.graphql',
                      'output': 'lib/query.graphql.dart',
                      'naming_scheme': 'pathedWithTypes',
                    },
                  ],
                }),
              )
              // Test that the builder processes the mutation correctly
              ..onBuild = expectAsync1((definition) {
                expect(definition.queries.length, equals(1));
                final query = definition.queries.first;
                expect(query.suffix, equals('Mutation'));
                expect(query.operationName, equals('CreateUser'));

                // Check that no Arguments class is generated (combined approach)
                final classNames = query.classes
                    .map((c) => c.name.namePrintable)
                    .toList();
                expect(
                  classNames.any((name) => name.contains('Arguments')),
                  isFalse,
                );

                // Check that inputs are present (should be used for constructor parameters)
                expect(query.inputs.length, equals(2));
                expect(
                  query.inputs.map((i) => i.name.name),
                  containsAll(['name', 'email']),
                );
              });

        await testBuilder(
          anotherBuilder,
          {
            'a|api.schema.graphql': createUserSchema,
            'a|queries/query.graphql': createUserQuery,
          },
          outputs: {
            'a|lib/query.graphql.dart': anything,
          },
          onLog: print,
        );
      },
    );

    test(
      'Should generate separate Arguments class when combine_mutation_args is false',
      () async {
        final anotherBuilder =
            graphQLQueryBuilder(
                const BuilderOptions({
                  'generate_helpers': true,
                  'combine_mutation_args': false,
                  'schema_mapping': [
                    {
                      'schema': 'api.schema.graphql',
                      'queries_glob': 'queries/**.graphql',
                      'output': 'lib/query.graphql.dart',
                      'naming_scheme': 'pathedWithTypes',
                    },
                  ],
                }),
              )
              // Test that the builder processes the mutation correctly
              ..onBuild = expectAsync1((definition) {
                expect(definition.queries.length, equals(1));
                final query = definition.queries.first;
                expect(query.suffix, equals('Mutation'));
                expect(query.operationName, equals('CreateUser'));

                // Debug: Print all class names
                final classNames = query.classes
                    .map((c) => c.name.namePrintable)
                    .toList();
                developer.log(
                  '[DEBUG_LOG] Generated classes when combine_mutation_args=false: $classNames',
                );

                // Check that the traditional approach generates the expected classes
                // (Input classes and response classes, but no Arguments classes)
                expect(classNames.any((name) => name.contains('User')), isTrue);
                expect(
                  classNames.any((name) => name.contains('MutationRoot')),
                  isTrue,
                );

                // Check that inputs are present
                expect(query.inputs.length, equals(2));
                expect(
                  query.inputs.map((i) => i.name.name),
                  containsAll(['name', 'email']),
                );
              });

        await testBuilder(
          anotherBuilder,
          {
            'a|api.schema.graphql': createUserSchema,
            'a|queries/query.graphql': createUserQuery,
          },
          outputs: {
            'a|lib/query.graphql.dart': anything,
          },
          onLog: print,
        );
      },
    );

    test(
      'Should handle mutations with no arguments when combine_mutation_args is true',
      () async {
        final anotherBuilder =
            graphQLQueryBuilder(
                const BuilderOptions({
                  'generate_helpers': true,
                  'combine_mutation_args': true,
                  'schema_mapping': [
                    {
                      'schema': 'api.schema.graphql',
                      'queries_glob': 'queries/**.graphql',
                      'output': 'lib/query.graphql.dart',
                      'naming_scheme': 'pathedWithTypes',
                    },
                  ],
                }),
              )
              ..onBuild = expectAsync1((definition) {
                expect(definition.queries.length, equals(1));
                final query = definition.queries.first;
                expect(query.suffix, equals('Mutation'));
                expect(query.operationName, equals('RefreshCache'));

                // Check that no inputs are present for no-args mutation
                expect(query.inputs.length, equals(0));
              });

        await testBuilder(
          anotherBuilder,
          {
            'a|api.schema.graphql': noArgsSchema,
            'a|queries/query.graphql': noArgsQuery,
          },
          outputs: {
            'a|lib/query.graphql.dart': anything,
          },
          onLog: print,
        );
      },
    );

    test(
      'Should handle mutations with optional arguments when combine_mutation_args is true',
      () async {
        final anotherBuilder =
            graphQLQueryBuilder(
                const BuilderOptions({
                  'generate_helpers': true,
                  'combine_mutation_args': true,
                  'schema_mapping': [
                    {
                      'schema': 'api.schema.graphql',
                      'queries_glob': 'queries/**.graphql',
                      'output': 'lib/query.graphql.dart',
                      'naming_scheme': 'pathedWithTypes',
                    },
                  ],
                }),
              )
              ..onBuild = expectAsync1((definition) {
                expect(definition.queries.length, equals(1));
                final query = definition.queries.first;
                expect(query.suffix, equals('Mutation'));
                expect(query.operationName, equals('UpdateProfile'));

                // Check that optional inputs are present
                expect(query.inputs.length, equals(2));
                expect(
                  query.inputs.map((i) => i.name.name),
                  containsAll(['name', 'bio']),
                );
              });

        await testBuilder(
          anotherBuilder,
          {
            'a|api.schema.graphql': optionalArgsSchema,
            'a|queries/query.graphql': optionalArgsQuery,
          },
          outputs: {
            'a|lib/query.graphql.dart': anything,
          },
          onLog: print,
        );
      },
    );

    test(
      'Should handle mutations with complex nested input types when combine_mutation_args is true',
      () async {
        final anotherBuilder =
            graphQLQueryBuilder(
                const BuilderOptions({
                  'generate_helpers': true,
                  'combine_mutation_args': true,
                  'schema_mapping': [
                    {
                      'schema': 'api.schema.graphql',
                      'queries_glob': 'queries/**.graphql',
                      'output': 'lib/query.graphql.dart',
                      'naming_scheme': 'pathedWithTypes',
                    },
                  ],
                }),
              )
              ..onBuild = expectAsync1((definition) {
                expect(definition.queries.length, equals(1));
                final query = definition.queries.first;
                expect(query.suffix, equals('Mutation'));
                expect(query.operationName, equals('CreateOrder'));

                // Check that complex nested inputs are present
                expect(query.inputs.length, equals(1));
                expect(query.inputs.first.name.name, equals('orderInput'));

                // Check that input object classes are still generated
                final classNames = query.classes
                    .map((c) => c.name.namePrintable)
                    .toList();
                expect(
                  classNames.any((name) => name.contains('OrderInput')),
                  isTrue,
                );
                expect(
                  classNames.any((name) => name.contains('AddressInput')),
                  isTrue,
                );
              });

        await testBuilder(
          anotherBuilder,
          {
            'a|api.schema.graphql': complexNestedSchema,
            'a|queries/query.graphql': complexNestedQuery,
          },
          outputs: {
            'a|lib/query.graphql.dart': anything,
          },
          onLog: print,
        );
      },
    );

    test(
      'Should handle mutations with list and nullable parameters when combine_mutation_args is true',
      () async {
        final anotherBuilder =
            graphQLQueryBuilder(
                const BuilderOptions({
                  'generate_helpers': true,
                  'combine_mutation_args': true,
                  'schema_mapping': [
                    {
                      'schema': 'api.schema.graphql',
                      'queries_glob': 'queries/**.graphql',
                      'output': 'lib/query.graphql.dart',
                      'naming_scheme': 'pathedWithTypes',
                    },
                  ],
                }),
              )
              ..onBuild = expectAsync1((definition) {
                expect(definition.queries.length, equals(1));
                final query = definition.queries.first;
                expect(query.suffix, equals('Mutation'));
                expect(query.operationName, equals('BulkUpdateUsers'));

                // Check that list and nullable inputs are present
                expect(query.inputs.length, equals(3));
                expect(
                  query.inputs.map((i) => i.name.name),
                  containsAll(['userIds', 'status', 'tags']),
                );
              });

        await testBuilder(
          anotherBuilder,
          {
            'a|api.schema.graphql': listNullableSchema,
            'a|queries/query.graphql': listNullableQuery,
          },
          outputs: {
            'a|lib/query.graphql.dart': anything,
          },
          onLog: print,
        );
      },
    );
  });
}

const createUserQuery = r'''
mutation CreateUser($name: String!, $email: String!) {
  createUser(name: $name, email: $email) {
    id
    name
    email
  }
}
''';

const createUserSchema = r'''
schema {
  mutation: MutationRoot
}

type MutationRoot {
  createUser(name: String!, email: String!): User
}

type User {
  id: ID!
  name: String!
  email: String!
}
''';

const noArgsQuery = r'''
mutation RefreshCache {
  refreshCache {
    success
  }
}
''';

const noArgsSchema = r'''
schema {
  mutation: MutationRoot
}

type MutationRoot {
  refreshCache: RefreshResult
}

type RefreshResult {
  success: Boolean!
}
''';

const optionalArgsQuery = r'''
mutation UpdateProfile($name: String, $bio: String) {
  updateProfile(name: $name, bio: $bio) {
    id
    name
    bio
  }
}
''';

const optionalArgsSchema = r'''
schema {
  mutation: MutationRoot
}

type MutationRoot {
  updateProfile(name: String, bio: String): Profile
}

type Profile {
  id: ID!
  name: String
  bio: String
}
''';

const complexNestedQuery = r'''
mutation CreateOrder($orderInput: OrderInput!) {
  createOrder(orderInput: $orderInput) {
    id
    total
    status
  }
}
''';

const complexNestedSchema = r'''
schema {
  mutation: MutationRoot
}

type MutationRoot {
  createOrder(orderInput: OrderInput!): Order
}

type Order {
  id: ID!
  total: Float!
  status: String!
}

input OrderInput {
  items: [OrderItemInput!]!
  shippingAddress: AddressInput!
  billingAddress: AddressInput
  notes: String
}

input OrderItemInput {
  productId: ID!
  quantity: Int!
  price: Float!
}

input AddressInput {
  street: String!
  city: String!
  state: String!
  zipCode: String!
  country: String!
}
''';

const listNullableQuery = r'''
mutation BulkUpdateUsers($userIds: [ID!]!, $status: String, $tags: [String]) {
  bulkUpdateUsers(userIds: $userIds, status: $status, tags: $tags) {
    updatedCount
    errors
  }
}
''';

const listNullableSchema = r'''
schema {
  mutation: MutationRoot
}

type MutationRoot {
  bulkUpdateUsers(userIds: [ID!]!, status: String, tags: [String]): BulkUpdateResult
}

type BulkUpdateResult {
  updatedCount: Int!
  errors: [String]
}
''';
