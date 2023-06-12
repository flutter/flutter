import 'dart:typed_data';

String? _argumentToStringTruncate(Object? argument) {
  if (argument == null) {
    return null;
  }
  var text = argument.toString();
  if (text.length > 50) {
    return '${text.substring(0, 50)}...';
  }
  return text;
}

/// Convert an sql argument to a printable string, truncating if necessary
String? argumentToString(Object? argument) {
  if (argument is Uint8List) {
    return 'Blob(${argument.length})';
  }
  return _argumentToStringTruncate(argument);
}

/// Convert sql arguments to a printable string, truncating if necessary
String argumentsToString(List<Object?> arguments) =>
    '[${arguments.map((e) => argumentToString(e)).join(', ')}]';

/// Sql command and arguments formatted for logs
String sqlArgumentsToString(String sql, List<Object?>? arguments) {
  return '$sql${(arguments?.isNotEmpty ?? false) ? ' ${argumentsToString(arguments!)}' : ''}';
}
