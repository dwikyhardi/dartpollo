import 'package:json_annotation/json_annotation.dart';
import 'package:yaml/yaml.dart';

// I can't use the default json_serializable flow because the dartpollo generator
// would crash when importing schema_options.dart file.
part 'schema_options.g.dart';

/// This generator options, gathered from `build.yaml` file.
@JsonSerializable(fieldRename: FieldRename.snake, anyMap: true)
class GeneratorOptions {
  /// If instances of [GraphQLQuery] should be generated.
  @JsonKey(defaultValue: true)
  final bool generateHelpers;

  /// If query documents and operation names should be generated
  @JsonKey(defaultValue: true)
  final bool generateQueries;

  /// A list of scalar mappings.
  @JsonKey(defaultValue: [])
  final List<ScalarMap?> scalarMapping;

  /// A list of fragments apply for all query files without declare them.
  final String? fragmentsGlob;

  /// A list of schema mappings.
  @JsonKey(defaultValue: [])
  final List<SchemaMap> schemaMapping;

  /// A list of linter rules to ignore
  /// in generated files.
  @JsonKey(defaultValue: [])
  final List<String> ignoreForFile;

  @JsonKey(defaultValue: false)
  final bool convertEnumToString;

  /// Instantiate generator options.
  GeneratorOptions({
    this.generateHelpers = true,
    this.generateQueries = true,
    this.scalarMapping = const [],
    this.fragmentsGlob,
    this.convertEnumToString = false,
    this.schemaMapping = const [],
    this.ignoreForFile = const [],
  });

  /// Build options from a JSON map.
  factory GeneratorOptions.fromJson(Map<String, dynamic> json) =>
      _$GeneratorOptionsFromJson(json);

  /// Convert this options instance to JSON.
  Map<String, dynamic> toJson() => _$GeneratorOptionsToJson(this);

  /// Creates a copy of this [GeneratorOptions] but with the given fields
  /// replaced with the new values.
  GeneratorOptions copyWith({
    bool? generateHelpers,
    bool? generateQueries,
    List<ScalarMap?>? scalarMapping,
    String? fragmentsGlob,
    List<SchemaMap>? schemaMapping,
    List<String>? ignoreForFile,
    bool? convertEnumToString,
  }) {
    return GeneratorOptions(
      generateHelpers: generateHelpers ?? this.generateHelpers,
      generateQueries: generateQueries ?? this.generateQueries,
      scalarMapping: scalarMapping ?? this.scalarMapping,
      fragmentsGlob: fragmentsGlob ?? this.fragmentsGlob,
      schemaMapping: schemaMapping ?? this.schemaMapping,
      ignoreForFile: ignoreForFile ?? this.ignoreForFile,
      convertEnumToString: convertEnumToString ?? this.convertEnumToString,
    );
  }
}

/// Define a Dart type.
@JsonSerializable()
class DartType {
  /// Dart type name.
  final String? name;

  /// Package imports related to this type.
  @JsonKey(defaultValue: <String>[])
  final List<String> imports;

  /// Instantiate a Dart type.
  const DartType({
    this.name,
    this.imports = const [],
  });

  /// Build a Dart type from a JSON string or map.
  factory DartType.fromJson(dynamic json) {
    if (json is String) {
      return DartType(name: json);
    } else if (json is Map<String, dynamic>) {
      return _$DartTypeFromJson(json);
    } else if (json is YamlMap) {
      return _$DartTypeFromJson({
        'name': json['name'],
        'imports': (json['imports'] as YamlList).map((s) => s).toList(),
      });
    } else {
      throw 'Invalid YAML: $json';
    }
  }

  /// Convert this Dart type instance to JSON.
  Map<String, dynamic> toJson() => _$DartTypeToJson(this);
}

/// Maps a GraphQL scalar to a Dart type.
@JsonSerializable(fieldRename: FieldRename.snake)
class ScalarMap {
  /// The GraphQL type name.
  @JsonKey(name: 'graphql_type')
  final String? graphQLType;

  /// The Dart type linked to this GraphQL type.
  final DartType? dartType;

  /// If custom parser would be used.
  final String? customParserImport;

  /// Instatiates a scalar mapping.
  ScalarMap({
    this.graphQLType,
    this.dartType,
    this.customParserImport,
  });

  /// Build a scalar mapping from a JSON map.
  factory ScalarMap.fromJson(Map<String, dynamic> json) =>
      _$ScalarMapFromJson(json);

  /// Convert this scalar mapping instance to JSON.
  Map<String, dynamic> toJson() => _$ScalarMapToJson(this);
}

/// The naming scheme to be used on generated classes names.
enum NamingScheme {
  /// Default, where the names of previous types are used as prefix of the
  /// next class. This can generate duplication on certain schemas.
  pathedWithTypes,

  /// The names of previous fields are used as prefix of the next class.
  pathedWithFields,

  /// Considers only the actual GraphQL class name. This will probably lead to
  /// duplication and an Dartpollo error unless user uses aliases.
  simple,
}

/// Maps a GraphQL schema to queries files.
@JsonSerializable(fieldRename: FieldRename.snake)
class SchemaMap {
  /// The output file of this queries glob.
  final String? output;

  /// The GraphQL schema string.
  final String? schema;

  /// A [Glob] to find queries files.
  final String? queriesGlob;

  /// A [Glob] to find your fragments files.
  final String? fragmentsGlob;

  /// The resolve type field used on this schema.
  @JsonKey(defaultValue: '__typename')
  final String typeNameField;

  /// The resolve type field used on this schema.
  @JsonKey(defaultValue: false)
  final bool appendTypeName;

  @JsonKey(defaultValue: false)
  final bool convertEnumToString;

  /// The naming scheme to be used.
  ///
  /// - [NamingScheme.pathedWithTypes]: default, where the names of
  /// previous classes are used to generate the prefix.
  /// - [NamingScheme.pathedWithFields]: the field names are joined
  /// together to generate the path.
  /// - [NamingScheme.simple]: considers only the actual GraphQL class name.
  /// This will probably lead to duplication and an Dartpollo error unless you
  /// use aliases.
  @JsonKey(unknownEnumValue: NamingScheme.pathedWithTypes)
  final NamingScheme? namingScheme;

  /// Instantiates a schema mapping.
  SchemaMap({
    this.output,
    this.schema,
    this.queriesGlob,
    this.fragmentsGlob,
    this.typeNameField = '__typename',
    this.appendTypeName = false,
    this.convertEnumToString = false,
    this.namingScheme = NamingScheme.pathedWithTypes,
  });

  /// Build a schema mapping from a JSON map.
  factory SchemaMap.fromJson(Map<String, dynamic> json) =>
      _$SchemaMapFromJson(json);

  /// Convert this schema mapping instance to JSON.
  Map<String, dynamic> toJson() => _$SchemaMapToJson(this);

  SchemaMap copyWith({
    String? output,
    String? schema,
    String? queriesGlob,
    String? fragmentsGlob,
    String? typeNameField,
    bool? appendTypeName,
    bool? convertEnumToString,
    NamingScheme? namingScheme,
  }) {
    return SchemaMap(
      output: output ?? this.output,
      schema: schema ?? this.schema,
      queriesGlob: queriesGlob ?? this.queriesGlob,
      fragmentsGlob: fragmentsGlob ?? this.fragmentsGlob,
      typeNameField: typeNameField ?? this.typeNameField,
      appendTypeName: appendTypeName ?? this.appendTypeName,
      convertEnumToString: convertEnumToString ?? this.convertEnumToString,
      namingScheme: namingScheme ?? this.namingScheme,
    );
  }
}
