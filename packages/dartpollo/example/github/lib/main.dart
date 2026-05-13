import 'dart:async';
import 'dart:io';

import 'package:dartpollo/dartpollo.dart';
import 'package:dio/dio.dart';

import '__generated__/search_repositories.graphql.dart';

Future<void> main() async {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['Authorization'] =
            'Bearer ${Platform.environment['GITHUB_TOKEN']}';
        handler.next(options);
      },
    ),
  );

  final client = DartpolloClient(
    'https://api.github.com/graphql',
    client: dio,
  );

  final query = SearchRepositoriesQuery(
    variables: SearchRepositoriesArguments(query: 'flutter'),
  );

  final response = await client.execute(query);

  (response.data?.search.nodes ?? [])
      .whereType<
        SearchRepositories$Query$SearchResultItemConnection$SearchResultItem$Repository
      >()
      .map((r) => r.name)
      .forEach(print);
}
