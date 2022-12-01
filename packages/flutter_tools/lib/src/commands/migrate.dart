// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_migrate/flutter_migrate.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../globals.dart' as globals;
import '../ios/xcodeproj.dart';
import '../project.dart';
import '../runner/flutter_command.dart';

class MigrateCommand extends FlutterCommand {
  MigrateCommand({
    bool verbose = false,
  }) : _verbose = verbose {
    requiresPubspecYaml();

    MigrateBaseDependencies baseDependencies = MigrateBaseDependencies();

    addSubcommand(MigrateStartCommand(
      verbose: verbose,
      logger: baseDependencies.logger,
      fileSystem: baseDependencies.fileSystem,
      processManager: baseDependencies.processManager,
    ));
    addSubcommand(MigrateStatusCommand(
      verbose: verbose,
      logger: baseDependencies.logger,
      fileSystem: baseDependencies.fileSystem,
      processManager: baseDependencies.processManager,
    ));
    addSubcommand(MigrateResolveConflictsCommand(
      logger: baseDependencies.logger,
      fileSystem: baseDependencies.fileSystem,
      terminal: baseDependencies.terminal,
    ));
    addSubcommand(MigrateAbandonCommand(
      logger: baseDependencies.logger,
      fileSystem: baseDependencies.fileSystem,
      terminal: baseDependencies.terminal,
      processManager: baseDependencies.processManager
    ));
    addSubcommand(MigrateApplyCommand(
      verbose: verbose,
      logger: baseDependencies.logger,
      fileSystem: baseDependencies.fileSystem,
      terminal: baseDependencies.terminal,
      processManager: baseDependencies.processManager
    ));
  }

  final bool _verbose;

  @override
  final String name = 'migrate';

  @override
  final String description = 'Migrate legacy flutter projects to modern versions.';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  @override
  Future<FlutterCommandResult> runCommand() async => FlutterCommandResult.fail();
}
