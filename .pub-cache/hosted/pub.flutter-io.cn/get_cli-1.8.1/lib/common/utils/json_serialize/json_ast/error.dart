import 'dart:core';
import 'dart:math';

class Settings {
  final int extraLines;
  final int tabSize;
  final bool loc;
  final String? source;

  Settings(
      {this.extraLines = 2, this.tabSize = 4, this.loc = true, this.source});
}

String repeatString(String str, int n) {
  if (n == 0) {
    return '';
  } else if (n == 1) {
    return str;
  }
  final strBuf = StringBuffer();
  for (var i = 0; i < n; i++) {
    strBuf.write(str);
  }
  return strBuf.toString();
}

String printLine(
    String line, int position, int maxNumLength, Settings settings) {
  final n = position.toString();
  final formattedNum = n.padLeft(maxNumLength);
  final tabReplacement = repeatString(' ', settings.tabSize);
  return '$formattedNum | ${line.replaceAll('\t', tabReplacement)}';
}

String printLines(List<String> lines, int start, int end, int maxNumLength,
    Settings settings) {
  return lines
      .sublist(start, end)
      .asMap()
      .map((i, line) =>
          MapEntry(i, printLine(line, start + i + 1, maxNumLength, settings)))
      .values
      .join('\n');
}

String codeErrorFragment(String input, int linePos, int columnPos,
    [Settings? settings]) {
  final splitter = RegExp(r'\r\n?|\n|\f');
  final lines = input.split(splitter);
  settings = settings ?? Settings();
  final startLinePos = max(1, linePos - settings.extraLines) - 1;
  final endLinePos = min(linePos + settings.extraLines, lines.length);
  final maxNumLength = endLinePos.toString().length;
  final prevLines =
      printLines(lines, startLinePos, linePos, maxNumLength, settings);
  final targetLineBeforeCursor = printLine(
      lines[linePos - 1].substring(0, columnPos - 1),
      linePos,
      maxNumLength,
      settings);
  final cursorLine = '${repeatString(' ', targetLineBeforeCursor.length)}^';
  final nextLines =
      printLines(lines, linePos, endLinePos, maxNumLength, settings);

  return [prevLines, cursorLine, nextLines].where((c) => c != '0').join('\n');
}

class JSONASTException implements Exception {
  final String rawMessage;
  final String? input;
  final String? source;
  final int? line;
  final int? column;
  String? _message;

  JSONASTException(
      this.rawMessage, this.input, this.source, this.line, this.column) {
    if (input != null) {
      _message = line != 0
          ? '$rawMessage\n${codeErrorFragment(input!, line!, column!)}'
          : rawMessage;
    } else {
      _message = rawMessage;
    }
  }

  String? get message {
    return _message;
  }
}
