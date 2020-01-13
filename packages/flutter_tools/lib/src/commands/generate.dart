// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../cache.dart';
import '../codegen.dart';
import '../convert.dart';
import '../globals.dart' as globals;
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
  Future<FlutterCommandResult> runCommand() async {
    Cache.releaseLockEarly();
    final FlutterProject flutterProject = FlutterProject.current();
    final CodegenDaemon codegenDaemon = await codeGenerator.daemon(flutterProject);
    codegenDaemon.startBuild();
    await for (final CodegenStatus codegenStatus in codegenDaemon.buildResults) {
      if (codegenStatus == CodegenStatus.Failed) {
        globals.printError('Code generation failed.');
        break;
      }
      if (codegenStatus == CodegenStatus.Succeeded) {
        break;
      }
    }
    // Check for errors output in the build_runner cache.
    final Directory buildDirectory = flutterProject.dartTool.childDirectory('build');
    final Directory errorCacheParent = buildDirectory.listSync().whereType<Directory>().firstWhere((Directory dir) {
      return dir.childDirectory('error_cache').existsSync();
    }, orElse: () => null);
    if (errorCacheParent == null) {
      return FlutterCommandResult.success();
    }
    final Directory errorCache = errorCacheParent.childDirectory('error_cache');
    for (final File errorFile in errorCache.listSync(recursive: true).whereType<File>()) {
      try {
        final List<Object> errorData = json.decode(errorFile.readAsStringSync()) as List<Object>;
        final List<Object> stackData = errorData[1] as List<Object>;
        globals.printError(errorData.first as String);
        globals.printError(stackData[0] as String);
        globals.printError(stackData[1] as String);
        globals.printError(StackTrace.fromString(stackData[2] as String).toString());
      } catch (err) {
        globals.printError('Error reading error in ${errorFile.path}');
      }
    }
    return FlutterCommandResult.fail();
  }
}
