// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schema_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeneratorOptions _$GeneratorOptionsFromJson(Map json) => GeneratorOptions(
      generateHelpers: json['generate_helpers'] as bool? ?? true,
      generateQueries: json['generate_queries'] as bool? ?? true,
      scalarMapping: (json['scalar_mapping'] as List<dynamic>?)
              ?.map((e) => e == null
                  ? null
                  : ScalarMap.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      fragmentsGlob: json['fragments_glob'] as String?,
      convertEnumToString: json['convert_enum_to_string'] as bool? ?? false,
      schemaMapping: (json['schema_mapping'] as List<dynamic>?)
              ?.map((e) =>
                  SchemaMap.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      ignoreForFile: (json['ignore_for_file'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$GeneratorOptionsToJson(GeneratorOptions instance) =>
    <String, dynamic>{
      'generate_helpers': instance.generateHelpers,
      'generate_queries': instance.generateQueries,
      'scalar_mapping': instance.scalarMapping,
      'fragments_glob': instance.fragmentsGlob,
      'schema_mapping': instance.schemaMapping,
      'ignore_for_file': instance.ignoreForFile,
      'convert_enum_to_string': instance.convertEnumToString,
    };

DartType _$DartTypeFromJson(Map<String, dynamic> json) => DartType(
      name: json['name'] as String?,
      imports: (json['imports'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$DartTypeToJson(DartType instance) => <String, dynamic>{
      'name': instance.name,
      'imports': instance.imports,
    };

ScalarMap _$ScalarMapFromJson(Map<String, dynamic> json) => ScalarMap(
      graphQLType: json['graphql_type'] as String?,
      dartType: json['dart_type'] == null
          ? null
          : DartType.fromJson(json['dart_type']),
      customParserImport: json['custom_parser_import'] as String?,
    );

Map<String, dynamic> _$ScalarMapToJson(ScalarMap instance) => <String, dynamic>{
      'graphql_type': instance.graphQLType,
      'dart_type': instance.dartType,
      'custom_parser_import': instance.customParserImport,
    };

SchemaMap _$SchemaMapFromJson(Map<String, dynamic> json) => SchemaMap(
      output: json['output'] as String?,
      schema: json['schema'] as String?,
      queriesGlob: json['queries_glob'] as String?,
      fragmentsGlob: json['fragments_glob'] as String?,
      typeNameField: json['type_name_field'] as String? ?? '__typename',
      appendTypeName: json['append_type_name'] as bool? ?? false,
      convertEnumToString: json['convert_enum_to_string'] as bool? ?? false,
      namingScheme: $enumDecodeNullable(
              _$NamingSchemeEnumMap, json['naming_scheme'],
              unknownValue: NamingScheme.pathedWithTypes) ??
          NamingScheme.pathedWithTypes,
    );

Map<String, dynamic> _$SchemaMapToJson(SchemaMap instance) => <String, dynamic>{
      'output': instance.output,
      'schema': instance.schema,
      'queries_glob': instance.queriesGlob,
      'fragments_glob': instance.fragmentsGlob,
      'type_name_field': instance.typeNameField,
      'append_type_name': instance.appendTypeName,
      'convert_enum_to_string': instance.convertEnumToString,
      'naming_scheme': _$NamingSchemeEnumMap[instance.namingScheme],
    };

const _$NamingSchemeEnumMap = {
  NamingScheme.pathedWithTypes: 'pathedWithTypes',
  NamingScheme.pathedWithFields: 'pathedWithFields',
  NamingScheme.simple: 'simple',
};
