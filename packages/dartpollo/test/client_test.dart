import 'package:dartpollo/client.dart';
import 'package:dartpollo_annotation/schema/graphql_response.dart';
import 'package:gql_exec/gql_exec.dart';
import 'package:test/test.dart';

import 'helpers/test_helpers.dart';

class _TestContextEntry extends ContextEntry {
  const _TestContextEntry();

  @override
  List<Object?> get fieldsForEquality => [];
}

void main() {
  group('DartpolloClient', () {
    group('fromLink constructor', () {
      test('creates client with custom link', () {
        final client = DartpolloClient.fromLink(MockLink({'hello': 'world'}));
        expect(client, isNotNull);
      });
    });

    group('execute', () {
      test('returns parsed response', () async {
        final client = DartpolloClient.fromLink(
          MockLink({
            'user': {'name': 'John'},
          }),
        );

        final response = await client.execute(SimpleQuery());

        expect(response, isA<GraphQLResponse<Map<String, dynamic>>>());
        expect(response.data, {
          'user': {'name': 'John'},
        });
      });

      test('passes variables to request', () async {
        final link = CapturingLink(
          data: {
            'user': {'name': 'John'},
          },
        );
        final client = DartpolloClient.fromLink(link);

        await client.execute(TestQueryWithVars(const {'id': '123'}));

        expect(link.capturedRequest!.variables, {'id': '123'});
      });

      test('passes context to request', () async {
        final link = CapturingLink(data: {'data': true});
        final client = DartpolloClient.fromLink(link);
        final context = const Context().withEntry(const _TestContextEntry());

        await client.execute(SimpleQuery(), context: context);

        expect(
          link.capturedRequest!.context.entry<_TestContextEntry>(),
          isNotNull,
        );
      });

      test('handles null data response', () async {
        final client = DartpolloClient.fromLink(NullDataLink());

        final response = await client.execute(SimpleQuery());

        expect(response.data, isNull);
      });

      test('includes errors from response', () async {
        final client = DartpolloClient.fromLink(ErrorResponseLink());

        final response = await client.execute(SimpleQuery());

        expect(response.errors, isNotNull);
        expect(response.errors, hasLength(1));
      });
    });

    group('stream', () {
      test('returns stream of responses', () async {
        final client = DartpolloClient.fromLink(
          MultiResponseLink([
            {'first': true},
            {'second': true},
          ]),
        );

        final responses = await client.stream(SimpleQuery()).toList();

        expect(responses, hasLength(2));
        expect(responses[0].data, {'first': true});
        expect(responses[1].data, {'second': true});
      });
    });

    group('dispose', () {
      test('dispose on fromLink client does not throw', () {
        final client = DartpolloClient.fromLink(MockLink({}));
        expect(client.dispose, returnsNormally);
      });
    });
  });
}
