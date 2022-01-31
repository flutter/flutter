// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  test('flutter build ios --config only updates generated xcconfig file without performing build', () async {
    final String workingDirectory = fileSystem.path.join(getFlutterRoot(), 'examples', 'hello_world');
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');

    await processManager.run(<String>[
      flutterBin,
       ...getLocalEngineArguments(),
      'clean',
    ], workingDirectory: workingDirectory);
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'ios',
      '--config-only',
      '--release',
      '--obfuscate',
      '--split-debug-info=info',
      '--no-codesign',
    ], workingDirectory: workingDirectory);

    printOnFailure('Output of flutter build ios:');
    printOnFailure(result.stdout.toString());
    printOnFailure(result.stderr.toString());

    expect(result.exitCode, 0);

    final File generatedConfig = fileSystem.file(
      fileSystem.path.join(workingDirectory, 'ios', 'Flutter', 'Generated.xcconfig'));

    // Config is updated if command succeeded.
    expect(generatedConfig, exists);
    expect(generatedConfig.readAsStringSync(), contains('DART_OBFUSCATION=true'));

    // file that only exists if app was fully built.
    final File frameworkPlist = fileSystem.file(
      fileSystem.path.join(workingDirectory, 'build', 'ios', 'iphoneos', 'Runner.app', 'AppFrameworkInfo.plist'));

    expect(frameworkPlist, isNot(exists));
  }, skip: !platform.isMacOS); // [intended] iOS builds only work on macos.
}
