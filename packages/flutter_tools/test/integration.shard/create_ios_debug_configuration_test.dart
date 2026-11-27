// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/convert.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  test('flutter create defines Swift DEBUG for the iOS app and its tests', () async {
    final Directory temp = createResolvedTempDirectorySync('create_ios_debug_configuration.');
    addTearDown(() => ErrorHandlingFileSystem.deleteIfExists(temp, recursive: true));
    final Directory app = temp.childDirectory('debug_app');

    final ProcessResult create = await processManager.run(<String>[
      flutterBin,
      'create',
      '--platforms=ios',
      app.path,
    ]);
    expect(create, const ProcessResultMatcher());

    final String projectPath = app.childDirectory('ios').childDirectory('Runner.xcodeproj').path;
    for (final configuration in <String>['Debug', 'Profile', 'Release']) {
      final ProcessResult result = await processManager.run(<String>[
        'xcrun',
        'xcodebuild',
        '-project',
        projectPath,
        '-alltargets',
        '-configuration',
        configuration,
        '-showBuildSettings',
        '-json',
      ]);
      expect(result, const ProcessResultMatcher());

      final List<Map<String, Object?>> settings =
          (jsonDecode(result.stdout as String) as List<Object?>).cast<Map<String, Object?>>();
      for (final target in <String>['Runner', 'RunnerTests']) {
        final Map<String, Object?>? entry = settings
            .where((Map<String, Object?> entry) => entry['target'] == target)
            .firstOrNull;
        expect(
          entry,
          isNotNull,
          reason: 'Xcode did not report build settings for $target ($configuration).',
        );
        final buildSettings = entry!['buildSettings']! as Map<String, Object?>;
        final List<String> flags =
            (buildSettings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] as String? ?? '').split(' ');
        expect(
          flags,
          configuration == 'Debug' ? contains('DEBUG') : isNot(contains('DEBUG')),
          reason: '$target $configuration',
        );
      }
    }
  }, skip: !platform.isMacOS); // [intended] Requires Xcode.
}
