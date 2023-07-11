// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../android/gradle.dart';
import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';

class CreateLocalEngineRepoCommand extends FlutterCommand {
  CreateLocalEngineRepoCommand() {
    argParser.addOption(
      'local-repo-path',
      help:
          'Path to your engine artifact repo directory, Defaults to engineOutPath',
    );
  }

  @override
  final String name = 'create-local-engine-repo';

  @override
  String get description =>
      'Create a local engine repository containing AAR and POM file.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    globals.terminal.usesTerminalUi = true;

    final LocalEngineInfo? localEngineInfo = globals.artifacts?.localEngineInfo;
    final FileSystem fileSystem = globals.fs;
    if (localEngineInfo == null || localEngineInfo.engineOutPath.isEmpty) {
      throwToolExit('Local engine is not specified');
    }

    final String? localRepoPath = stringArg('local-repo-path');
    final String outPath = localRepoPath ?? localEngineInfo.engineOutPath;

    globals.logger.printStatus('Create local engine repo at $outPath');
    createLocalEngineRepo(
      localEngineRepoPath: outPath,
      engineOutPath: localEngineInfo.engineOutPath,
      fileSystem: fileSystem,
    );
    return FlutterCommandResult.success();
  }
}
