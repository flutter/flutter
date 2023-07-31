// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:coverage/coverage.dart';
import 'package:path/path.dart' as p;

/// [Environment] stores gathered arguments information.
class Environment {
  Environment({
    required this.baseDirectory,
    required this.bazel,
    required this.bazelWorkspace,
    required this.checkIgnore,
    required this.input,
    required this.lcov,
    required this.output,
    required this.packagesPath,
    required this.packagePath,
    required this.prettyPrint,
    required this.prettyPrintFunc,
    required this.prettyPrintBranch,
    required this.reportOn,
    required this.sdkRoot,
    required this.verbose,
    required this.workers,
  });

  String? baseDirectory;
  bool bazel;
  String bazelWorkspace;
  bool checkIgnore;
  String input;
  bool lcov;
  IOSink output;
  String? packagesPath;
  String packagePath;
  bool prettyPrint;
  bool prettyPrintFunc;
  bool prettyPrintBranch;
  List<String>? reportOn;
  String? sdkRoot;
  bool verbose;
  int workers;
}

Future<void> main(List<String> arguments) async {
  final env = parseArgs(arguments);

  final files = filesToProcess(env.input);
  if (env.verbose) {
    print('Environment:');
    print('  # files: ${files.length}');
    print('  # workers: ${env.workers}');
    print('  sdk-root: ${env.sdkRoot}');
    print('  package-path: ${env.packagePath}');
    print('  packages-path: ${env.packagesPath}');
    print('  report-on: ${env.reportOn}');
    print('  check-ignore: ${env.checkIgnore}');
  }

  final clock = Stopwatch()..start();
  final hitmap = await HitMap.parseFiles(
    files,
    checkIgnoredLines: env.checkIgnore,
    // ignore: deprecated_member_use_from_same_package
    packagesPath: env.packagesPath,
    packagePath: env.packagePath,
  );

  // All workers are done. Process the data.
  if (env.verbose) {
    print('Done creating global hitmap. Took ${clock.elapsedMilliseconds} ms.');
  }

  String output;
  final resolver = env.bazel
      ? BazelResolver(workspacePath: env.bazelWorkspace)
      : await Resolver.create(
          packagesPath: env.packagesPath,
          packagePath: env.packagePath,
          sdkRoot: env.sdkRoot,
        );
  final loader = Loader();
  if (env.prettyPrint) {
    output = await hitmap.prettyPrint(resolver, loader,
        reportOn: env.reportOn,
        reportFuncs: env.prettyPrintFunc,
        reportBranches: env.prettyPrintBranch);
  } else {
    assert(env.lcov);
    output = hitmap.formatLcov(resolver,
        reportOn: env.reportOn, basePath: env.baseDirectory);
  }

  env.output.write(output);
  await env.output.flush();
  if (env.verbose) {
    print('Done flushing output. Took ${clock.elapsedMilliseconds} ms.');
  }

  if (env.verbose) {
    if (resolver.failed.isNotEmpty) {
      print('Failed to resolve:');
      for (var error in resolver.failed.toSet()) {
        print('  $error');
      }
    }
    if (loader.failed.isNotEmpty) {
      print('Failed to load:');
      for (var error in loader.failed.toSet()) {
        print('  $error');
      }
    }
  }
  await env.output.close();
}

/// Checks the validity of the provided arguments. Does not initialize actual
/// processing.
Environment parseArgs(List<String> arguments) {
  final parser = ArgParser();

  parser.addOption('sdk-root', abbr: 's', help: 'path to the SDK root');
  parser.addOption('packages',
      help: '[DEPRECATED] path to the package spec file');
  parser.addOption('package',
      help: 'root directory of the package', defaultsTo: '.');
  parser.addOption('in', abbr: 'i', help: 'input(s): may be file or directory');
  parser.addOption('out',
      abbr: 'o', defaultsTo: 'stdout', help: 'output: may be file or stdout');
  parser.addMultiOption('report-on',
      help: 'which directories or files to report coverage on');
  parser.addOption('workers',
      abbr: 'j', defaultsTo: '1', help: 'number of workers');
  parser.addOption('bazel-workspace',
      defaultsTo: '', help: 'Bazel workspace directory');
  parser.addOption('base-directory',
      abbr: 'b',
      help: 'the base directory relative to which source paths are output');
  parser.addFlag('bazel',
      defaultsTo: false, help: 'use Bazel-style path resolution');
  parser.addFlag('pretty-print',
      abbr: 'r',
      negatable: false,
      help: 'convert line coverage data to pretty print format');
  parser.addFlag('pretty-print-func',
      abbr: 'f',
      negatable: false,
      help: 'convert function coverage data to pretty print format');
  parser.addFlag('pretty-print-branch',
      negatable: false,
      help: 'convert branch coverage data to pretty print format');
  parser.addFlag('lcov',
      abbr: 'l',
      negatable: false,
      help: 'convert coverage data to lcov format');
  parser.addFlag('verbose',
      abbr: 'v', negatable: false, help: 'verbose output');
  parser.addFlag(
    'check-ignore',
    abbr: 'c',
    negatable: false,
    help: 'check for coverage ignore comments.'
        ' Not supported in web coverage.',
  );
  parser.addFlag('help', abbr: 'h', negatable: false, help: 'show this help');

  final args = parser.parse(arguments);

  void printUsage() {
    print('Usage: dart format_coverage.dart [OPTION...]\n');
    print(parser.usage);
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

  var sdkRoot = args['sdk-root'] as String?;
  if (sdkRoot != null) {
    sdkRoot = p.normalize(p.join(p.absolute(sdkRoot), 'lib'));
    if (!FileSystemEntity.isDirectorySync(sdkRoot)) {
      fail('Provided SDK root "${args["sdk-root"]}" is not a valid SDK '
          'top-level directory');
    }
  }

  final packagesPath = args['packages'] as String?;
  if (packagesPath != null) {
    if (!FileSystemEntity.isFileSync(packagesPath)) {
      fail('Package spec "${args["packages"]}" not found, or not a file.');
    }
  }

  final packagePath = args['package'] as String;
  if (!FileSystemEntity.isDirectorySync(packagePath)) {
    fail('Package spec "${args["package"]}" not found, or not a directory.');
  }

  if (args['in'] == null) fail('No input files given.');
  final input = p.absolute(p.normalize(args['in'] as String));
  if (!FileSystemEntity.isDirectorySync(input) &&
      !FileSystemEntity.isFileSync(input)) {
    fail('Provided input "${args["in"]}" is neither a directory nor a file.');
  }

  IOSink output;
  if (args['out'] == 'stdout') {
    output = stdout;
  } else {
    final outpath = p.absolute(p.normalize(args['out'] as String));
    final outfile = File(outpath)..createSync(recursive: true);
    output = outfile.openWrite();
  }

  final reportOnRaw = args['report-on'] as List<String>;
  final reportOn = reportOnRaw.isNotEmpty ? reportOnRaw : null;

  final bazel = args['bazel'] as bool;
  final bazelWorkspace = args['bazel-workspace'] as String;
  if (bazelWorkspace.isNotEmpty && !bazel) {
    stderr.writeln('warning: ignoring --bazel-workspace: --bazel not set');
  }

  String? baseDirectory;
  if (args['base-directory'] != null) {
    baseDirectory = p.absolute(args['base-directory'] as String);
  }

  final lcov = args['lcov'] as bool;
  var prettyPrint = args['pretty-print'] as bool;
  final prettyPrintFunc = args['pretty-print-func'] as bool;
  final prettyPrintBranch = args['pretty-print-branch'] as bool;
  final numModesChosen = (prettyPrint ? 1 : 0) +
      (prettyPrintFunc ? 1 : 0) +
      (prettyPrintBranch ? 1 : 0) +
      (lcov ? 1 : 0);
  if (numModesChosen > 1) {
    fail('Choose one of the pretty-print modes or lcov output');
  }

  // The pretty printer is used by all modes other than lcov.
  if (!lcov) prettyPrint = true;

  int workers;
  try {
    workers = int.parse('${args["workers"]}');
  } catch (e) {
    fail('Invalid worker count: $e');
  }

  final checkIgnore = args['check-ignore'] as bool;
  final verbose = args['verbose'] as bool;
  return Environment(
      baseDirectory: baseDirectory,
      bazel: bazel,
      bazelWorkspace: bazelWorkspace,
      checkIgnore: checkIgnore,
      input: input,
      lcov: lcov,
      output: output,
      packagesPath: packagesPath,
      packagePath: packagePath,
      prettyPrint: prettyPrint,
      prettyPrintFunc: prettyPrintFunc,
      prettyPrintBranch: prettyPrintBranch,
      reportOn: reportOn,
      sdkRoot: sdkRoot,
      verbose: verbose,
      workers: workers);
}

/// Given an absolute path absPath, this function returns a [List] of files
/// are contained by it if it is a directory, or a [List] containing the file if
/// it is a file.
List<File> filesToProcess(String absPath) {
  if (FileSystemEntity.isDirectorySync(absPath)) {
    return Directory(absPath)
        .listSync(recursive: true)
        .whereType<File>()
        .where((e) => e.path.endsWith('.json'))
        .toList();
  }
  return <File>[File(absPath)];
}
