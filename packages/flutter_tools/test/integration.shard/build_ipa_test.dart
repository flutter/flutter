// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {

  group('flutter build ipa validation', () {

    test('flutter build ipa should validate Xcode build settings', () async {
      final String workingDirectory = fileSystem.path.join(
        getFlutterRoot(),
        'dev',
        'integration_tests',
        'flutter_gallery',
      );
      final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');

      await processManager.run(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'clean',
      ], workingDirectory: workingDirectory);
      final List<String> buildCommand = <String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'build',
        'ipa',
      ];
      final ProcessResult result = await processManager.run(buildCommand, workingDirectory: workingDirectory);

      expect(
          result.stdout.toString(),
          contains(
              '┌─ Xcode Settings ────────────────────────────────────────────────────────────────────┐\n'
              '│ iOS App Version: Missing                                                            │\n'
              '│ iOS Build Number: Missing                                                           │\n'
              '│ App Display Name: Missing                                                           │\n'
              '│ Deployment Target: 11.0                                                             │\n'
              '│ Bundle Identifier: io.flutter.examples.gallery                                      │\n'
              '│                                                                                     │\n'
              '│ You must set up the missing settings in Xcode                                       │\n'
              '│ Instructions: https://docs.flutter.dev/deployment/ios#review-xcode-project-settings │\n'
              '└─────────────────────────────────────────────────────────────────────────────────────┘'
          )
      );
    });
  }, skip: !platform.isMacOS); // [intended] iOS builds only work on macos.
}
