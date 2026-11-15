import '__generated__/viewer.graphql.dart';

void main() {
  final viewer = Viewer$Query.fromJson({
    'viewer': {'id': 'user-1', 'login': 'octocat'},
  });
  print(viewer.viewer.login);
}
