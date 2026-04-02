import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:dartpollo_generator/builder.dart';
import 'package:test/test.dart';

void main() {
  group('On errors', () {
    test('When there\'s no root type on schema', () async {
      final anotherBuilder = graphQLQueryBuilder(
        const BuilderOptions({
          'generate_helpers': false,
          'schema_mapping': [
            {
              'schema': 'lib/api.schema.graphql',
              'queries_glob': 'lib/**.query.graphql',
            },
          ],
        }),
      )..onBuild = expectAsync1((_) {}, count: 0);

      final logs = <String>[];
      await testBuilder(
        anotherBuilder,
        {
          'a|lib/api.schema.graphql': '',
          'a|lib/some.query.graphql': 'query { a }',
        },
        onLog: (log) => logs.add(log.toString()),
      );

      expect(
        logs.any((l) => l.contains('root type') || l.contains('Query')),
        isTrue,
      );
    });
  });
}
