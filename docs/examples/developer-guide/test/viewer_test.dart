import 'package:dartpollo_developer_guide/__generated__/viewer.graphql.dart';
import 'package:test/test.dart';

void main() {
  test('parses the data object, not the GraphQL response envelope', () {
    final response = {
      'data': {
        'viewer': {'id': 'user-1', 'login': 'octocat'},
      },
    };
    final viewer = Viewer$Query.fromJson(response['data']!);
    expect(viewer.viewer.login, 'octocat');
    expect(viewer.viewer.id, 'user-1');
  });
}
