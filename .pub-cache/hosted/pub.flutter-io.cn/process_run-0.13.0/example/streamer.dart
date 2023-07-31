#!/usr/bin/env dart

import 'dart:async';
import 'dart:io';

// ignore: import_of_legacy_library_into_null_safe
import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:process_run/src/common/import.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:pub_semver/pub_semver.dart';

Version version = Version(0, 1, 0);

String get currentScriptName => basenameWithoutExtension(Platform.script.path);

/*
Global options:
-h, --help       Usage help
-d, --udelay     delay in microseconds
-c, --count      count of print
-t, --timeout    timeout in millis
    --version    Print the command version
*/

const udelayOption = 'udelay';

///
/// Stream lines to stdout, according to count (count of lines), delay (delay
/// between 2 lines) and/or timeout (stop after timeout)
///
Future main(List<String> arguments) async {
  //setupQuickLogging();

  final parser = ArgParser(allowTrailingOptions: false);
  parser.addFlag('help', abbr: 'h', help: 'Usage help', negatable: false);
  // parser.addFlag('verbose', abbr: 'v', help: 'Verbose', negatable: false);
  parser.addOption(udelayOption,
      abbr: 'd', help: 'delay in microseconds', defaultsTo: null);
  parser.addOption('count',
      abbr: 'c', help: 'count of print', defaultsTo: null);
  parser.addOption('timeout',
      abbr: 't', help: 'timeout in millis', defaultsTo: null);
  parser.addFlag('version',
      help: 'Print the command version', negatable: false);

  final argsResult = parser.parse(arguments);

  int? parseInt(dynamic value) {
    return int.tryParse(value?.toString() ?? '');
  }

  final help = argsResult['help'] as bool;
  final count = parseInt(argsResult['count']);
  final delay = parseInt(argsResult[udelayOption]);
  final timeout = parseInt(argsResult['timeout']);

  void printUsage() {
    stdout.writeln('Streamer utility');
    stdout.writeln();
    stdout.writeln('Usage: $currentScriptName <command> [<arguments>]');
    stdout.writeln();
    stdout.writeln('Example: $currentScriptName -c 100');
    stdout.writeln('will display 100 lines of logs [1], [2]...[100]');
    stdout.writeln();
    stdout.writeln('Global options:');
    stdout.writeln(parser.usage);
  }

  if (help) {
    printUsage();
    return;
  }

  final displayVersion = argsResult['version'] as bool;

  if (displayVersion) {
    stdout.write('$currentScriptName version $version');
    stdout.writeln('VM: ${Platform.resolvedExecutable} ${Platform.version}');
    return;
  }

  var index = 0;
  Future<void> doPrint() async {
    if (delay != null) {
      await Future<void>.delayed(Duration(microseconds: delay));
    }
    index++;
    print('[$index]');
  }

  Future<void> doCount(int count) async {
    var localCount = count;
    while (localCount-- > 0) {
      await doPrint();
    }
  }

  if (count != null) {
    await doCount(count);
  } else if (timeout != null) {
    var sw = Stopwatch()..start();

    while (sw.elapsed < Duration(milliseconds: timeout)) {
      await doPrint();
    }
  } else {
    await doCount(10);
  }
}
