/// XML grep.
import 'dart:io';

import 'package:args/args.dart' as args;
import 'package:xml/xml.dart';

final args.ArgParser argumentParser = args.ArgParser()
  ..addOption(
    'tag',
    abbr: 't',
    help: 'Filter by tag name.',
    defaultsTo: '*',
  )
  ..addOption(
    'namespace',
    abbr: 'n',
    help: 'Filter by namespace.',
    defaultsTo: '*',
  )
  ..addFlag(
    'pretty',
    abbr: 'p',
    help: 'Pretty print matching results.',
  );

void printUsage() {
  stdout.writeln('Usage: xml_grep [options] {files}');
  stdout.writeln();
  stdout.writeln(argumentParser.usage);
  exit(1);
}

void main(List<String> arguments) {
  final files = <File>[];
  final results = argumentParser.parse(arguments);
  final String tag = results['tag'];
  final String namespace = results['namespace'];

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
    final document = XmlDocument.parse(file.readAsStringSync());
    final elements = document.findAllElements(tag, namespace: namespace);
    for (final element in elements) {
      stdout.writeln(element.toXmlString(pretty: results['pretty']));
    }
  }
}
