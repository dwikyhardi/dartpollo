import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:dartpollo_generator/builder.dart';
import 'package:dartpollo_generator/generator/errors.dart';
import 'package:test/test.dart';

void main() {
  group('On errors', () {
    test('When the schema glob matches queries glob', () async {
      final anotherBuilder = graphQLQueryBuilder(
        const BuilderOptions({
          'generate_helpers': false,
          'schema_mapping': [
            {
              'schema': 'non_existent_api.schema.graphql',
              'queries_glob': '**.graphql',
            },
          ],
        }),
      )..onBuild = expectAsync1((_) {}, count: 0);

      final logs = <String>[];
      await testBuilder(anotherBuilder, {
        'a|api.schema.json': '',
        'a|api.schema.grqphql': '',
        'a|some_query.query.graphql': 'query some_query { s }',
      }, onLog: (log) => logs.add(log.toString()));

      expect(
        logs.any((l) => l.contains('queries_glob') || l.contains('schema')),
        isTrue,
      );
    });

    test('When user has not configured an output, auto-generation is used',
        () {
      // output is no longer required - the builder auto-generates it
      final builder = graphQLQueryBuilder(
        const BuilderOptions({
          'generate_helpers': false,
          'schema_mapping': [
            {
              'schema': 'api.schema.grqphql',
              'queries_glob': 'queries/**.graphql',
            },
          ],
        }),
      );
      expect(builder, isNotNull);
    });

    test("When user hasn't configured an queries_glob", () {
      expect(
        () => graphQLQueryBuilder(
          const BuilderOptions({
            'generate_helpers': false,
            'schema_mapping': [
              {
                'schema': 'api.schema.grqphql',
                'output': 'lib/some_query.dart',
              },
            ],
          }),
        ),
        throwsA(
          predicate(
            (e) =>
                e is MissingBuildConfigurationException &&
                e.name == 'schema_mapping => queries_glob required',
          ),
        ),
      );
    });

    test('When user fragments_glob return empty file', () {
      // Without queries_glob, builder throws at construction time
      expect(
        () => graphQLQueryBuilder(
          const BuilderOptions({
            'generate_helpers': false,
            'fragments_glob': '**.frag',
            'schema_mapping': [
              {
                'schema': 'api.schema.grqphql',
                'output': 'lib/some_query.dart',
              },
            ],
          }),
        ),
        throwsA(
          predicate(
            (e) =>
                e is MissingBuildConfigurationException &&
                e.name == 'schema_mapping => queries_glob required',
          ),
        ),
      );
    });

    test(
      'When user fragments_glob at schema level return empty file',
      () {
        // Without queries_glob, builder throws at construction time
        expect(
          () => graphQLQueryBuilder(
            const BuilderOptions({
              'generate_helpers': false,
              'schema_mapping': [
                {
                  'schema': 'api.schema.grqphql',
                  'fragments_glob': '**.schema',
                  'output': 'lib/some_query.dart',
                },
              ],
            }),
          ),
          throwsA(
            predicate(
              (e) =>
                  e is MissingBuildConfigurationException &&
                  e.name == 'schema_mapping => queries_glob required',
            ),
          ),
        );
      },
    );

    test('When schema_mapping is empty', () async {
      try {
        final anotherBuilder = graphQLQueryBuilder(
          const BuilderOptions({
            'generate_helpers': false,
            'schema_mapping': <String>[],
          }),
        );

        await testBuilder(anotherBuilder, {
          'a|api.schema.graphql': ''' ''',
          'a|queries/query.graphql': ''' ''',
        }, onLog: print);
      } on MissingBuildConfigurationException catch (e) {
        expect(e.name, 'schema_mapping');
        return;
      }

      throw Exception('Expected MissingBuildConfigurationException');
    });

    test('When schema_mapping => schema is not defined', () async {
      final anotherBuilder = graphQLQueryBuilder(
        const BuilderOptions({
          'generate_helpers': false,
          'schema_mapping': [
            {
              'queries_glob': '**.graphql',
            },
          ],
        }),
      )..onBuild = expectAsync1((_) {}, count: 0);

      final logs = <String>[];
      await testBuilder(anotherBuilder, {
        'a|api.schema.graphql': ''' ''',
        'a|queries/query.graphql': ''' ''',
      }, onLog: (log) => logs.add(log.toString()));

      expect(
        logs.any((l) => l.contains('schema')),
        isTrue,
      );
    });

    test('When the schema file is not found', () async {
      final anotherBuilder = graphQLQueryBuilder(
        const BuilderOptions({
          'generate_helpers': false,
          'schema_mapping': [
            {
              'schema': 'non_existent_api.schema.graphql',
              'queries_glob': 'lib/**.graphql',
            },
          ],
        }),
      )..onBuild = expectAsync1((_) {}, count: 0);

      final logs = <String>[];
      await testBuilder(anotherBuilder, {
        'a|api.schema.json': '',
        'a|api.schema.grqphql': '',
        'a|some_query.query.graphql': 'query some_query { s }',
      }, onLog: (log) => logs.add(log.toString()));

      expect(
        logs.any(
          (l) => l.contains('non_existent_api.schema.graphql') || l.contains('Missing'),
        ),
        isTrue,
      );
    });

    test('When the queries_glob files are not found', () async {
      final anotherBuilder = graphQLQueryBuilder(
        const BuilderOptions({
          'generate_helpers': false,
          'schema_mapping': [
            {
              'schema': 'api.schema.grqphql',
              'queries_glob': 'lib/**.graphql',
            },
          ],
        }),
      )..onBuild = expectAsync1((_) {}, count: 0);

      final logs = <String>[];
      await testBuilder(anotherBuilder, {
        'a|api.schema.grqphql': '',
        'a|some_query.query.graphql': 'query some_query { s }',
      }, onLog: (log) => logs.add(log.toString()));

      expect(
        logs.any((l) => l.contains('lib/**.graphql') || l.contains('Missing')),
        isTrue,
      );
    });
  });

  test('Fragments with same name but with different selection set', () async {
    final anotherBuilder = graphQLQueryBuilder(
      const BuilderOptions({
        'generate_helpers': false,
        'schema_mapping': [
          {
            'schema': 'api.schema.graphql',
            'queries_glob': 'queries/**.graphql',
            'naming_scheme': 'pathedWithFields',
          },
        ],
      }),
    )..onBuild = expectAsync1((_) {}, count: 0);

    final logs = <String>[];
    await testBuilder(anotherBuilder, {
      'a|api.schema.graphql': '''
              schema {
                query: Query
              }
    
              type Query {
                pokemon: Pokemon
              }
    
              type Pokemon {
                id: String!
                name: String!
              }
              ''',
      'a|queries/query.graphql': '''
                {
                    pokemon {
                      ...Pokemon
                    }
                }
                
                fragment Pokemon on Pokemon {
                  id
                }
              ''',
      'a|queries/anotherQuery.graphql': '''
                {
                    pokemon {
                      ...Pokemon
                    }
                }
                
                fragment Pokemon on Pokemon {
                  id
                  name
                }
              ''',
    }, onLog: (log) => logs.add(log.toString()));

    expect(
      logs.any((l) => l.contains('same name') || l.contains('Duplicated')),
      isTrue,
    );
  });

  test('When the query globs schema location', () async {
    final anotherBuilder = graphQLQueryBuilder(
      const BuilderOptions({
        'generate_helpers': false,
        'schema_mapping': [
          {
            'schema': 'lib/schema.graphql',
            'queries_glob': 'lib/*.graphql',
          },
        ],
      }),
    )..onBuild = expectAsync1((_) {}, count: 0);

    final logs = <String>[];
    await testBuilder(anotherBuilder, {
      'a|api.schema.json': '',
      'a|api.schema.grqphql': '',
      'a|some_query.query.graphql': 'query some_query { s }',
    }, onLog: (log) => logs.add(log.toString()));

    expect(
      logs.any(
        (l) => l.contains('queries_glob') || l.contains('schema'),
      ),
      isTrue,
    );
  });

  test('When the query globs output location', () async {
    final anotherBuilder = graphQLQueryBuilder(
      const BuilderOptions({
        'generate_helpers': false,
        'schema_mapping': [
          {
            'schema': 'schema.graphql',
            'queries_glob': 'lib/*',
          },
        ],
      }),
    )..onBuild = expectAsync1((_) {}, count: 0);

    final logs = <String>[];
    await testBuilder(anotherBuilder, {
      'a|api.schema.json': '',
      'a|api.schema.grqphql': '',
      'a|some_query.query.graphql': 'query some_query { s }',
    }, onLog: (log) => logs.add(log.toString()));

    expect(
      logs.any((l) => l.contains('Missing') || l.contains('schema')),
      isTrue,
    );
  });

  test('When scalar_mapping does not define a custom scalar', () async {
    final anotherBuilder = graphQLQueryBuilder(
      const BuilderOptions({
        'generate_helpers': false,
        'schema_mapping': [
          {
            'schema': 'api.schema.graphql',
            'queries_glob': 'lib/queries/some_query.graphql',
          },
        ],
      }),
    )..onBuild = expectAsync1((_) {}, count: 0);

    final logs = <String>[];
    await testBuilder(anotherBuilder, {
      'a|api.schema.graphql': r'''
scalar DateTime

type Query {
  s: DateTime
}
''',
      'a|lib/queries/some_query.graphql': 'query some_query { s }',
    }, onLog: (log) => logs.add(log.toString()));

    expect(
      logs.any(
        (l) => l.contains('DateTime') || l.contains('scalar'),
      ),
      isTrue,
    );
  });
}
