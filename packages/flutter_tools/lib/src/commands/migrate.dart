// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart';
import '../migrate/migrate_config.dart';
import '../migrate/migrate_manifest.dart';
import '../migrate/migrate_utils.dart';
import '../cache.dart';
import 'migrate_abandon.dart';
import 'migrate_apply.dart';
import 'migrate_start.dart';

const String kDefaultMigrateWorkingDirectoryName = 'migrate_working_dir';

class MigrateCommand extends FlutterCommand {
  MigrateCommand({
    bool verbose = false,
  }) : _verbose = verbose {
    addSubcommand(MigrateAbandonCommand(verbose: verbose));
    addSubcommand(MigrateApplyCommand(verbose: verbose));
    addSubcommand(MigrateStartCommand(verbose: verbose));
    requiresPubspecYaml();
    // TODO move these to subcomands instead of flags.
    argParser.addFlag('apply',
      negatable: false,
      help: "",
    );
    argParser.addFlag('abandon',
      negatable: false,
      help: "",
    );
    argParser.addFlag('delete-temp-directories',
      negatable: true,
      help: "",
    );
    argParser.addOption(
      'old-app-directory',
      help: '',
      defaultsTo: null,
      valueHelp: 'path',
    );
    argParser.addOption(
      'new-app-directory',
      help: '',
      defaultsTo: null,
      valueHelp: 'path',
    );
    argParser.addOption(
      'base-revision',
      help: '',
      defaultsTo: null,
      valueHelp: '',
    );
  }

  final bool _verbose;

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
