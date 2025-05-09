import 'package:test/test.dart';

void main() {
  group('Simple tests', () {
    test('Basic assertion test', () {
      expect(2 + 2, equals(4));
    });

    test('String operations test', () {
      final str = 'Hello, Dartpollo!';
      expect(str.contains('Dartpollo'), isTrue);
      expect(str.length, equals(17));
    });
  });
}
