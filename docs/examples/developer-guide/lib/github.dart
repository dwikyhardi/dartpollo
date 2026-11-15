import 'dart:io';

import 'package:graphql/client.dart';

import '__generated__/viewer.graphql.dart';

Future<Viewer$Query> loadViewer(GraphQLClient client) async {
  final result = await client.query<Viewer$Query>(
    QueryOptions<Viewer$Query>(
      document: VIEWER_QUERY_DOCUMENT,
      operationName: VIEWER_QUERY_DOCUMENT_OPERATION_NAME,
      parserFn: Viewer$Query.fromJson,
      fetchPolicy: FetchPolicy.noCache,
    ),
  );
  if (result.hasException) throw result.exception!;
  final viewer = result.parsedData;
  if (viewer == null) throw StateError('GitHub returned no viewer data');
  return viewer;
}

Future<void> main() async {
  final token = Platform.environment['GITHUB_TOKEN'];
  if (token == null || token.isEmpty) {
    throw StateError('Set GITHUB_TOKEN before running this example');
  }

  final httpLink = HttpLink('https://api.github.com/graphql');
  final link = AuthLink(getToken: () async => 'Bearer $token').concat(httpLink);
  final client = GraphQLClient(link: link, cache: GraphQLCache());

  try {
    final viewer = await loadViewer(client);
    print(viewer.viewer.login);
  } finally {
    await httpLink.dispose();
  }
}
