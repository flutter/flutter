// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  test('flutter create accepts apostrophes in Apple plugin descriptions', () async {
    final Directory temp = createResolvedTempDirectorySync('create_plugin_podspec.');
    addTearDown(() => ErrorHandlingFileSystem.deleteIfExists(temp, recursive: true));
    final Directory plugin = temp.childDirectory('attitude_plugin');

    final ProcessResult create = await processManager.run(<String>[
      flutterBin,
      'create',
      '--no-pub',
      '--template=plugin',
      '--platforms=ios,macos',
      '--description',
      "Reports the device's attitude.",
      plugin.path,
    ]);
    expect(create, const ProcessResultMatcher());

    for (final platformName in <String>['ios', 'macos']) {
      final File podspec = plugin.childDirectory(platformName).childFile('attitude_plugin.podspec');
      final ProcessResult syntaxCheck = await processManager.run(<String>[
        '/usr/bin/ruby',
        '-c',
        podspec.path,
      ]);
      expect(syntaxCheck, const ProcessResultMatcher(stdoutPattern: 'Syntax OK'));
    }
  }, skip: !platform.isMacOS); // [intended] Uses macOS system Ruby.
}
