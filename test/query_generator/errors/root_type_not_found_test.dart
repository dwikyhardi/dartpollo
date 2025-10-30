import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:dartpollo/builder.dart';
import 'package:dartpollo/generator/errors.dart';
import 'package:test/test.dart';

void main() {
  group('On errors', () {
    test('When there\'s no root type on schema', () {
      final anotherBuilder = graphQLQueryBuilder(
        const BuilderOptions({
          'generate_helpers': false,
          'schema_mapping': [
            {
              'schema': 'lib/api.schema.graphql',
              'queries_glob': 'lib/**.query.graphql',
              'output': 'lib/some_query.graphql.dart',
            },
          ],
        }),
      )..onBuild = expectAsync1((_) {}, count: 0);

      expect(
        () => testBuilder(
          anotherBuilder,
          {
            'a|lib/api.schema.graphql': '',
            'a|lib/some.query.graphql': 'query { a }',
          },
          onLog: print,
        ),
        throwsA(predicate((e) => e is MissingRootTypeException)),
      );
    });
  });
}
