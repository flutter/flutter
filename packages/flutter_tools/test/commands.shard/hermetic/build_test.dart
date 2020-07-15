// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  testUsingContext('obfuscate requires split-debug-info', () {
    final FakeBuildCommand command = FakeBuildCommand();
    final CommandRunner<void> commandRunner = createTestCommandRunner(command);

    expect(() => commandRunner.run(<String>[
      'build',
      '--obfuscate',
    ]), throwsA(isA<ToolExit>()));
  });
}

class FakeBuildCommand extends FlutterCommand {
  FakeBuildCommand() {
    addSplitDebugInfoOption();
    addDartObfuscationOption();
  }

  @override
  String get description => throw UnimplementedError();

  @override
  String get name => 'build';

  @override
  Future<FlutterCommandResult> runCommand() async {
    getBuildInfo();
    return FlutterCommandResult.success();
  }
}
