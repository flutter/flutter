// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io show Process;

import 'package:process/process.dart';

import '../base/file_system.dart';
import '../base/io.dart';
import '../cache.dart';
import '../runner/flutter_command.dart';

class MigrateCommand extends FlutterCommand {
  MigrateCommand({
    bool verbose = false,
    required FileSystem fileSystem,
    required ProcessManager processManager,
  }) : _verbose = verbose,
       _fileSystem = fileSystem,
       _processManager = processManager {
    requiresPubspecYaml();
  }

  final bool _verbose;

  final FileSystem _fileSystem;

  final ProcessManager _processManager;

  @override
  final String name = 'migrate';

  @override
  final String description = 'Migrate legacy flutter projects to modern versions.';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  /// The command used for running pub.
  List<String> _migrateCommand() {
    // TODO(zanderso): refactor to use artifacts.
    final String sdkPath = _fileSystem.path.joinAll(<String>[
      Cache.flutterRoot!,
      'bin',
      'cache',
      'dart-sdk',
      'bin',
      'dart',
    ]);
    const String dillPath = '/Users/garyq/packages/packages/flutter_migrate/bin/flutter_migrate.dill';
    List<String> command = <String>[sdkPath, '--disable-dart-dev', dillPath, ...argResults!.arguments];
    print(command);
    return command;
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final List<String> cmd = _migrateCommand();
    final io.Process process = await _processManager.start(
      cmd,
      workingDirectory: _fileSystem.path.current,
      mode: ProcessStartMode.inheritStdio,
    );

    exitCode = await process.exitCode;
    return FlutterCommandResult.success();
  }
}
