import 'package:dartpollo/generator/data/query_definition.dart';
import 'package:dartpollo/generator/data_printer.dart';
import 'package:dartpollo/generator/helpers.dart';
import 'package:equatable/equatable.dart';

import '../../schema/schema_options.dart';

/// Callback fired when the generator processes a [LibraryDefinition].
typedef OnBuildQuery = void Function(LibraryDefinition definition);

/// Define a whole library file, the output of a single [SchemaMap] code
/// generation.
class LibraryDefinition extends Equatable with DataPrinter {
  /// The output file basename.
  final String basename;

  /// A list of queries.
  final Iterable<QueryDefinition> queries;

  /// Any other custom package imports, defined in `build.yaml`.
  final Iterable<String> customImports;

  final SchemaMap? schemaMap;

  /// Instantiate a library definition.
  LibraryDefinition({
    required this.basename,
    this.queries = const [],
    this.customImports = const [],
    this.schemaMap,
  }) : assert(hasValue(basename));

  @override
  Map<String, Object?> get namedProps => {
        'basename': basename,
        'queries': queries,
        'customImports': customImports,
        'schemaMap': schemaMap,
      };
}
