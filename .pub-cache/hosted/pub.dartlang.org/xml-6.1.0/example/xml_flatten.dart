/// XML flatten.
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart' as args;
import 'package:xml/xml_events.dart';

final args.ArgParser argumentParser = args.ArgParser()
  ..addFlag(
    'normalize',
    abbr: 'n',
    help: 'Normalize the output stream.',
  )
  ..addFlag(
    'text',
    abbr: 't',
    help: 'Only display text events.',
  );

void printUsage() {
  stdout.writeln('Usage: xml_flatten [options] {files}');
  stdout.writeln();
  stdout.writeln(argumentParser.usage);
  exit(1);
}

Future<void> main(List<String> arguments) async {
  final files = <File>[];
  final results = argumentParser.parse(arguments);
  final normalize = results['normalize'];
  final text = results['text'];

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
    var stream = file.openRead().transform(utf8.decoder).toXmlEvents();
    if (normalize) {
      stream = stream.normalizeEvents();
    }
    var flatStream = stream.flatten();
    if (text) {
      flatStream = flatStream.where((event) => event is XmlTextEvent);
    }
    await flatStream.forEach(stdout.writeln);
  }
}
