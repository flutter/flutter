// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import '../base/utils.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

/// Common behavior for `flutter analyze` and `flutter watch`
abstract class AnalysisCommand extends FlutterCommand {
  AnalysisCommand({bool verboseHelp: false}) {
    argParser.addFlag('flutter-repo', help: 'Include all the examples and tests from the Flutter repository.', defaultsTo: false);
    argParser.addFlag('current-directory', help: 'Include all the Dart files in the current directory, if any.', defaultsTo: true);
    argParser.addFlag('current-package', help: 'Include the lib/main.dart file from the current directory, if any.', defaultsTo: true);
    argParser.addFlag('dartdocs', help: 'List every public member that is lacking documentation (only examines files in the Flutter repository).', defaultsTo: false);
    argParser.addOption('write', valueHelp: 'file', help: 'Also output the results to a file. This is useful with --watch if you want a file to always contain the latest results.');
    argParser.addOption('dart-sdk', valueHelp: 'path-to-sdk', help: 'The path to the Dart SDK.', hide: !verboseHelp);

    // Hidden option to enable a benchmarking mode.
    argParser.addFlag('benchmark', negatable: false, hide: !verboseHelp);

    usesPubOption();
  }

  @override
  bool get shouldRunPub {
    // If they're not analyzing the current project.
    if (!argResults['current-package'])
      return false;

    // Or we're not in a project directory.
    if (!new File('pubspec.yaml').existsSync())
      return false;

    return super.shouldRunPub;
  }

  void dumpErrors(Iterable<String> errors) {
    if (argResults['write'] != null) {
      try {
        final RandomAccessFile resultsFile = new File(argResults['write']).openSync(mode: FileMode.WRITE);
        try {
          resultsFile.lockSync();
          resultsFile.writeStringSync(errors.join('\n'));
        } finally {
          resultsFile.close();
        }
      } catch (e) {
        printError('Failed to save output to "${argResults['write']}": $e');
      }
    }
  }

  void writeBenchmark(Stopwatch stopwatch, int errorCount, int membersMissingDocumentation) {
    final String benchmarkOut = 'analysis_benchmark.json';
    Map<String, dynamic> data = <String, dynamic>{
      'time': (stopwatch.elapsedMilliseconds / 1000.0),
      'issues': errorCount,
      'missingDartDocs': membersMissingDocumentation
    };
    new File(benchmarkOut).writeAsStringSync(toPrettyJson(data));
    printStatus('Analysis benchmark written to $benchmarkOut ($data).');
  }

  bool get isBenchmarking => argResults['benchmark'];
}