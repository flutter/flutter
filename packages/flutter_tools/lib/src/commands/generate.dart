// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../cache.dart';
import '../codegen.dart';
import '../convert.dart';
import '../globals.dart';
import '../project.dart';
import '../runner/flutter_command.dart';

class GenerateCommand extends FlutterCommand {
  GenerateCommand() {
    usesTargetOption();
  }
  @override
  String get description => 'run code generators.';

  @override
  String get name => 'generate';

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{
    DevelopmentArtifact.universal,
  };

  @override
  Future<FlutterCommandResult> runCommand() async {
    Cache.releaseLockEarly();
    final FlutterProject flutterProject = FlutterProject.current();
    final CodegenDaemon codegenDaemon = await codeGenerator.daemon(flutterProject);
    codegenDaemon.startBuild();
    await for (CodegenStatus codegenStatus in codegenDaemon.buildResults) {
      if (codegenStatus == CodegenStatus.Failed) {
        printError('Code generation failed.');
        break;
      }
      if (codegenStatus ==CodegenStatus.Succeeded) {
        break;
      }
    }
    // Check for errors output in the build_runner cache.
    final Directory buildDirectory = flutterProject.dartTool.childDirectory('build');
    final Directory errorCacheParent = buildDirectory.listSync().firstWhere((FileSystemEntity entity) {
      return entity is Directory && entity.childDirectory('error_cache').existsSync();
    }, orElse: () => null);
    if (errorCacheParent == null) {
      return null;
    }
    final Directory errorCache = errorCacheParent.childDirectory('error_cache');
    for (File errorFile in errorCache.listSync(recursive: true).whereType<File>()) {
      try {
        final List<Object> errorData = json.decode(errorFile.readAsStringSync());
        final List<Object> stackData = errorData[1];
        printError(errorData.first);
        printError(stackData[0]);
        printError(stackData[1]);
        printError(StackTrace.fromString(stackData[2]).toString());
      } catch (err) {
        printError('Error reading error in ${errorFile.path}');
      }
    }
    return const FlutterCommandResult(ExitStatus.fail);
  }
}
