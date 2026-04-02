import 'package:dartpollo_generator/visitor/base_visitor.dart';
import 'package:gql/ast.dart';
import 'package:test/test.dart';

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
      visitor.visitFieldNode(const FieldNode(name: NameNode(value: 'test')));
      expect(visitor.result, isNotEmpty);

      // Reset should clear the data
      visitor.reset();
      expect(visitor.result, isEmpty);
    });

    test('should implement canHandle method', () {
      const documentNode = DocumentNode();
      const fieldNode = FieldNode(name: NameNode(value: 'test'));
      const nameNode = NameNode(value: 'test');

      expect(visitor.canHandle(documentNode), isTrue);
      expect(visitor.canHandle(fieldNode), isTrue);
      expect(visitor.canHandle(nameNode), isFalse);
    });

    test('should process nodes when visiting', () {
      const fieldNode = FieldNode(name: NameNode(value: 'testField'));

      visitor.visitFieldNode(fieldNode);

      expect(visitor.result, contains('testField'));
    });

    test('should maintain immutable result', () {
      visitor.visitFieldNode(const FieldNode(name: NameNode(value: 'test')));

      final result1 = visitor.result;
      final result2 = visitor.result;

      expect(identical(result1, result2), isFalse);
      expect(result1, equals(result2));
    });
  });
}
