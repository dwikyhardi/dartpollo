import 'package:dartpollo/builder.dart';
import 'package:dartpollo/generator/data/data.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:collection/collection.dart';

final bool Function(Iterable, Iterable) listEquals =
    const DeepCollectionEquality.unordered().equals;

Future testGenerator({
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
}) async {
  Logger.root.level = Level.INFO;

  final anotherBuilder = graphQLQueryBuilder(BuilderOptions({
    if (!generateHelpers) 'generate_helpers': false,
    if (!generateQueries) 'generate_queries': false,
    'schema_mapping': [
      {
        'schema': 'api.schema.graphql',
        'queries_glob': 'queries/**.graphql',
        'output': 'lib/query.graphql.dart',
        'naming_scheme': namingScheme,
        'append_type_name': appendTypeName,
      }
    ],
    ...builderOptionsMap,
  }));

  anotherBuilder.onBuild = expectAsync1((definition) {
    log.fine(definition);
    // Create a copy of the definition with schemaMap set to null for comparison
    final definitionForComparison = LibraryDefinition(
      basename: definition.basename,
      queries: definition.queries,
      customImports: definition.customImports,
    );
    expect(definitionForComparison, libraryDefinition);
  }, count: 1);

  return await testBuilder(
    anotherBuilder,
    {
      'a|api.schema.graphql': schema,
      'a|queries/query.graphql': query,
      ...sourceAssetsMap,
    },
    outputs: {
      'a|lib/query.graphql.dart': anything, // Use 'anything' matcher to accept any output
      ...outputsMap,
    },
    onLog: print,
  );
}

// Helper function to normalize content for comparison
String _normalizeContent(String content) {
  // Split the content into lines
  final lines = content.split('\n');

  // Separate import statements from the rest of the content
  final imports = <String>[];
  final otherLines = <String>[];

  for (final line in lines) {
    if (line.trim().startsWith('import ')) {
      imports.add(line.trim());
    } else {
      otherLines.add(line);
    }
  }

  // Sort import statements
  imports.sort();

  // Combine everything back together
  return [...imports, ...otherLines].join('\n');
}

Future testNaming({
  required String query,
  required String schema,
  required List<String> expectedNames,
  required String namingScheme,
  bool shouldFail = false,
}) {
  final anotherBuilder = graphQLQueryBuilder(BuilderOptions({
    'generate_helpers': false,
    'generate_queries': false,
    'schema_mapping': [
      {
        'schema': 'api.schema.graphql',
        'queries_glob': 'queries/**.graphql',
        'output': 'lib/query.dart',
        'naming_scheme': namingScheme,
      }
    ],
  }));

  if (!shouldFail) {
    anotherBuilder.onBuild = expectAsync1((definition) {
      final names = definition.queries.first.classes
          .map((e) => e.name.namePrintable)
          .toSet();
      log.fine(names);
      expect(names.toSet(), equals(expectedNames.toSet()));
    }, count: 1);
  }

  return testBuilder(
    anotherBuilder,
    {
      'a|api.schema.graphql': schema,
      'a|queries/query.graphql': query,
    },
    onLog: print,
  );
}
