import 'package:dartpollo_generator/generator/data/definition.dart';
import 'package:dartpollo_generator/generator/data_printer.dart';
import 'package:recase/recase.dart';

/// Enum value
class EnumValueDefinition extends Definition with DataPrinter {
  /// Instantiate an enum value
  EnumValueDefinition({
    required this.name,
    this.annotations = const [],
  }) : super(name: name);
  @override
  final EnumValueName name;

  /// Some other custom annotation.
  final List<String> annotations;

  @override
  Map<String, Object> get namedProps => {
    'name': name,
    'annotations': annotations,
  };
}

/// Enum value name
class EnumValueName extends Name with DataPrinter {
  /// Instantiate a enum value name definition.
  EnumValueName({required super.name});

  @override
  Map<String, Object?> get namedProps => {
    'name': name,
  };

  @override
  String normalize(String name) {
    return ReCase(super.normalize(name)).camelCase;
  }
}
