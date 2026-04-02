import 'dart:async';
import 'dart:convert';
import 'dart:developer' as $dev;
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;

const String introspectionQuery = '''
  query IntrospectionQuery {
    __schema {
      queryType { name }
      mutationType { name }
      subscriptionType { name }
      types {
        ...FullType
      }
      directives {
        name
        description
        locations
        args {
          ...InputValue
        }
      }
    }
  }

  fragment FullType on __Type {
    kind
    name
    description
    fields(includeDeprecated: true) {
      name
      description
      args {
        ...InputValue
      }
      type {
        ...TypeRef
      }
      isDeprecated
      deprecationReason
    }
    inputFields {
      ...InputValue
    }
    interfaces {
      ...TypeRef
    }
    enumValues(includeDeprecated: true) {
      name
      description
      isDeprecated
      deprecationReason
    }
    possibleTypes {
      ...TypeRef
    }
  }

  fragment InputValue on __InputValue {
    name
    description
    type { ...TypeRef }
    defaultValue
  }

  fragment TypeRef on __Type {
    kind
    name
    ofType {
      kind
      name
      ofType {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
              ofType {
                kind
                name
                ofType {
                  kind
                  name
                }
              }
            }
          }
        }
      }
    }
  }
''';

Future<String> fetchGraphQLSchemaStringFromURL(
  String graphqlEndpoint, {
  http.Client? client,
  Map<String, String>? headers,
}) async {
  final httpClient = client ?? http.Client();

  final requestHeaders = <String, String>{
    'Content-Type': 'application/json',
    if (headers != null) ...headers,
  };

  final response = await httpClient.post(
    Uri.parse(graphqlEndpoint),
    headers: requestHeaders,
    body:
        '{"operationName":"IntrospectionQuery","query":${_jsonEncode(introspectionQuery)}}',
  );

  return response.body;
}

String _jsonEncode(String value) {
  return '"${value.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n')}"';
}

/// Converts a JSON introspection query result to GraphQL SDL (Schema Definition Language).
String introspectionJsonToSdl(String jsonString) {
  final decoded = json.decode(jsonString) as Map<String, dynamic>;

  final Map<String, dynamic> schema;
  if (decoded.containsKey('data')) {
    schema =
        (decoded['data'] as Map<String, dynamic>)['__schema']
            as Map<String, dynamic>;
  } else if (decoded.containsKey('__schema')) {
    schema = decoded['__schema'] as Map<String, dynamic>;
  } else {
    throw const FormatException(
      'Invalid introspection result: missing "data.__schema" or "__schema" key.',
    );
  }

  final types = (schema['types'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  final directives =
      (schema['directives'] as List?)?.cast<Map<String, dynamic>>() ?? [];

  final queryTypeName =
      (schema['queryType'] as Map<String, dynamic>?)?['name'] as String?;
  final mutationTypeName =
      (schema['mutationType'] as Map<String, dynamic>?)?['name'] as String?;
  final subscriptionTypeName =
      (schema['subscriptionType'] as Map<String, dynamic>?)?['name'] as String?;

  // Built-in types and directives to skip
  const builtInTypes = {
    'String',
    'Int',
    'Float',
    'Boolean',
    'ID',
    '__Schema',
    '__Type',
    '__TypeKind',
    '__Field',
    '__InputValue',
    '__EnumValue',
    '__Directive',
    '__DirectiveLocation',
  };
  const builtInDirectives = {'skip', 'include', 'deprecated', 'specifiedBy'};

  final buffer = StringBuffer();

  // Schema definition (only if non-default root type names)
  final needsSchemaBlock =
      (queryTypeName != null && queryTypeName != 'Query') ||
      (mutationTypeName != null && mutationTypeName != 'Mutation') ||
      (subscriptionTypeName != null && subscriptionTypeName != 'Subscription');

  if (needsSchemaBlock) {
    buffer.writeln('schema {');
    if (queryTypeName != null) buffer.writeln('  query: $queryTypeName');
    if (mutationTypeName != null) {
      buffer.writeln('  mutation: $mutationTypeName');
    }
    if (subscriptionTypeName != null) {
      buffer.writeln('  subscription: $subscriptionTypeName');
    }
    buffer
      ..writeln('}')
      ..writeln();
  }

  // Custom directives
  for (final directive in directives) {
    final name = directive['name'] as String;
    if (builtInDirectives.contains(name)) continue;

    final description = directive['description'] as String?;
    if (description != null && description.isNotEmpty) {
      _writeDescription(buffer, description, '');
    }

    buffer.write('directive @$name');

    final args =
        (directive['args'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (args.isNotEmpty) {
      _writeArguments(buffer, args);
    }

    final locations = (directive['locations'] as List?)?.cast<String>() ?? [];
    if (locations.isNotEmpty) {
      buffer.write(' on ${locations.join(' | ')}');
    }

    buffer
      ..writeln()
      ..writeln();
  }

  // Types
  for (final type in types) {
    final name = type['name'] as String;
    final kind = type['kind'] as String;

    if (builtInTypes.contains(name)) continue;

    final description = type['description'] as String?;
    if (description != null && description.isNotEmpty) {
      _writeDescription(buffer, description, '');
    }

    switch (kind) {
      case 'SCALAR':
        buffer.writeln('scalar $name');
      case 'OBJECT':
        buffer.write('type $name');
        final interfaces =
            (type['interfaces'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        if (interfaces.isNotEmpty) {
          final names = interfaces.map(_typeRefToString).toList();
          buffer.write(' implements ${names.join(' & ')}');
        }
        buffer.writeln(' {');
        _writeFields(buffer, type['fields'] as List?);
        buffer.writeln('}');
      case 'INPUT_OBJECT':
        buffer.writeln('input $name {');
        _writeInputFields(buffer, type['inputFields'] as List?);
        buffer.writeln('}');
      case 'ENUM':
        buffer.writeln('enum $name {');
        final enumValues =
            (type['enumValues'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        for (final ev in enumValues) {
          final evDesc = ev['description'] as String?;
          if (evDesc != null && evDesc.isNotEmpty) {
            _writeDescription(buffer, evDesc, '  ');
          }
          buffer.write('  ${ev['name']}');
          final deprecation = _deprecationDirective(ev);
          if (deprecation != null) buffer.write(' $deprecation');
          buffer.writeln();
        }
        buffer.writeln('}');
      case 'INTERFACE':
        buffer.write('interface $name');
        final interfaces =
            (type['interfaces'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        if (interfaces.isNotEmpty) {
          final names = interfaces.map(_typeRefToString).toList();
          buffer.write(' implements ${names.join(' & ')}');
        }
        buffer.writeln(' {');
        _writeFields(buffer, type['fields'] as List?);
        buffer.writeln('}');
      case 'UNION':
        final possibleTypes =
            (type['possibleTypes'] as List?)?.cast<Map<String, dynamic>>() ??
            [];
        final names = possibleTypes.map(_typeRefToString).toList();
        buffer.writeln('union $name = ${names.join(' | ')}');
    }

    buffer.writeln();
  }

  return '${buffer.toString().trimRight()}\n';
}

void _writeDescription(StringBuffer buffer, String description, String indent) {
  if (description.contains('\n')) {
    buffer.writeln('$indent"""');
    for (final line in description.split('\n')) {
      buffer.writeln('$indent$line');
    }
    buffer.writeln('$indent"""');
  } else {
    buffer.writeln('$indent"${_escapeString(description)}"');
  }
}

String _escapeString(String value) {
  return value
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n');
}

void _writeFields(StringBuffer buffer, List<dynamic>? fields) {
  if (fields == null) return;
  for (final field in fields.cast<Map<String, dynamic>>()) {
    final desc = field['description'] as String?;
    if (desc != null && desc.isNotEmpty) {
      _writeDescription(buffer, desc, '  ');
    }

    buffer.write('  ${field['name']}');

    final args = (field['args'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (args.isNotEmpty) {
      _writeArguments(buffer, args);
    }

    buffer.write(
      ': ${_typeRefToString(field['type'] as Map<String, dynamic>)}',
    );

    final deprecation = _deprecationDirective(field);
    if (deprecation != null) buffer.write(' $deprecation');

    buffer.writeln();
  }
}

void _writeInputFields(StringBuffer buffer, List<dynamic>? fields) {
  if (fields == null) return;
  for (final field in fields.cast<Map<String, dynamic>>()) {
    final desc = field['description'] as String?;
    if (desc != null && desc.isNotEmpty) {
      _writeDescription(buffer, desc, '  ');
    }

    buffer.write(
      '  ${field['name']}: ${_typeRefToString(field['type'] as Map<String, dynamic>)}',
    );

    final defaultValue = field['defaultValue'] as String?;
    if (defaultValue != null) {
      buffer.write(' = $defaultValue');
    }

    buffer.writeln();
  }
}

void _writeArguments(StringBuffer buffer, List<Map<String, dynamic>> args) {
  if (args.length == 1) {
    final arg = args.first;
    buffer
      ..write('(')
      ..write(
        '${arg['name']}: ${_typeRefToString(arg['type'] as Map<String, dynamic>)}',
      );
    final defaultValue = arg['defaultValue'] as String?;
    if (defaultValue != null) buffer.write(' = $defaultValue');
    buffer.write(')');
  } else {
    buffer.writeln('(');
    for (final arg in args) {
      final argDesc = arg['description'] as String?;
      if (argDesc != null && argDesc.isNotEmpty) {
        _writeDescription(buffer, argDesc, '    ');
      }
      buffer.write(
        '    ${arg['name']}: ${_typeRefToString(arg['type'] as Map<String, dynamic>)}',
      );
      final defaultValue = arg['defaultValue'] as String?;
      if (defaultValue != null) buffer.write(' = $defaultValue');
      buffer.writeln();
    }
    buffer.write('  )');
  }
}

String? _deprecationDirective(Map<String, dynamic> node) {
  final isDeprecated = node['isDeprecated'] as bool? ?? false;
  if (!isDeprecated) return null;
  final reason = node['deprecationReason'] as String?;
  if (reason == null || reason.isEmpty || reason == 'No longer supported') {
    return '@deprecated';
  }
  return '@deprecated(reason: "${_escapeString(reason)}")';
}

String _typeRefToString(Map<String, dynamic> typeRef) {
  final kind = typeRef['kind'] as String;
  final name = typeRef['name'] as String?;
  final ofType = typeRef['ofType'] as Map<String, dynamic>?;

  switch (kind) {
    case 'NON_NULL':
      if (ofType == null) return '';
      return '${_typeRefToString(ofType)}!';
    case 'LIST':
      if (ofType == null) return '';
      return '[${_typeRefToString(ofType)}]';
    default:
      return name ?? '';
  }
}

void main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', help: 'Show this help', negatable: false)
    ..addOption(
      'endpoint',
      abbr: 'e',
      help: 'Endpoint to hit to get the schema',
    )
    ..addOption('output', abbr: 'o', help: 'File to output the schema to')
    ..addOption(
      'authorization',
      abbr: 'a',
      help: 'Authorization header value (e.g., "Bearer <token>")',
    )
    ..addMultiOption(
      'header',
      abbr: 'H',
      help: 'Additional headers in "Key: Value" format (can be repeated)',
    )
    ..addFlag(
      'json',
      help: 'Output raw JSON introspection result instead of SDL',
      negatable: false,
    );
  final results = parser.parse(args);

  if (results['help'] as bool || args.isEmpty) {
    return $dev.log(parser.usage);
  }

  final headers = <String, String>{};

  final authorization = results['authorization'] as String?;
  if (authorization != null) {
    headers['Authorization'] = authorization;
  }

  final rawHeaders = results['header'] as List<String>;
  for (final h in rawHeaders) {
    final index = h.indexOf(':');
    if (index > 0) {
      headers[h.substring(0, index).trim()] = h.substring(index + 1).trim();
    }
  }

  final jsonResponse = await fetchGraphQLSchemaStringFromURL(
    results['endpoint'] as String,
    headers: headers.isNotEmpty ? headers : null,
  );

  final outputJson = results['json'] as bool;
  final output = outputJson
      ? jsonResponse
      : introspectionJsonToSdl(jsonResponse);

  File(results['output'] as String).writeAsStringSync(output, flush: true);
}
