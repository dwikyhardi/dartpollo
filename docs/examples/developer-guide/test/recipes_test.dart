import 'package:dartpollo_developer_guide/__generated__/accounts.graphql.dart';
import 'package:dartpollo_developer_guide/__generated__/search.graphql.dart';
import 'package:dartpollo_developer_guide/__generated__/update_viewer.graphql.dart';
import 'package:dartpollo_developer_guide/__generated__/users.graphql.dart';
import 'package:dartpollo_developer_guide/github.dart';
import 'package:dartpollo_developer_guide/recipes.dart';
import 'package:gql/language.dart' show printNode;
import 'package:graphql/client.dart';
import 'package:test/test.dart';

void main() {
  test('nested input and enum become GraphQL wire values', () {
    expect(profileUpdate().toJson(), {
      'input': {
        'profile': {'displayName': 'Ada', 'bio': 'Builds Dart tools'},
        'visibility': 'PUBLIC',
      },
    });
  });

  test('nullable variables and input fields serialize null, not defaults', () {
    expect(UsersArguments(size: 5).toJson(), {'limit': null, 'size': 5});
    expect(ProfileInput(displayName: 'Ada').toJson(), {
      'displayName': 'Ada',
      'bio': null,
    });
    expect(usersWithServerDefault(), {'size': 5});
    expect(printNode(USERS_QUERY_DOCUMENT), contains(r'$limit: Int = 10'));
    expect(printNode(USERS_QUERY_DOCUMENT), contains(r'$size: Int! = 5'));
  });

  test('union results expose concrete fields and handle null items', () {
    final data = Search$Query.fromJson({
      'search': [
        {'__typename': 'Repository', 'name': 'dartpollo'},
        {'__typename': 'User', 'login': 'octocat'},
        null,
      ],
    });
    expect(repositoryNames(data), ['dartpollo']);
    expect(repositoryNames(Search$Query.fromJson({'search': null})), isEmpty);
  });

  test('unknown response enum maps to the generated fallback', () {
    final data = UpdateViewer$Mutation.fromJson({
      'updateViewer': {
        'id': 'user-1',
        'login': 'octocat',
        'visibility': 'FUTURE_VALUE',
      },
    });
    expect(data.updateViewer.visibility, Visibility.unknown);
  });

  test('scalar converters round trip values, null items and a null list', () {
    for (final linkedIds in <List<String?>?>[
      ['account-2', null],
      null,
      [],
    ]) {
      final json = {
        'viewer': {'accountId': 'account-1', 'linkedIds': linkedIds},
      };
      final data = Accounts$Query.fromJson(json);
      expect(data.viewer.accountId.value, 'account-1');
      expect(data.toJson(), json);
    }
  });

  test(
    'query integration sends the generated operation and parses data',
    () async {
      final link = Link.function((request, [forward]) {
        expect(request.operation.operationName, 'Viewer');
        expect(printNode(request.operation.document), contains('viewer'));
        return Stream.value(
          Response(
            data: {
              'viewer': {'id': 'user-1', 'login': 'octocat'},
            },
            response: const {},
          ),
        );
      });
      addTearDown(link.dispose);
      final client = GraphQLClient(link: link, cache: GraphQLCache());
      expect((await loadViewer(client)).viewer.login, 'octocat');
    },
  );

  test('query integration reports GraphQL errors', () async {
    final link = Link.function(
      (request, [forward]) => Stream.value(
        Response(
          errors: [const GraphQLError(message: 'Permission denied')],
          response: const {},
        ),
      ),
    );
    addTearDown(link.dispose);
    final client = GraphQLClient(link: link, cache: GraphQLCache());
    await expectLater(loadViewer(client), throwsA(isA<OperationException>()));
  });

  test(
    'mutation sends nested variables and a self-contained fragment',
    () async {
      final link = Link.function((request, [forward]) {
        expect(request.operation.operationName, 'UpdateViewer');
        expect(request.variables, profileUpdate().toJson());
        expect(
          printNode(request.operation.document),
          contains('fragment UserIdentity'),
        );
        return Stream.value(
          Response(
            data: {
              'updateViewer': {
                'id': 'user-1',
                'login': 'octocat',
                'visibility': 'PUBLIC',
              },
            },
            response: const {},
          ),
        );
      });
      addTearDown(link.dispose);
      final client = GraphQLClient(link: link, cache: GraphQLCache());
      expect(
        (await updateViewer(client)).updateViewer.visibility,
        Visibility.public,
      );
    },
  );
}
