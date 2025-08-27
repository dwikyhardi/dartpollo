import 'package:test/test.dart';
import 'package:gql/ast.dart';
import 'package:dartpollo/visitor/base_visitor.dart';

// Test implementation of BaseVisitor for testing purposes
class TestVisitor extends BaseVisitor<List<String>> {
  final List<String> _results = [];

  @override
  List<String> get result => List.unmodifiable(_results);

  @override
  void reset() {
    _results.clear();
  }

  @override
  bool canHandle(Node node) {
    return node is DocumentNode || node is FieldNode;
  }

  @override
  void visitFieldNode(FieldNode node) {
    _results.add(node.name.value);
    super.visitFieldNode(node);
  }
}

void main() {
  group('BaseVisitor', () {
    late TestVisitor visitor;

    setUp(() {
      visitor = TestVisitor();
    });

    test('should implement result getter', () {
      expect(visitor.result, isA<List<String>>());
      expect(visitor.result, isEmpty);
    });

    test('should implement reset functionality', () {
      // Add some data
      visitor.visitFieldNode(FieldNode(name: NameNode(value: 'test')));
      expect(visitor.result, isNotEmpty);

      // Reset should clear the data
      visitor.reset();
      expect(visitor.result, isEmpty);
    });

    test('should implement canHandle method', () {
      final documentNode = DocumentNode(definitions: []);
      final fieldNode = FieldNode(name: NameNode(value: 'test'));
      final nameNode = NameNode(value: 'test');

      expect(visitor.canHandle(documentNode), isTrue);
      expect(visitor.canHandle(fieldNode), isTrue);
      expect(visitor.canHandle(nameNode), isFalse);
    });

    test('should process nodes when visiting', () {
      final fieldNode = FieldNode(name: NameNode(value: 'testField'));

      visitor.visitFieldNode(fieldNode);

      expect(visitor.result, contains('testField'));
    });

    test('should maintain immutable result', () {
      visitor.visitFieldNode(FieldNode(name: NameNode(value: 'test')));

      final result1 = visitor.result;
      final result2 = visitor.result;

      expect(identical(result1, result2), isFalse);
      expect(result1, equals(result2));
    });
  });
}
