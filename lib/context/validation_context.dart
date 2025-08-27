/// Context for collecting and managing validation errors and warnings
/// during the generation process.
class ValidationContext {
  final List<String> _errors;
  final List<String> _warnings;

  ValidationContext()
      : _errors = [],
        _warnings = [];

  /// Gets a read-only view of errors
  List<String> get errors => List.unmodifiable(_errors);

  /// Gets a read-only view of warnings
  List<String> get warnings => List.unmodifiable(_warnings);

  /// Adds an error to the validation context
  void addError(String error) {
    _errors.add(error);
  }

  /// Adds a warning to the validation context
  void addWarning(String warning) {
    _warnings.add(warning);
  }

  /// Returns true if there are any errors
  bool get hasErrors => _errors.isNotEmpty;

  /// Returns true if there are any warnings
  bool get hasWarnings => _warnings.isNotEmpty;

  /// Throws an exception if there are any errors
  void throwIfErrors() {
    if (hasErrors) {
      throw ValidationException(
          'Validation failed with ${_errors.length} errors', _errors);
    }
  }

  /// Clears all errors and warnings
  void clear() {
    _errors.clear();
    _warnings.clear();
  }

  /// Clears only errors
  void clearErrors() {
    _errors.clear();
  }

  /// Clears only warnings
  void clearWarnings() {
    _warnings.clear();
  }

  /// Returns the total number of errors
  int get errorCount => _errors.length;

  /// Returns the total number of warnings
  int get warningCount => _warnings.length;

  /// Returns true if the validation context is clean (no errors or warnings)
  bool get isClean => !hasErrors && !hasWarnings;

  /// Adds multiple errors at once
  void addErrors(Iterable<String> errors) {
    _errors.addAll(errors);
  }

  /// Adds multiple warnings at once
  void addWarnings(Iterable<String> warnings) {
    _warnings.addAll(warnings);
  }

  /// Merges another validation context into this one
  void merge(ValidationContext other) {
    _errors.addAll(other.errors);
    _warnings.addAll(other.warnings);
  }

  /// Creates a summary string of all errors and warnings
  String getSummary() {
    final buffer = StringBuffer();

    if (hasErrors) {
      buffer.writeln('Errors ($errorCount):');
      for (int i = 0; i < _errors.length; i++) {
        buffer.writeln('  ${i + 1}. ${_errors[i]}');
      }
    }

    if (hasWarnings) {
      if (hasErrors) buffer.writeln();
      buffer.writeln('Warnings ($warningCount):');
      for (int i = 0; i < _warnings.length; i++) {
        buffer.writeln('  ${i + 1}. ${_warnings[i]}');
      }
    }

    if (isClean) {
      buffer.write('No errors or warnings');
    }

    return buffer.toString().trim();
  }
}

/// Exception thrown when validation fails
class ValidationException implements Exception {
  final String message;
  final List<String> errors;

  ValidationException(this.message, this.errors);

  @override
  String toString() {
    final errorList = errors.map((e) => '  - $e').join('\n');
    return '$message:\n$errorList';
  }
}
