/// XML position printer.
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart' as args;
import 'package:petitparser/petitparser.dart';
import 'package:xml/xml_events.dart';

final args.ArgParser argumentParser = args.ArgParser()
  ..addOption(
    'position',
    abbr: 'p',
    help: 'Print character index instead of line:column.',
    allowed: ['start', 'stop', 'start-stop', 'line', 'column', 'line:column'],
    defaultsTo: 'line:column',
  )
  ..addOption(
    'limit',
    abbr: 'l',
    help: 'Limit output to the specified number of characters.',
    defaultsTo: '60',
  );

void printUsage() {
  stdout.writeln('Usage: xml_pos [options] {files}');
  stdout.writeln();
  stdout.writeln(argumentParser.usage);
  exit(1);
}

void main(List<String> arguments) {
  final files = <File>[];
  final results = argumentParser.parse(arguments);
  final position = results['position'];
  final limit = int.parse(results['limit']);

  for (final argument in results.rest) {
    final file = File(argument);
    if (file.existsSync()) {
      files.add(file);
    } else {
      stderr.writeln('File not found: $file');
      exit(2);
    }
  }
  if (files.isEmpty) {
    printUsage();
  }

  for (final file in files) {
    final events = parseEvents(
      file.readAsStringSync(),
      withBuffer: true,
      withLocation: true,
    ).where((event) => event is! XmlTextEvent || event.text.trim().isNotEmpty);
    for (final event in events) {
      final positionString = outputPosition(position, event).padLeft(10);
      final tokenString = outputString(limit, event);
      stdout.writeln('$positionString: $tokenString');
    }
  }
}

String outputPosition(String position, XmlEvent event) {
  switch (position) {
    case 'start':
      return '${event.start}';
    case 'stop':
      return '${event.stop}';
    case 'start-stop':
      return '${event.start}-${event.stop}';
  }
  final lineAndColumn = Token.lineAndColumnOf(event.buffer!, event.start!);
  switch (position) {
    case 'line':
      return '${lineAndColumn[0]}';
    case 'column':
      return '${lineAndColumn[1]}';
    default:
      return '${lineAndColumn[0]}:${lineAndColumn[1]}';
  }
}

String outputString(int limit, XmlEvent event) {
  final input = event.buffer!.substring(event.start!, event.stop!);
  final index = input.indexOf('\n');
  final length = min(limit, index < 0 ? input.length : index);
  final output = input.substring(0, length);
  return output.length < input.length ? '$output...' : output;
}
