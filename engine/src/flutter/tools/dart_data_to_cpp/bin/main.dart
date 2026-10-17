// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:args/args.dart';
import 'package:dart_data_to_cpp/dart_data_to_cpp.dart';
import 'package:engine_repo_tools/engine_repo_tools.dart';
import 'package:path/path.dart' as path;

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'input',
      mandatory: true,
      help: 'Path to the input Dart library containing @_NativeData constructors.',
    )
    ..addOption('cpp-out', mandatory: true, help: 'Output path for the generated C++ header file.')
    ..addOption('dart-out', mandatory: true, help: 'Output path for the generated Dart part file.')
    ..addOption('stamp', help: 'Optional output path for a build stamp file.');

  final ArgResults parsedArguments = parser.parse(arguments);
  final String inputPath = parsedArguments.option('input')!;
  final String cppOutputPath = parsedArguments.option('cpp-out')!;
  final String dartOutputPath = parsedArguments.option('dart-out')!;
  final String? stampPath = parsedArguments.option('stamp');

  final SomeResolvedUnitResult result = await resolveFile(
    path: path.normalize(File(inputPath).absolute.path),
  );
  if (result is! ResolvedUnitResult) {
    throw StateError('Failed to resolve $inputPath: $result');
  }

  final String flutterRoot = Engine.findWithin().flutterDir.path;
  final String relativeCppPath = path.relative(
    path.normalize(File(cppOutputPath).absolute.path),
    from: flutterRoot,
  );
  final String underscored = path
      .withoutExtension(relativeCppPath)
      .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
  final headerGuard = 'FLUTTER_${underscored.toUpperCase()}_H_';

  final LibraryElement libElement = result.libraryElement;
  final Iterable<NativeData> definitions = NativeData.parseLibrary(libElement);
  final String cppHeader = await generateCppHeader(definitions, headerGuard: headerGuard);
  final String dartCode = await generateDartEncoders(
    definitions,
    partOfFile: libElement.firstFragment.source.shortName,
    libraryName: libElement.name,
  );

  final cppFile = File(cppOutputPath);
  final dartFile = File(dartOutputPath);
  if (Platform.environment.containsKey('LUCI_CONTEXT')) {
    if (cppFile.readAsStringSync() != cppHeader || dartFile.readAsStringSync() != dartCode) {
      stderr.writeln(
        'Error: Generated files ($cppOutputPath, $dartOutputPath) are out of sync with $inputPath.\n'
        'Do not manually edit generated files, and regenerate them after modifying $inputPath.',
      );
      exitCode = 1;
      return;
    }
  } else {
    cppFile.writeAsStringSync(cppHeader);
    dartFile.writeAsStringSync(dartCode);
  }

  if (stampPath != null) {
    final stampFile = File(stampPath);
    stampFile.parent.createSync(recursive: true);
    stampFile.writeAsStringSync('');
  }
}
