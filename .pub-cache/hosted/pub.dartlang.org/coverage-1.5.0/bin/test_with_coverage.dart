// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:coverage/src/util.dart'
    show StandardOutExtension, extractVMServiceUri;
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as path;

import 'collect_coverage.dart' as collect_coverage;
import 'format_coverage.dart' as format_coverage;

final _allProcesses = <Process>[];

Future<void> _dartRun(List<String> args,
    {void Function(String)? onStdout, String? workingDir}) async {
  final process = await Process.start(
    Platform.executable,
    args,
    workingDirectory: workingDir,
  );
  _allProcesses.add(process);
  final broadStdout = process.stdout.asBroadcastStream();
  broadStdout.listen(stdout.add);
  if (onStdout != null) {
    broadStdout.lines().listen(onStdout);
  }
  process.stderr.listen(stderr.add);
  final result = await process.exitCode;
  if (result != 0) {
    throw ProcessException(Platform.executable, args, '', result);
  }
}

Future<String?> _packageNameFromConfig(String packageDir) async {
  final config = await findPackageConfig(Directory(packageDir));
  return config?.packageOf(Uri.directory(packageDir))?.name;
}

void _watchExitSignal(ProcessSignal signal) {
  signal.watch().listen((sig) {
    for (final process in _allProcesses) {
      process.kill(sig);
    }
    exit(1);
  });
}

ArgParser _createArgParser() => ArgParser()
  ..addOption(
    'package',
    help: 'Root directory of the package to test.',
    defaultsTo: '.',
  )
  ..addOption(
    'package-name',
    help: 'Name of the package to test. '
        'Deduced from --package if not provided.',
  )
  ..addOption('port', help: 'VM service port.', defaultsTo: '8181')
  ..addOption(
    'out',
    abbr: 'o',
    help: 'Output directory. Defaults to <package-dir>/coverage.',
  )
  ..addOption('test', help: 'Test script to run.', defaultsTo: 'test')
  ..addFlag(
    'function-coverage',
    abbr: 'f',
    defaultsTo: false,
    help: 'Collect function coverage info.',
  )
  ..addFlag(
    'branch-coverage',
    abbr: 'b',
    defaultsTo: false,
    help: 'Collect branch coverage info.',
  )
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

class Flags {
  Flags(
    this.packageDir,
    this.packageName,
    this.outDir,
    this.port,
    this.testScript,
    this.functionCoverage,
    this.branchCoverage, {
    required this.rest,
  });

  final String packageDir;
  final String packageName;
  final String outDir;
  final String port;
  final String testScript;
  final bool functionCoverage;
  final bool branchCoverage;
  final List<String> rest;
}

Future<Flags> _parseArgs(List<String> arguments) async {
  final parser = _createArgParser();
  final args = parser.parse(arguments);

  void printUsage() {
    print('''
Runs tests and collects coverage for a package.

By default this  script assumes it's being run from the root directory of a
package, and outputs a coverage.json and lcov.info to ./coverage/

Usage: test_with_coverage [OPTIONS...] [-- <test script OPTIONS>]

${parser.usage}
''');
  }

  Never fail(String msg) {
    print('\n$msg\n');
    printUsage();
    exit(1);
  }

  if (args['help'] as bool) {
    printUsage();
    exit(0);
  }

  final packageDir = path.canonicalize(args['package'] as String);
  if (!FileSystemEntity.isDirectorySync(packageDir)) {
    fail('--package is not a valid directory.');
  }

  final packageName = (args['package-name'] as String?) ??
      await _packageNameFromConfig(packageDir);
  if (packageName == null) {
    fail(
      "Couldn't figure out package name from --package. Make sure this is a "
      'package directory, or try passing --package-name explicitly.',
    );
  }

  return Flags(
    packageDir,
    packageName,
    (args['out'] as String?) ?? path.join(packageDir, 'coverage'),
    args['port'] as String,
    args['test'] as String,
    args['function-coverage'] as bool,
    args['branch-coverage'] as bool,
    rest: args.rest,
  );
}

Future<void> main(List<String> arguments) async {
  final flags = await _parseArgs(arguments);
  final outJson = path.join(flags.outDir, 'coverage.json');
  final outLcov = path.join(flags.outDir, 'lcov.info');

  if (!FileSystemEntity.isDirectorySync(flags.outDir)) {
    await Directory(flags.outDir).create(recursive: true);
  }

  _watchExitSignal(ProcessSignal.sighup);
  _watchExitSignal(ProcessSignal.sigint);
  if (!Platform.isWindows) {
    _watchExitSignal(ProcessSignal.sigterm);
  }

  final serviceUriCompleter = Completer<Uri>();
  final testProcess = _dartRun(
    [
      if (flags.branchCoverage) '--branch-coverage',
      'run',
      '--pause-isolates-on-exit',
      '--disable-service-auth-codes',
      '--enable-vm-service=${flags.port}',
      flags.testScript,
      ...flags.rest,
    ],
    onStdout: (line) {
      if (!serviceUriCompleter.isCompleted) {
        final uri = extractVMServiceUri(line);
        if (uri != null) {
          serviceUriCompleter.complete(uri);
        }
      }
    },
  );
  final serviceUri = await serviceUriCompleter.future;

  await collect_coverage.main([
    '--wait-paused',
    '--resume-isolates',
    '--uri=$serviceUri',
    '--scope-output=${flags.packageName}',
    if (flags.branchCoverage) '--branch-coverage',
    if (flags.functionCoverage) '--function-coverage',
    '-o',
    outJson,
  ]);
  await testProcess;

  await format_coverage.main([
    '--lcov',
    '--check-ignore',
    '--package=${flags.packageDir}',
    '-i',
    outJson,
    '-o',
    outLcov,
  ]);
  exit(0);
}
