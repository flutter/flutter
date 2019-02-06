// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../build_runner/build_runner.dart';
import '../runner/flutter_command.dart';

/// Run a single codegen step.
class GenerateCommand extends FlutterCommand {
  @override
  String get description => 'run builders';

  @override
  String get name => 'generate';

  @override
  bool get hidden => true;

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (!experimentalBuildEnabled) {
      throwToolExit('flutter generate is not supported for this project.');
    }
    // Note: currently build runner code is not synced in google3, so we
    // do not inject it using context.
    final BuildRunner buildRunner = const BuildRunnerFactory().create();
    await buildRunner.build(
      mainPath: 'lib/main.dart',
      disableKernelGeneration: true,
      aot: false,
      linkPlatformKernelIn: false,
      targetProductVm: false,
      trackWidgetCreation: false,
    );
    return const FlutterCommandResult(ExitStatus.success);
  }
}