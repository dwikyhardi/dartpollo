import 'package:graphql/client.dart';

import '__generated__/search.graphql.dart';
import '__generated__/update_viewer.graphql.dart';
import '__generated__/users.graphql.dart';

UpdateViewerArguments profileUpdate() => UpdateViewerArguments(
  input: UpdateViewerInput(
    profile: ProfileInput(displayName: 'Ada', bio: 'Builds Dart tools'),
    visibility: Visibility.public,
  ),
);

Future<UpdateViewer$Mutation> updateViewer(GraphQLClient client) async {
  final result = await client.mutate<UpdateViewer$Mutation>(
    MutationOptions<UpdateViewer$Mutation>(
      document: UPDATE_VIEWER_MUTATION_DOCUMENT,
      operationName: UPDATE_VIEWER_MUTATION_DOCUMENT_OPERATION_NAME,
      variables: profileUpdate().toJson(),
      parserFn: UpdateViewer$Mutation.fromJson,
      fetchPolicy: FetchPolicy.noCache,
    ),
  );
  if (result.hasException) throw result.exception!;
  final data = result.parsedData;
  if (data == null) throw StateError('Mutation returned no data');
  return data;
}

List<String> repositoryNames(Search$Query data) => (data.search ?? [])
    .whereType<Search$Query$SearchResult$Repository>()
    .map((repository) => repository.name)
    .toList();

Map<String, dynamic> usersWithServerDefault() {
  final variables = UsersArguments(size: 5).toJson();
  // Omit only this variable; null values for other variables remain intentional.
  variables.remove('limit');
  return variables;
}
