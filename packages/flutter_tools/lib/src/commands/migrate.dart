// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/logger.dart';
import '../cache.dart';
import '../runner/flutter_command.dart';
import 'migrate_abandon.dart';
import 'migrate_apply.dart';
import 'migrate_start.dart';
import 'migrate_status.dart';

const String kDefaultMigrateWorkingDirectoryName = 'migrate_working_dir';

class MigrateCommand extends FlutterCommand {
  MigrateCommand({
    bool verbose = false,
    this.logger,
  }) : _verbose = verbose {
    addSubcommand(MigrateAbandonCommand(verbose: _verbose, logger: logger));
    addSubcommand(MigrateApplyCommand(verbose: _verbose, logger: logger));
    addSubcommand(MigrateStartCommand(verbose: _verbose, logger: logger));
    addSubcommand(MigrateStatusCommand(verbose: _verbose, logger: logger));
  }

  final bool _verbose;

  final Logger logger;

  @override
  final String name = 'migrate';

  @override
  final String description = 'Migrates flutter generated project files to the current flutter version';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  @override
  Future<FlutterCommandResult> runCommand() async {
    return const FlutterCommandResult(ExitStatus.fail);
  }
}
