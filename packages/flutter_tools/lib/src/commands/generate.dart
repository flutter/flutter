// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/logger.dart';
import '../build_runner/build_runner.dart';
import '../cache.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class GenerateCommand extends FlutterCommand {
  @override
  String get description => 'run build_runner code generation';

  @override
  String get name => 'generate';

  @override
  bool get hidden => true;

  @override
  Future<FlutterCommandResult> runCommand() async {
    Cache.releaseLockEarly();
    if (!await experimentalBuildEnabled) {
      printTrace('Experimental flutter build not enabled. Exiting...');
      return const FlutterCommandResult(ExitStatus.fail);
    }
    final BuildRunner buildRunner = BuildRunner();
    final Status status = logger.startProgress(
      'Running builders...',
      timeout: null,
    );
    try {
      await buildRunner.codegen();
    } on Exception {
      status?.cancel();
      return const FlutterCommandResult(ExitStatus.fail);
    }
    status.stop();
    return const FlutterCommandResult(ExitStatus.success);
  }
}
