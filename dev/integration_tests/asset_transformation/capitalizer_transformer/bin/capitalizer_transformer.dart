import 'dart:io';

import 'package:args/args.dart';

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('input')
    ..addOption('output');

  final parsedArgs = parser.parse(args);

  final String inputFilePath = parsedArgs['input'] as String;
  final String outputFilePath = parsedArgs['output'] as String;

  final String input = File(inputFilePath).readAsStringSync();
  File(outputFilePath)
    ..createSync(recursive: true)
    ..writeAsStringSync(input.toUpperCase());
}
