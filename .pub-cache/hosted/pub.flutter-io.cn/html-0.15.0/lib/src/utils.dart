import 'constants.dart';

class Pair<F, S> {
  final F first;
  final S second;

  const Pair(this.first, this.second);

  @override
  int get hashCode => 37 * first.hashCode + second.hashCode;

  @override
  bool operator ==(Object other) =>
      other is Pair && other.first == first && other.second == second;
}

bool startsWithAny(String str, List<String> prefixes) =>
    prefixes.any(str.startsWith);

// Like the python [:] operator.
List<T> slice<T>(List<T> list, int start, [int? end]) {
  end ??= list.length;
  if (end < 0) end += list.length;

  // Ensure the indexes are in bounds.
  if (end < start) end = start;
  if (end > list.length) end = list.length;
  return list.sublist(start, end);
}

bool allWhitespace(String str) {
  for (var i = 0; i < str.length; i++) {
    if (!isWhitespaceCC(str.codeUnitAt(i))) return false;
  }
  return true;
}

String padWithZeros(String str, int size) {
  if (str.length == size) return str;
  final result = StringBuffer();
  size -= str.length;
  for (var i = 0; i < size; i++) {
    result.write('0');
  }
  result.write(str);
  return result.toString();
}

// TODO(jmesserly): this implementation is pretty wrong, but I need something
// quick until dartbug.com/1694 is fixed.
/// Format a string like Python's % string format operator. Right now this only
/// supports a [data] dictionary used with %s or %08x. Those were the only
/// things needed for [errorMessages].
String formatStr(String format, Map? data) {
  if (data == null) return format;
  data.forEach((key, value) {
    final result = StringBuffer();
    final search = '%($key)';
    int last = 0, match;
    while ((match = format.indexOf(search, last)) >= 0) {
      result.write(format.substring(last, match));
      match += search.length;

      var digits = match;
      while (isDigit(format[digits])) {
        digits++;
      }
      var numberSize = 0;
      if (digits > match) {
        numberSize = int.parse(format.substring(match, digits));
        match = digits;
      }

      switch (format[match]) {
        case 's':
          result.write(value);
          break;
        case 'd':
          final number = value.toString();
          result.write(padWithZeros(number, numberSize));
          break;
        case 'x':
          final number = (value as int).toRadixString(16);
          result.write(padWithZeros(number, numberSize));
          break;
        default:
          throw UnsupportedError('formatStr does not support format '
              'character ${format[match]}');
      }

      last = match + 1;
    }

    result.write(format.substring(last, format.length));
    format = result.toString();
  });

  return format;
}
