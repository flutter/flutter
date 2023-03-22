// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_build_system.dart';

class FakeTerminal extends Fake implements AnsiTerminal {
  FakeTerminal({this.stdinHasTerminal = true});

  @override
  final bool stdinHasTerminal;
}

class FakeProcessInfo extends Fake implements ProcessInfo {
  @override
  int maxRss = 0;
}

void main() {
  testUsingContext('Include only supported sub commands', () {
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    for (final Command<void> x in command.subcommands.values) {
      expect((x as BuildSubCommand).supported, isTrue);
    }
  });
}

class FakeBuildSubCommand extends BuildSubCommand {
  FakeBuildSubCommand() : super(verboseHelp: false);

  @override
  String get description => throw UnimplementedError();

  @override
  String get name => throw UnimplementedError();

  void test(BuildInfo buildInfo) {
    throw UnimplementedError('TODO what should we do here?');
    //displayNullSafetyMode(buildInfo);
  }

  @override
  Future<FlutterCommandResult> runCommand() {
    throw UnimplementedError();
  }
}
