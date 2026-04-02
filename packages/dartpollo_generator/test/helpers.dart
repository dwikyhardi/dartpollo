import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:collection/collection.dart';
import 'package:dartpollo_generator/builder.dart';
import 'package:dartpollo_generator/generator/data/data.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

final bool Function(Iterable<dynamic>, Iterable<dynamic>) listEquals =
    const DeepCollectionEquality.unordered().equals;

/// Compares two LibraryDefinitions structurally, ignoring naming differences
/// caused by the auto-generated output path (e.g. `**` prefix vs query name prefix).
void _assertLibraryDefinitionsMatch(
  LibraryDefinition actual,
  LibraryDefinition expected,
) {
  // Same basename
  expect(actual.basename, expected.basename, reason: 'basename should match');

  // Same number of queries
  final actualQueries = actual.queries.toList();
  final expectedQueries = expected.queries.toList();
  expect(
    actualQueries.length,
    expectedQueries.length,
    reason: 'query count should match',
  );

  // Sort both lists by operationName so order doesn't matter
  actualQueries.sort((a, b) => a.operationName.compareTo(b.operationName));
  expectedQueries.sort((a, b) => a.operationName.compareTo(b.operationName));

  for (var qi = 0; qi < expectedQueries.length; qi++) {
    final actualQuery = actualQueries[qi];
    final expectedQuery = expectedQueries[qi];

    // Same number of classes
    final actualClasses = actualQuery.classes.toList();
    final expectedClasses = expectedQuery.classes.toList();
    expect(
      actualClasses.length,
      expectedClasses.length,
      reason: 'class count should match for query $qi',
    );

    // Same generateHelpers
    expect(
      actualQuery.generateHelpers,
      expectedQuery.generateHelpers,
      reason: 'generateHelpers should match for query $qi',
    );

    for (var ci = 0; ci < expectedClasses.length; ci++) {
      final actualClass = actualClasses[ci];
      final expectedClass = expectedClasses[ci];

      // Compare class type (ClassDefinition vs EnumDefinition vs FragmentClassDefinition)
      expect(
        actualClass.runtimeType,
        expectedClass.runtimeType,
        reason: 'class type should match for query $qi class $ci',
      );

      if (expectedClass is ClassDefinition && actualClass is ClassDefinition) {
        // Compare non-typename properties by name
        final actualPropNames = actualClass.properties
            .where((p) => !p.isResolveType)
            .map((p) => p.name.name)
            .toSet();
        final expectedPropNames = expectedClass.properties
            .where((p) => !p.isResolveType)
            .map((p) => p.name.name)
            .toSet();
        expect(
          actualPropNames,
          expectedPropNames,
          reason:
              'non-typename property names should match for class ${expectedClass.name.namePrintable}',
        );

        // Compare isInput
        expect(
          actualClass.isInput,
          expectedClass.isInput,
          reason:
              'isInput should match for class ${expectedClass.name.namePrintable}',
        );

        // Compare factoryPossibilities count
        expect(
          actualClass.factoryPossibilities.length,
          expectedClass.factoryPossibilities.length,
          reason:
              'factoryPossibilities count should match for class ${expectedClass.name.namePrintable}',
        );

        // Compare mixins count
        expect(
          actualClass.mixins.length,
          expectedClass.mixins.length,
          reason:
              'mixins count should match for class ${expectedClass.name.namePrintable}',
        );
      }
    }
  }
}

Future<TestBuilderResult> testGenerator({
  required String query,
  required LibraryDefinition libraryDefinition,
  required String generatedFile,
  required String schema,
  String namingScheme = 'pathedWithTypes',
  bool appendTypeName = false,
  bool generateHelpers = false,
  bool generateQueries = false,
  Map<String, dynamic> builderOptionsMap = const {},
  Map<String, Object> sourceAssetsMap = const {},
  Map<String, Object> outputsMap = const {},
}) {
  Logger.root.level = Level.INFO;

  final anotherBuilder =
      graphQLQueryBuilder(
          BuilderOptions({
            if (!generateHelpers) 'generate_helpers': false,
            if (!generateQueries) 'generate_queries': false,
            'schema_mapping': [
              {
                'schema': 'api.schema.graphql',
                'queries_glob': 'queries/**.graphql',
                'naming_scheme': namingScheme,
                'append_type_name': appendTypeName,
              },
            ],
            ...builderOptionsMap,
          }),
        )
        ..onBuild = expectAsync1((definition) {
          log.fine(definition);
          final definitionForComparison = LibraryDefinition(
            basename: definition.basename,
            queries: definition.queries,
            customImports: definition.customImports,
          );
          _assertLibraryDefinitionsMatch(
            definitionForComparison,
            libraryDefinition,
          );
        });

  return testBuilder(
    anotherBuilder,
    {
      'a|api.schema.graphql': schema,
      'a|queries/query.graphql': query,
      ...sourceAssetsMap,
    },
    outputs: {
      'a|lib/__generated__/**.graphql.dart': anything,
      ...outputsMap,
    },
    onLog: print,
  );
}

Future<TestBuilderResult> testNaming({
  required String query,
  required String schema,
  required List<String> expectedNames,
  required String namingScheme,
  bool shouldFail = false,
}) {
  final anotherBuilder = graphQLQueryBuilder(
    BuilderOptions({
      'generate_helpers': false,
      'generate_queries': false,
      'schema_mapping': [
        {
          'schema': 'api.schema.graphql',
          'queries_glob': 'queries/**.graphql',
          'naming_scheme': namingScheme,
        },
      ],
    }),
  );

  if (!shouldFail) {
    anotherBuilder.onBuild = expectAsync1((definition) {
      final names = definition.queries.first.classes
          .map((e) => e.name.namePrintable)
          .toSet();
      log.fine(names);
      expect(names.toSet(), equals(expectedNames.toSet()));
    });
  }

  return testBuilder(
    anotherBuilder,
    {
      'a|api.schema.graphql': schema,
      'a|queries/query.graphql': query,
    },
    outputs: {
      'a|lib/__generated__/**.graphql.dart': anything,
    },
    onLog: print,
  );
}
