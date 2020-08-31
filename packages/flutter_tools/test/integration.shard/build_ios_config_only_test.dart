// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:process/process.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../src/common.dart';

void main() {
  test('flutter build ios --config only updates generated xcconfig file without performing build', () async {
    final String woringDirectory = globals.fs.path.join(getFlutterRoot(), 'examples', 'hello_world');
    final String flutterBin = globals.fs.path.join(getFlutterRoot(), 'bin', 'flutter');

    await const LocalProcessManager().run(<String>[
      flutterBin,
      'clean',
    ], workingDirectory: woringDirectory);
    final ProcessResult result = await const LocalProcessManager().run(<String>[
      flutterBin,
      'build',
      'ios',
      '--config-only',
      '--release',
      '--obfuscate',
      '--split-debug-info=info',
      '--no-codesign',
    ], workingDirectory: woringDirectory);

    print(result.stdout);
    print(result.stderr);

    expect(result.exitCode, 0);

    final File generatedConfig = globals.fs.file(
      globals.fs.path.join(woringDirectory, 'ios', 'Flutter', 'Generated.xcconfig'));

    // Config is updated if command succeeded.
    expect(generatedConfig, exists);
    expect(generatedConfig.readAsStringSync(), allOf(
      contains('DART_OBFUSCATION=true'),
      contains('FLUTTER_FRAMEWORK_DIR=${globals.fs.path.absolute(getFlutterRoot(), 'bin', 'cache', 'artifacts', 'engine')}'),
    ));

    // file that only exists if app was fully built.
    final File frameworkPlist = globals.fs.file(
      globals.fs.path.join(woringDirectory, 'build', 'ios', 'iphoneos', 'Runner.app', 'AppFrameworkInfo.plist'));

    expect(frameworkPlist, isNot(exists));
  },skip: !const LocalPlatform().isMacOS);
}
