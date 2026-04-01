import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:dartpollo_generator/builder.dart';
import 'package:test/test.dart';

void main() {
  group('On errors', () {
    test('When there\'s a missing fragment being used', () async {
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
      await testBuilder(
        anotherBuilder,
        {
          'a|api.schema.graphql': '''
              type Query {
                a: String!
              }
              ''',
          'a|lib/queries/some_query.graphql':
              'query { ...nonExistentFragment }',
        },
        onLog: (log) => logs.add(log.toString()),
      );

      expect(
        logs.any(
          (l) =>
              l.contains('fragment') ||
              l.contains('Fragment') ||
              l.contains('nonExistentFragment'),
        ),
        isTrue,
      );
    });
  });
}
