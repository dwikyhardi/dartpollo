import 'package:test/test.dart';

void main() {
  group('Example tests for guidelines', () {
    test('Basic arithmetic test', () {
      expect(3 * 4, equals(12));
    });

    test('String manipulation test', () {
      final projectName = 'Dartpollo';
      expect(projectName.toLowerCase(), equals('dartpollo'));
      expect(projectName.split('').reversed.join(), equals('olloptraD'));
    });
  });
}
