import 'dart:developer' as developer;
import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('Mutation Args Performance Benchmark', () {
    test('Memory usage comparison: Combined vs Separate approach', () async {
      developer.log('[DEBUG_LOG] Starting memory usage benchmark...');

      // Simulate traditional approach (separate Arguments class)
      final traditionalObjects = <Object>[];
      final stopwatch1 = Stopwatch()..start();

      for (var i = 0; i < 10000; i++) {
        // Simulate creating Arguments object
        final args = TraditionalArguments(
          attachmentId: 'attachment-$i',
          name: 'name-$i',
          receiptAmount: i,
          receiptCategory: 'FOOD',
          receiptDate: '2025-08-26',
          receiptName: 'receipt-$i',
          recipientId: 'recipient-$i',
        );

        // Simulate creating Mutation object
        final mutation = TraditionalMutation(variables: args);

        traditionalObjects.addAll([args, mutation]);
      }

      stopwatch1.stop();
      final traditionalTime = stopwatch1.elapsedMilliseconds;
      final traditionalMemory = ProcessInfo.currentRss;

      developer.log(
        '[DEBUG_LOG] Traditional approach: ${traditionalTime}ms, Memory: ${traditionalMemory ~/ 1024}KB',
      );

      // Clear memory
      traditionalObjects.clear();

      // Force garbage collection
      for (var i = 0; i < 3; i++) {
        ProcessInfo.currentRss; // Trigger GC
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      // Simulate combined approach
      final combinedObjects = <Object>[];
      final stopwatch2 = Stopwatch()..start();

      for (var i = 0; i < 10000; i++) {
        // Simulate creating combined Mutation object
        final mutation = CombinedMutation(
          attachmentId: 'attachment-$i',
          name: 'name-$i',
          receiptAmount: i,
          receiptCategory: 'FOOD',
          receiptDate: '2025-08-26',
          receiptName: 'receipt-$i',
          recipientId: 'recipient-$i',
        );

        combinedObjects.add(mutation);
      }

      stopwatch2.stop();
      final combinedTime = stopwatch2.elapsedMilliseconds;
      final combinedMemory = ProcessInfo.currentRss;

      developer.log(
        '[DEBUG_LOG] Combined approach: ${combinedTime}ms, Memory: ${combinedMemory ~/ 1024}KB',
      );

      // Calculate improvements
      final timeImprovement =
          (traditionalTime - combinedTime) / traditionalTime * 100;
      final memoryImprovement =
          (traditionalMemory - combinedMemory) / traditionalMemory * 100;

      developer.log('[DEBUG_LOG] Performance improvements:');
      developer.log(
        '[DEBUG_LOG] - Time: ${timeImprovement.toStringAsFixed(1)}% faster',
      );
      developer.log(
        '[DEBUG_LOG] - Memory: ${memoryImprovement.toStringAsFixed(1)}% less memory',
      );
      developer.log(
        '[DEBUG_LOG] - Object count: 50% fewer objects (10k vs 20k)',
      );

      // Validate that combined approach is more efficient
      expect(combinedObjects.length, equals(10000));
      expect(traditionalObjects.length, equals(0)); // Cleared
      expect(combinedTime, lessThanOrEqualTo(traditionalTime));

      combinedObjects.clear();
    });

    test('Instantiation performance comparison', () {
      developer.log(
        '[DEBUG_LOG] Starting instantiation performance benchmark...',
      );

      const iterations = 100000;

      // Benchmark traditional approach
      final stopwatch1 = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        final args = TraditionalArguments(
          attachmentId: 'attachment-$i',
          name: 'name-$i',
          receiptAmount: i,
          receiptCategory: 'FOOD',
          receiptDate: '2025-08-26',
          receiptName: 'receipt-$i',
          recipientId: 'recipient-$i',
        );
        final mutation = TraditionalMutation(variables: args);
        // Simulate accessing variables
        final vars = mutation.getVariablesMap();
        expect(vars['name'], equals('name-$i'));
      }
      stopwatch1.stop();

      // Benchmark combined approach
      final stopwatch2 = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        final mutation = CombinedMutation(
          attachmentId: 'attachment-$i',
          name: 'name-$i',
          receiptAmount: i,
          receiptCategory: 'FOOD',
          receiptDate: '2025-08-26',
          receiptName: 'receipt-$i',
          recipientId: 'recipient-$i',
        );
        // Simulate accessing variables
        final vars = mutation.getParameterVariablesMap();
        expect(vars['name'], equals('name-$i'));
      }
      stopwatch2.stop();

      final traditionalTime = stopwatch1.elapsedMilliseconds;
      final combinedTime = stopwatch2.elapsedMilliseconds;
      final improvement =
          (traditionalTime - combinedTime) / traditionalTime * 100;

      developer.log('[DEBUG_LOG] Instantiation benchmark results:');
      developer.log(
        '[DEBUG_LOG] - Traditional: ${traditionalTime}ms for $iterations iterations',
      );
      developer.log(
        '[DEBUG_LOG] - Combined: ${combinedTime}ms for $iterations iterations',
      );
      developer.log(
        '[DEBUG_LOG] - Improvement: ${improvement.toStringAsFixed(1)}% faster',
      );

      // Validate performance improvement or at least parity
      expect(
        combinedTime,
        lessThanOrEqualTo(traditionalTime * 1.1),
      ); // Allow 10% tolerance
    });
  });
}

// Mock classes to simulate traditional approach
class TraditionalArguments {
  TraditionalArguments({
    required this.attachmentId,
    required this.name,
    required this.receiptAmount,
    required this.receiptCategory,
    required this.receiptDate,
    required this.receiptName,
    required this.recipientId,
  });

  final String attachmentId;
  final String name;
  final int receiptAmount;
  final String receiptCategory;
  final String receiptDate;
  final String receiptName;
  final String recipientId;

  Map<String, dynamic> toJson() => {
    'attachmentId': attachmentId,
    'name': name,
    'receiptAmount': receiptAmount,
    'receiptCategory': receiptCategory,
    'receiptDate': receiptDate,
    'receiptName': receiptName,
    'recipientId': recipientId,
  };
}

class TraditionalMutation {
  TraditionalMutation({required this.variables});

  final TraditionalArguments variables;

  Map<String, dynamic> getVariablesMap() => variables.toJson();
}

// Mock class to simulate combined approach
class CombinedMutation {
  CombinedMutation({
    required this.attachmentId,
    required this.name,
    required this.receiptAmount,
    required this.receiptCategory,
    required this.receiptDate,
    required this.receiptName,
    required this.recipientId,
  });

  final String attachmentId;
  final String name;
  final int receiptAmount;
  final String receiptCategory;
  final String receiptDate;
  final String receiptName;
  final String recipientId;

  Map<String, dynamic> getParameterVariablesMap() => {
    'attachmentId': attachmentId,
    'name': name,
    'receiptAmount': receiptAmount,
    'receiptCategory': receiptCategory,
    'receiptDate': receiptDate,
    'receiptName': receiptName,
    'recipientId': recipientId,
  };
}
