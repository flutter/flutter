// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/runner/options/common_options.dart';
import 'package:test/test.dart';

import '../../../src/fakes.dart';

class DummyCommand extends FlutterCommand {
  DummyCommand() : super(toolContext: FakeToolContext()) {
    registerOptionBundles(<OptionBundle>[const BuildInfoOptionsBundle()]);
  }

  @override
  final String name = 'dummy';

  @override
  final String description = 'A dummy command';

  @override
  Future<FlutterCommandResult> runCommand() async {
    return FlutterCommandResult.success();
  }
}

class _BundleCommand extends FlutterCommand {
  _BundleCommand(List<OptionBundle> bundles)
    : super(toolContext: FakeToolContext()) {
    registerOptionBundles(bundles);
  }

  @override
  final String name = 'bundle';

  @override
  final String description = 'A bundle test command';

  @override
  Future<FlutterCommandResult> runCommand() async {
    return FlutterCommandResult.success();
  }
}

void main() {
  test('build option bundles register frontend-server-starter-path', () {
    for (final bundle in <OptionBundle>[
      const AndroidBuildOptionsBundle(),
      const AppleBuildOptionsBundle(),
      const DesktopBuildOptionsBundle(),
    ]) {
      final command = _BundleCommand(<OptionBundle>[bundle]);
      expect(
        command.argParser.options.keys,
        contains('frontend-server-starter-path'),
        reason: bundle.runtimeType.toString(),
      );
    }
  });

  test('BuildInfoOptionsBundle registers all descriptors successfully', () {
    final command = DummyCommand();
    final runner = CommandRunner<void>('test', 'test');
    runner.addCommand(command);

    expect(
      command.argParser.options.keys,
      containsAll(<String>[
        'track-widget-creation',
        'analyze-size',
        'code-size-directory',
        'obfuscate',
        'split-debug-info',
        'android-gradle-daemon',
        'android-project-arg',
        'android-project-cache-dir',
        'android-skip-build-dependency-validation',
        'performance-measurement-file',
        'flavor',
        'codesign',
        'frontend-server-starter-path',
        'extra-front-end-options',
        'extra-gen-snapshot-options',
        'initialize-from-dill',
        'assume-initialize-from-dill-up-to-date',
      ]),
    );
  });
}
