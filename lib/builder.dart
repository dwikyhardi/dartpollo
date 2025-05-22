import 'dart:async';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';

import './generator.dart';
import './generator/print_helpers.dart';
import './schema/schema_options.dart';
import 'generator/data/library_definition.dart';
import 'generator/errors.dart';
import 'transformer/add_typename_transformer.dart';

/// [GraphQLQueryBuilder] instance, to be used by `build_runner`.
GraphQLQueryBuilder graphQLQueryBuilder(BuilderOptions options) =>
    GraphQLQueryBuilder(options);

String _addGraphQLExtensionToPathIfNeeded(String path) {
  if (!path.endsWith('.graphql.dart')) {
    return path.replaceAll(RegExp(r'\.dart$'), '.graphql.dart');
  }
  return path;
}

List<String> _builderOptionsToExpectedOutputs(BuilderOptions builderOptions) {
  final schemaMapping =
      GeneratorOptions.fromJson(builderOptions.config).schemaMapping;

  if (schemaMapping.isEmpty) {
    throw MissingBuildConfigurationException('schema_mapping');
  }

  if (schemaMapping.any((s) => s.output == null)) {
    throw MissingBuildConfigurationException('schema_mapping => output');
  }

  return schemaMapping
      .map((s) {
        final outputWithoutLib = s.output!.replaceAll(RegExp(r'^lib/'), '');

        return {
          outputWithoutLib,
          _addGraphQLExtensionToPathIfNeeded(outputWithoutLib),
        }.toList();
      })
      .expand((e) => e)
      .toList();
}

/// Main Dartpollo builder.
class GraphQLQueryBuilder implements Builder {
  /// Creates a builder from [BuilderOptions].
  GraphQLQueryBuilder(BuilderOptions builderOptions)
      : options = GeneratorOptions.fromJson(builderOptions.config),
        expectedOutputs = _builderOptionsToExpectedOutputs(builderOptions);

  /// This generator options, gathered from `build.yaml` file.
  final GeneratorOptions options;

  /// List FragmentDefinitionNode in fragments_glob.
  // List<FragmentDefinitionNode> fragmentsCommon = [];

  /// The generated output file.
  final List<String> expectedOutputs;

  /// Callback fired when the generator processes a [QueryDefinition].
  OnBuildQuery? onBuild;

  @override
  Map<String, List<String>> get buildExtensions => {
        r'$lib$': expectedOutputs,
      };

  /// read asset files
  Future<List<DocumentNode>> readGraphQlFiles(
    BuildStep buildStep,
    String schema,
  ) async {
    final schemaAssetStream = buildStep.findAssets(Glob(schema));

    return await schemaAssetStream
        .asyncMap(
          (asset) async => parseString(
            await buildStep.readAsString(asset),
            url: asset.path,
          ),
        )
        .toList();
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    List<FragmentDefinitionNode> fragmentsCommon = [];

    GeneratorOptions copyOptions = options;
    if (copyOptions.convertEnumToString) {
      final copyMapping = copyOptions.schemaMapping
          .map(
            (e) => e.copyWith(
                convertEnumToString: copyOptions.convertEnumToString),
          )
          .toList();

      copyOptions = copyOptions.copyWith(
        schemaMapping: copyMapping,
      );
    }

    final fragmentsGlob = copyOptions.fragmentsGlob;
    if (fragmentsGlob != null) {
      final commonFragments = (await readGraphQlFiles(buildStep, fragmentsGlob))
          .map((e) => e.definitions.whereType<FragmentDefinitionNode>())
          .expand((e) => e)
          .toList();

      if (commonFragments.isEmpty) {
        throw MissingFilesException(fragmentsGlob);
      }

      fragmentsCommon.addAll(commonFragments);
    }

    for (final schemaMap in copyOptions.schemaMapping) {
      List<FragmentDefinitionNode> schemaCommonFragments = [
        ...fragmentsCommon,
      ];
      final schemaFragmentsGlob = schemaMap.fragmentsGlob;
      if (schemaFragmentsGlob != null) {
        final schemaFragments =
            (await readGraphQlFiles(buildStep, schemaFragmentsGlob))
                .map((e) => e.definitions.whereType<FragmentDefinitionNode>())
                .expand((e) => e)
                .toList();

        if (schemaFragments.isEmpty) {
          throw MissingFilesException(schemaFragmentsGlob);
        }

        schemaCommonFragments.addAll(schemaFragments);
      }

      final queriesGlob = schemaMap.queriesGlob;
      final schema = schemaMap.schema;
      final output = schemaMap.output;

      if (schema == null) {
        throw MissingBuildConfigurationException('schema_map => schema');
      }

      if (output == null) {
        throw MissingBuildConfigurationException('schema_map => output');
      }

      // Loop through all files in glob
      if (queriesGlob == null) {
        throw MissingBuildConfigurationException('schema_map => queries_glob');
      } else if (Glob(queriesGlob).matches(schema)) {
        throw QueryGlobsSchemaException();
      } else if (Glob(queriesGlob).matches(output)) {
        throw QueryGlobsOutputException();
      }

      final gqlSchema = await readGraphQlFiles(buildStep, schema);

      if (gqlSchema.isEmpty) {
        throw MissingFilesException(schema);
      }

      var gqlDocs = await readGraphQlFiles(buildStep, queriesGlob);

      if (gqlDocs.isEmpty) {
        throw MissingFilesException(queriesGlob);
      }

      if (schemaMap.appendTypeName) {
        gqlDocs = gqlDocs.map(
          (doc) {
            final transformed =
                transform(doc, [AppendTypename(schemaMap.typeNameField)]);

            // transform makes definitions growable: false so just recreate it again
            // as far as we need to add some elements there lately
            return DocumentNode(
              definitions: List.from(transformed.definitions),
              span: transformed.span,
            );
          },
        ).toList();

        schemaCommonFragments = schemaCommonFragments
            .map((fragments) => transform(
                  fragments,
                  [AppendTypename(schemaMap.typeNameField)],
                ))
            .toList();
      }

      final libDefinition = generateLibrary(
        _addGraphQLExtensionToPathIfNeeded(output),
        gqlDocs,
        copyOptions,
        schemaMap,
        schemaCommonFragments,
        gqlSchema.first,
      );

      if (onBuild != null) {
        onBuild!(libDefinition);
      }

      final buffer = StringBuffer();

      final outputFileId = AssetId(
        buildStep.inputId.package,
        _addGraphQLExtensionToPathIfNeeded(output),
      );

      writeLibraryDefinitionToBuffer(
        buffer,
        copyOptions.ignoreForFile,
        libDefinition,
      );

      await buildStep.writeAsString(outputFileId, buffer.toString());

      if (!output.endsWith('.graphql.dart')) {
        final forwarderOutputFileId =
            AssetId(buildStep.inputId.package, output);
        await buildStep.writeAsString(
            forwarderOutputFileId, writeLibraryForwarder(libDefinition));
      }
    }
  }
}
