import 'package:logging/logging.dart' as logging;

class Tag {
  static const getArgsCompletions = Tag._('getArgsCompletions');

  final String name;

  const Tag._(this.name);

  static int get longestTagLength => getArgsCompletions.name.length;
}

void log(Object o, [Tag? tag]) {
  String safe;

  try {
    safe = o.toString();
  } catch (e, stack) {
    safe = 'Error converting provided object $o into '
        'String\nException:\t$e\Stack:\t$stack';
  }

  final startArgs = ['completion'];
  if (tag != null) {
    startArgs.add(tag.name);
  }

  final loggerName = startArgs.join('.');

  logging.Logger(loggerName).info(safe);
}

String helpfulToString(Object input) {
  if (input is Iterable) {
    final items = input.cast<Object>().map(helpfulToString).toList();

    if (items.isEmpty) {
      return '-empty-';
    } else {
      return "[${items.join(', ')}]";
    }
  }

  return Error.safeToString(input);
}
