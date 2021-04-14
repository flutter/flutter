// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart=2.9
// TODO(dnfield): migrate this once vm_snapshot_analysis is migrated.
// https://github.com/dart-lang/sdk/issues/45683

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as path;
import 'package:process/process.dart';
import 'package:vm_snapshot_analysis/program_info.dart';
import 'package:vm_snapshot_analysis/v8_profile.dart';

import 'package:meta/meta.dart';

const ProcessManager processManager = LocalProcessManager();
const FileSystem fs = LocalFileSystem();

Future<void> main(List<String> args) async {
  final Options options = Options.fromArgs(args);

  final Directory tempDirectory = fs.systemTempDirectory.createTempSync('forbidden_imports');
  print('Using $tempDirectory for temporary files.');

  final List<String> command = <String>[
    options.flutter.path,
    'build',
    'apk',
    '--target-platform',
    'android-arm64',
    '--release',
    '--analyze-size',
    '--code-size-directory',
    tempDirectory.path,
    '-v',
  ];

  await _runStreamed(command, workingDirectory: options.target.parent.path);

  final File v8SnapshotInfo = tempDirectory.childFile('snapshot.arm64-v8a.json');

  final String json = v8SnapshotInfo.readAsStringSync();
  final Snapshot snapshot = Snapshot.fromJson(jsonDecode(json) as Map<String, dynamic>);
  final ProgramInfo programInfo = toProgramInfo(snapshot);

  final List<String> foundForbiddenTypes = <String>[];
  bool fail = false;
  for (final String forbiddenType in options.forbiddenTypes) {
    final int slash = forbiddenType.indexOf('/');
    final int doubleColons = forbiddenType.indexOf('::');
    if (slash == -1 || doubleColons < 2) {
      print('Invalid forbidden type "$forbiddenType". The format must be <package_uri>::<type_name>, e.g. package:flutter/src/widgets/framework.dart::Widget');
      fail = true;
      continue;
    }

    final List<String> lookupPath = <String>[
      forbiddenType.substring(0, slash),
      forbiddenType.substring(0, doubleColons),
      forbiddenType.substring(doubleColons + 2),
    ];
    if (programInfo.lookup(lookupPath) != null) {
      foundForbiddenTypes.add(forbiddenType);
    }
  }
  if (fail) {
    print('Invalid forbidden type formats. Exiting.');
    exit(-1);
  }
  if (foundForbiddenTypes.isNotEmpty) {
    print('The output contained the following forbidden types:');
    print(foundForbiddenTypes);
    exit(-1);
  }

  print('No forbidden types found.');
  tempDirectory.deleteSync(recursive: true);
}

class Options {
  const Options({
    @required this.flutter,
    @required this.target,
    @required this.forbiddenTypes,
  });

  factory Options.fromArgs(List<String> args) {
    final String bat = Platform.isWindows ? '.bat' : '';

    final ArgParser argParser = ArgParser();
    argParser.addOption(
      'flutter',
      help: 'The path to the flutter binary.',
      valueHelp: path.join(r'$FLUTTER_ROOT', 'bin', 'flutter$bat'),
      defaultsTo: path.join(fs.currentDirectory.path, 'bin', 'flutter$bat'),
    );
    argParser.addOption(
      'target',
      abbr: 't',
      help: 'The Dart entrypoint file.',
      valueHelp: path.join(r'$FLUTTER_ROOT', 'examples', 'hello_world', 'lib', 'main.dart'),
      defaultsTo: path.join(fs.currentDirectory.path, 'examples', 'hello_world', 'lib', 'main.dart'),
    );
    argParser.addMultiOption(
      'forbidden-type',
      help: 'Type name(s) to forbid from release compilation, e.g. "package:flutter/src/widgets/framework.dart::Widget".',
      valueHelp: '<package_uri>::<type_name>',
    );

    argParser.addFlag('help', help: 'Prints usage.', negatable: false);
    final ArgResults argResults = argParser.parse(args);

    if (argResults['help'] == true) {
      print(argParser.usage);
      exit(0);
    }

    return Options(
      flutter: _getFileArg(argResults, 'flutter'),
      target: _getFileArg(argResults, 'target'),
      forbiddenTypes: Set<String>.from(argResults['forbidden-type'] as List<String>),
    );
  }

  final File flutter;
  final File target;
  final Set<String> forbiddenTypes;

  static File _getFileArg(ArgResults argResults, String argName) {
    final File result = fs.file(argResults[argName] as String);
    if (!result.existsSync()) {
      print('The $argName file at $result could not be found.');
      exit(-1);
    }
    return result;
  }
}

Future<void> _runStreamed(List<String> command, {String/*?*/ workingDirectory}) async {
  final String workingDirectoryInstruction = workingDirectory != null ? ' in directory $workingDirectory' : '';

  print('Running command ${command.join(' ')}$workingDirectoryInstruction');
  final Process process = await processManager.start(command, workingDirectory: workingDirectory);
  stdout.addStream(process.stdout);
  stderr.addStream(process.stderr);

  final int exitCode = await process.exitCode;
  if (exitCode != 0) {
    exit(exitCode);
  }
}
