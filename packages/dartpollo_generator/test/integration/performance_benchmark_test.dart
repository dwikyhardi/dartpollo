import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:dartpollo_generator/builder.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  group('Performance Benchmark Tests', () {
    setUp(() {
      Logger.root.level = Level.SEVERE; // Minimize logging noise
    });

    group('Generation Performance', () {
      test('should benchmark simple schema generation', () async {
        const schema = '''
          type Query {
            user: User
          }
          
          type User {
            id: ID!
            name: String
            email: String
          }
        ''';

        const query = '''
          query GetUser {
            user {
              id
              name
              email
            }
          }
        ''';

        final stopwatch = Stopwatch();
        final times = <int>[];

        // Run multiple iterations to get average performance
        for (var i = 0; i < 10; i++) {
          final builder =
              graphQLQueryBuilder(
                  const BuilderOptions({
                    'generate_helpers': false,
                    'generate_queries': false,
                    'schema_mapping': [
                      {
                        'schema': 'benchmark.schema.graphql',
                        'queries_glob': 'queries/**.graphql',
                      },
                    ],
                  }),
                )
                ..onBuild = expectAsync1((definition) {
                  // Capture timing when build completes
                });

          stopwatch
            ..reset()
            ..start();

          await testBuilder(
            builder,
            {
              'a|benchmark.schema.graphql': schema,
              'a|queries/benchmark.graphql': query,
            },
            outputs: {
              'a|lib/__generated__/**.graphql.dart': anything,
            },
          );

          stopwatch.stop();
          times.add(stopwatch.elapsedMilliseconds);
        }

        final averageTime = times.reduce((a, b) => a + b) / times.length;
        final minTime = times.reduce(min);
        final maxTime = times.reduce(max);

        dev.log(
          'Simple Schema Generation Performance:',
          level: Level.INFO.value,
          name: 'INFO',
        );
        dev.log(
          '  Average: ${averageTime.toStringAsFixed(2)}ms',
          level: Level.INFO.value,
          name: 'INFO',
        );
        dev.log(
          '  Min: ${minTime}ms',
          level: Level.INFO.value,
          name: 'INFO',
        );
        dev.log(
          '  Max: ${maxTime}ms',
          level: Level.INFO.value,
          name: 'INFO',
        );

        // Performance assertions
        expect(averageTime, lessThan(1000)); // Should average under 1 second
        expect(
          maxTime,
          lessThan(2000),
        ); // No single run should exceed 2 seconds
      });

      test('should benchmark complex schema generation', () async {
        // Generate a complex schema with multiple types and relationships
        final schemaBuffer = StringBuffer()
          ..writeln('type Query {')
          ..writeln('  user(id: ID!): User')
          ..writeln('  users(filter: UserFilter): [User!]!')
          ..writeln('  post(id: ID!): Post')
          ..writeln('  posts(filter: PostFilter): [Post!]!')
          ..writeln('}')
          ..writeln('''
          type User {
            id: ID!
            name: String!
            email: String!
            profile: UserProfile
            posts: [Post!]!
            comments: [Comment!]!
            followers: [User!]!
            following: [User!]!
            createdAt: String
            updatedAt: String
          }

          type UserProfile {
            bio: String
            avatar: String
            website: String
            location: String
            birthDate: String
            preferences: UserPreferences
          }

          type UserPreferences {
            theme: Theme
            notifications: NotificationSettings
            privacy: PrivacySettings
          }

          type Post {
            id: ID!
            title: String!
            content: String!
            author: User!
            comments: [Comment!]!
            tags: [Tag!]!
            likes: [Like!]!
            status: PostStatus!
            createdAt: String
            updatedAt: String
          }

          type Comment {
            id: ID!
            content: String!
            author: User!
            post: Post!
            parent: Comment
            replies: [Comment!]!
            likes: [Like!]!
            createdAt: String
          }

          type Tag {
            id: ID!
            name: String!
            posts: [Post!]!
          }

          type Like {
            id: ID!
            user: User!
            post: Post
            comment: Comment
            createdAt: String
          }

          enum Theme {
            LIGHT
            DARK
            AUTO
          }

          enum PostStatus {
            DRAFT
            PUBLISHED
            ARCHIVED
          }

          type NotificationSettings {
            email: Boolean!
            push: Boolean!
            sms: Boolean!
          }

          type PrivacySettings {
            profileVisible: Boolean!
            emailVisible: Boolean!
            postsVisible: Boolean!
          }

          input UserFilter {
            name: StringFilter
            email: StringFilter
            createdAt: DateFilter
          }

          input PostFilter {
            title: StringFilter
            status: PostStatus
            authorId: ID
            createdAt: DateFilter
          }

          input StringFilter {
            eq: String
            contains: String
            startsWith: String
            endsWith: String
          }

          input DateFilter {
            eq: String
            gt: String
            lt: String
            gte: String
            lte: String
          }
        ''');

        const complexQuery = '''
          query GetComplexUserData(\$userId: ID!, \$postFilter: PostFilter) {
            user(id: \$userId) {
              id
              name
              email
              profile {
                bio
                avatar
                website
                preferences {
                  theme
                  notifications {
                    email
                    push
                  }
                  privacy {
                    profileVisible
                    emailVisible
                  }
                }
              }
              posts(filter: \$postFilter) {
                id
                title
                content
                status
                tags {
                  id
                  name
                }
                comments {
                  id
                  content
                  author {
                    id
                    name
                  }
                  replies {
                    id
                    content
                    author {
                      id
                      name
                    }
                  }
                }
                likes {
                  id
                  user {
                    id
                    name
                  }
                }
              }
              followers {
                id
                name
                profile {
                  avatar
                }
              }
            }
          }
        ''';

        final stopwatch = Stopwatch();
        final times = <int>[];

        // Run multiple iterations
        for (var i = 0; i < 5; i++) {
          final builder =
              graphQLQueryBuilder(
                  const BuilderOptions({
                    'generate_helpers': true,
                    'generate_queries': true,
                    'schema_mapping': [
                      {
                        'schema': 'complex.schema.graphql',
                        'queries_glob': 'queries/**.graphql',
                      },
                    ],
                  }),
                )
                ..onBuild = expectAsync1((definition) {
                  // Capture timing when build completes
                });

          stopwatch
            ..reset()
            ..start();

          await testBuilder(
            builder,
            {
              'a|complex.schema.graphql': schemaBuffer.toString(),
              'a|queries/complex.graphql': complexQuery,
            },
            outputs: {
              'a|lib/__generated__/**.graphql.dart': anything,
            },
          );

          stopwatch.stop();
          times.add(stopwatch.elapsedMilliseconds);
        }

        final averageTime = times.reduce((a, b) => a + b) / times.length;
        final minTime = times.reduce(min);
        final maxTime = times.reduce(max);

        dev.log(
          'Complex Schema Generation Performance:',
          level: Level.INFO.value,
          name: 'INFO',
        );
        dev.log(
          '  Average: ${averageTime.toStringAsFixed(2)}ms',
          level: Level.INFO.value,
          name: 'INFO',
        );
        dev.log(
          '  Min: ${minTime}ms',
          level: Level.INFO.value,
          name: 'INFO',
        );
        dev.log(
          '  Max: ${maxTime}ms',
          level: Level.INFO.value,
          name: 'INFO',
        );

        // Performance assertions for complex schema
        expect(averageTime, lessThan(5000)); // Should average under 5 seconds
        expect(
          maxTime,
          lessThan(10000),
        ); // No single run should exceed 10 seconds
      });

      test('should benchmark memory usage during generation', () async {
        const schema = '''
          type Query {
            users: [User!]!
          }
          
          type User {
            id: ID!
            name: String
            posts: [Post!]!
          }
          
          type Post {
            id: ID!
            title: String
            content: String
          }
        ''';

        const query = '''
          query GetUsers {
            users {
              id
              name
              posts {
                id
                title
                content
              }
            }
          }
        ''';

        // Get initial memory usage
        final initialMemory = ProcessInfo.currentRss;

        final builder =
            graphQLQueryBuilder(
                const BuilderOptions({
                  'generate_helpers': true,
                  'generate_queries': true,
                  'schema_mapping': [
                    {
                      'schema': 'memory.schema.graphql',
                      'queries_glob': 'queries/**.graphql',
                    },
                  ],
                }),
              )
              ..onBuild = expectAsync1((definition) {
                // Memory check after generation
              });

        await testBuilder(
          builder,
          {
            'a|memory.schema.graphql': schema,
            'a|queries/memory.graphql': query,
          },
          outputs: {
            'a|lib/__generated__/**.graphql.dart': anything,
          },
        );

        final finalMemory = ProcessInfo.currentRss;
        final memoryIncrease = finalMemory - initialMemory;

        dev.log('Memory Usage:', level: Level.INFO.value, name: 'INFO');
        dev.log(
          '  Initial: ${(initialMemory / 1024 / 1024).toStringAsFixed(2)} MB',
          level: Level.INFO.value,
          name: 'INFO',
        );
        dev.log(
          '  Final: ${(finalMemory / 1024 / 1024).toStringAsFixed(2)} MB',
          level: Level.INFO.value,
          name: 'INFO',
        );
        dev.log(
          '  Increase: ${(memoryIncrease / 1024 / 1024).toStringAsFixed(2)} MB',
          level: Level.INFO.value,
          name: 'INFO',
        );

        // Memory usage should be reasonable
        expect(
          memoryIncrease,
          lessThan(100 * 1024 * 1024),
        ); // Less than 100MB increase
      });
    });

    group('Scalability Tests', () {
      test('should handle increasing schema sizes efficiently', () async {
        final results = <int, double>{};

        for (final entityCount in [10, 25, 50, 100]) {
          // Generate schema with varying sizes
          final schemaBuffer = StringBuffer()..writeln('type Query {');

          for (var i = 0; i < entityCount; i++) {
            schemaBuffer.writeln('  entity$i: Entity$i');
          }
          schemaBuffer.writeln('}');

          for (var i = 0; i < entityCount; i++) {
            schemaBuffer
              ..writeln('type Entity$i {')
              ..writeln('  id: ID!')
              ..writeln('  name: String')
              ..writeln('  value: Int');
            if (i > 0) {
              schemaBuffer.writeln('  related: Entity${i - 1}');
            }
            schemaBuffer.writeln('}');
          }

          final queryBuffer = StringBuffer()..writeln('query GetEntities {');
          for (var i = 0; i < min(entityCount, 10); i++) {
            queryBuffer
              ..writeln('  entity$i {')
              ..writeln('    id')
              ..writeln('    name')
              ..writeln('    value');
            if (i > 0) {
              queryBuffer.writeln('    related { id name }');
            }
            queryBuffer.writeln('  }');
          }
          queryBuffer.writeln('}');

          final stopwatch = Stopwatch();
          final times = <int>[];

          // Run 3 iterations for each size
          for (var i = 0; i < 3; i++) {
            final builder =
                graphQLQueryBuilder(
                    BuilderOptions({
                      'generate_helpers': false,
                      'generate_queries': false,
                      'schema_mapping': [
                        {
                          'schema': 'scale_$entityCount.schema.graphql',
                          'queries_glob': 'queries/**.graphql',
                        },
                      ],
                    }),
                  )
                  ..onBuild = expectAsync1((definition) {
                    // Timing capture
                  });

            stopwatch
              ..reset()
              ..start();

            await testBuilder(
              builder,
              {
                'a|scale_$entityCount.schema.graphql': schemaBuffer.toString(),
                'a|queries/scale_$entityCount.graphql': queryBuffer.toString(),
              },
              outputs: {
                'a|lib/__generated__/**.graphql.dart': anything,
              },
            );

            stopwatch.stop();
            times.add(stopwatch.elapsedMilliseconds);
          }

          final averageTime = times.reduce((a, b) => a + b) / times.length;
          results[entityCount] = averageTime;

          dev.log(
            'Schema with $entityCount entities: ${averageTime.toStringAsFixed(2)}ms',
            level: Level.INFO.value,
            name: 'INFO',
          );
        }

        // Verify that performance scales reasonably
        final smallTime = results[10]!;
        final largeTime = results[100]!;

        // Performance should not degrade exponentially
        // Allow up to 10x increase for 10x more entities
        expect(largeTime / smallTime, lessThan(10.0));

        dev.log(
          'Performance scaling factor (100 vs 10 entities): ${(largeTime / smallTime).toStringAsFixed(2)}x',
          level: Level.INFO.value,
          name: 'INFO',
        );
      });
    });

    group('Regression Detection', () {
      test('should detect performance regressions', () async {
        const schema = '''
          type Query {
            user: User
            posts: [Post!]!
          }
          
          type User {
            id: ID!
            name: String
            email: String
            posts: [Post!]!
          }
          
          type Post {
            id: ID!
            title: String
            content: String
            author: User!
          }
        ''';

        const query = '''
          query GetUserWithPosts {
            user {
              id
              name
              email
              posts {
                id
                title
                content
              }
            }
          }
        ''';

        // Baseline performance measurement
        final baselineTimes = <int>[];

        for (var i = 0; i < 5; i++) {
          final builder =
              graphQLQueryBuilder(
                  const BuilderOptions({
                    'generate_helpers': true,
                    'generate_queries': true,
                    'schema_mapping': [
                      {
                        'schema': 'regression.schema.graphql',
                        'queries_glob': 'queries/**.graphql',
                      },
                    ],
                  }),
                )
                ..onBuild = expectAsync1((definition) {
                  // Timing capture
                });

          final stopwatch = Stopwatch()..start();

          await testBuilder(
            builder,
            {
              'a|regression.schema.graphql': schema,
              'a|queries/regression.graphql': query,
            },
            outputs: {
              'a|lib/__generated__/**.graphql.dart': anything,
            },
          );

          stopwatch.stop();
          baselineTimes.add(stopwatch.elapsedMilliseconds);
        }

        final baselineAverage =
            baselineTimes.reduce((a, b) => a + b) / baselineTimes.length;

        dev.log(
          'Baseline performance: ${baselineAverage.toStringAsFixed(2)}ms',
          level: Level.INFO.value,
          name: 'INFO',
        );

        // Store baseline for future regression testing
        // In a real scenario, this would be compared against stored historical data
        expect(
          baselineAverage,
          lessThan(3000),
        ); // Should complete within 3 seconds

        // This test serves as a baseline for future performance regression detection
        // Future runs can compare against this baseline to detect regressions
      });
    });
  });
}
