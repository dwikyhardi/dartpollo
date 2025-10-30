import 'package:dartpollo/generator/data/class_property.dart';
import 'package:dartpollo/generator/data/definition.dart';
import 'package:dartpollo/generator/data_printer.dart';
import 'package:dartpollo/generator/helpers.dart';

/// Define a query/mutation input parameter.
class QueryInput extends Definition with DataPrinter {
  /// Instantiate an input parameter.
  QueryInput({
    required this.type,
    this.annotations = const [],
    required this.name,
  }) : assert(hasValue(type) && hasValue(name)),
       super(name: name);
  @override
  final QueryInputName name;

  /// The input type.
  final TypeName type;

  /// Some other custom annotation.
  final List<String> annotations;

  @override
  Map<String, Object?> get namedProps => {
    'type': type,
    'name': name,
    'annotations': annotations,
  };
}

///
class QueryInputName extends Name {
  ///
  const QueryInputName({required super.name});

  @override
  Map<String, Object?> get namedProps => {
    'name': name,
  };
}
