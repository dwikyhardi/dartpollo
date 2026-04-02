import 'package:dartpollo_generator/context/validation_context.dart';
import 'package:test/test.dart';

void main() {
  group('ValidationContext', () {
    late ValidationContext context;

    setUp(() {
      context = ValidationContext();
    });

    group('constructor', () {
      test('creates empty context', () {
        expect(context.errors, isEmpty);
        expect(context.warnings, isEmpty);
        expect(context.hasErrors, isFalse);
        expect(context.hasWarnings, isFalse);
        expect(context.isClean, isTrue);
      });
    });

    group('error management', () {
      test('addError adds error to context', () {
        const error = 'Test error';
        context.addError(error);

        expect(context.errors, contains(error));
        expect(context.hasErrors, isTrue);
        expect(context.errorCount, equals(1));
        expect(context.isClean, isFalse);
      });

      test('addErrors adds multiple errors', () {
        final errors = ['Error 1', 'Error 2', 'Error 3'];
        context.addErrors(errors);

        expect(context.errors, equals(errors));
        expect(context.hasErrors, isTrue);
        expect(context.errorCount, equals(3));
      });

      test('errors returns unmodifiable list', () {
        context.addError('Test error');
        final errorsList = context.errors;

        expect(() => errorsList.add('Another error'), throwsUnsupportedError);
      });

      test('clearErrors removes all errors', () {
        context
          ..addError('Error 1')
          ..addError('Error 2')
          ..addWarning('Warning 1')
          ..clearErrors();

        expect(context.errors, isEmpty);
        expect(context.hasErrors, isFalse);
        expect(context.warnings, isNotEmpty);
        expect(context.hasWarnings, isTrue);
      });
    });

    group('warning management', () {
      test('addWarning adds warning to context', () {
        const warning = 'Test warning';
        context.addWarning(warning);

        expect(context.warnings, contains(warning));
        expect(context.hasWarnings, isTrue);
        expect(context.warningCount, equals(1));
        expect(context.isClean, isFalse);
      });

      test('addWarnings adds multiple warnings', () {
        final warnings = ['Warning 1', 'Warning 2', 'Warning 3'];
        context.addWarnings(warnings);

        expect(context.warnings, equals(warnings));
        expect(context.hasWarnings, isTrue);
        expect(context.warningCount, equals(3));
      });

      test('warnings returns unmodifiable list', () {
        context.addWarning('Test warning');
        final warningsList = context.warnings;

        expect(
          () => warningsList.add('Another warning'),
          throwsUnsupportedError,
        );
      });

      test('clearWarnings removes all warnings', () {
        context
          ..addError('Error 1')
          ..addWarning('Warning 1')
          ..addWarning('Warning 2')
          ..clearWarnings();

        expect(context.warnings, isEmpty);
        expect(context.hasWarnings, isFalse);
        expect(context.errors, isNotEmpty);
        expect(context.hasErrors, isTrue);
      });
    });

    group('validation state', () {
      test('hasErrors returns true when errors exist', () {
        expect(context.hasErrors, isFalse);

        context.addError('Test error');
        expect(context.hasErrors, isTrue);
      });

      test('hasWarnings returns true when warnings exist', () {
        expect(context.hasWarnings, isFalse);

        context.addWarning('Test warning');
        expect(context.hasWarnings, isTrue);
      });

      test('isClean returns false when errors or warnings exist', () {
        expect(context.isClean, isTrue);

        context.addError('Test error');
        expect(context.isClean, isFalse);

        context.clearErrors();
        expect(context.isClean, isTrue);

        context.addWarning('Test warning');
        expect(context.isClean, isFalse);
      });

      test('errorCount returns correct count', () {
        expect(context.errorCount, equals(0));

        context.addError('Error 1');
        expect(context.errorCount, equals(1));

        context.addError('Error 2');
        expect(context.errorCount, equals(2));
      });

      test('warningCount returns correct count', () {
        expect(context.warningCount, equals(0));

        context.addWarning('Warning 1');
        expect(context.warningCount, equals(1));

        context.addWarning('Warning 2');
        expect(context.warningCount, equals(2));
      });
    });

    group('error throwing', () {
      test('throwIfErrors does nothing when no errors', () {
        context.addWarning('Test warning');
        expect(() => context.throwIfErrors(), returnsNormally);
      });

      test('throwIfErrors throws ValidationException when errors exist', () {
        context.addError('Test error');

        expect(
          () => context.throwIfErrors(),
          throwsA(
            isA<ValidationException>()
                .having(
                  (e) => e.message,
                  'message',
                  contains('Validation failed with 1 errors'),
                )
                .having((e) => e.errors, 'errors', contains('Test error')),
          ),
        );
      });

      test('throwIfErrors includes all errors in exception', () {
        context
          ..addError('Error 1')
          ..addError('Error 2');

        expect(
          () => context.throwIfErrors(),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.errors,
              'errors',
              equals(['Error 1', 'Error 2']),
            ),
          ),
        );
      });
    });

    group('clear operations', () {
      test('clear removes all errors and warnings', () {
        context
          ..addError('Error 1')
          ..addError('Error 2')
          ..addWarning('Warning 1')
          ..addWarning('Warning 2')
          ..clear();

        expect(context.errors, isEmpty);
        expect(context.warnings, isEmpty);
        expect(context.isClean, isTrue);
      });
    });

    group('merge operations', () {
      test('merge combines errors and warnings from another context', () {
        final otherContext = ValidationContext()
          ..addError('Other error')
          ..addWarning('Other warning');

        context
          ..addError('Original error')
          ..addWarning('Original warning')
          ..merge(otherContext);

        expect(context.errors, contains('Original error'));
        expect(context.errors, contains('Other error'));
        expect(context.warnings, contains('Original warning'));
        expect(context.warnings, contains('Other warning'));
        expect(context.errorCount, equals(2));
        expect(context.warningCount, equals(2));
      });

      test('merge with empty context does not change current context', () {
        final emptyContext = ValidationContext();
        context
          ..addError('Original error')
          ..merge(emptyContext);

        expect(context.errorCount, equals(1));
        expect(context.warningCount, equals(0));
      });
    });

    group('summary generation', () {
      test('getSummary returns clean message for empty context', () {
        final summary = context.getSummary();
        expect(summary, equals('No errors or warnings'));
      });

      test('getSummary returns formatted errors', () {
        context
          ..addError('Error 1')
          ..addError('Error 2');

        final summary = context.getSummary();
        expect(summary, contains('Errors (2):'));
        expect(summary, contains('1. Error 1'));
        expect(summary, contains('2. Error 2'));
      });

      test('getSummary returns formatted warnings', () {
        context
          ..addWarning('Warning 1')
          ..addWarning('Warning 2');

        final summary = context.getSummary();
        expect(summary, contains('Warnings (2):'));
        expect(summary, contains('1. Warning 1'));
        expect(summary, contains('2. Warning 2'));
      });

      test('getSummary returns both errors and warnings', () {
        context
          ..addError('Error 1')
          ..addWarning('Warning 1');

        final summary = context.getSummary();
        expect(summary, contains('Errors (1):'));
        expect(summary, contains('1. Error 1'));
        expect(summary, contains('Warnings (1):'));
        expect(summary, contains('1. Warning 1'));
      });
    });
  });

  group('ValidationException', () {
    test('creates exception with message and errors', () {
      const message = 'Test validation failed';
      final errors = ['Error 1', 'Error 2'];
      final exception = ValidationException(message, errors);

      expect(exception.message, equals(message));
      expect(exception.errors, equals(errors));
    });

    test('toString formats message and errors', () {
      const message = 'Validation failed';
      final errors = ['Error 1', 'Error 2'];
      final exception = ValidationException(message, errors);

      final string = exception.toString();
      expect(string, contains(message));
      expect(string, contains('- Error 1'));
      expect(string, contains('- Error 2'));
    });

    test('toString handles single error', () {
      const message = 'Single error';
      final errors = ['Only error'];
      final exception = ValidationException(message, errors);

      final string = exception.toString();
      expect(string, contains(message));
      expect(string, contains('- Only error'));
    });

    test('toString handles empty errors list', () {
      const message = 'No errors';
      final errors = <String>[];
      final exception = ValidationException(message, errors);

      final string = exception.toString();
      expect(string, equals('$message:\n'));
    });
  });
}
