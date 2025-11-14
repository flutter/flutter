// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/commands/build_ios.dart';

import '../../general.shard/ios/core_devices_test.dart';
import '../../src/common.dart';

void main() {
  group('ExportOptions.plist generation for manual signing', () {
    test('generates simple plist for automatic signing', () async {
      final fileSystem = MemoryFileSystem.test();
      final command = BuildIOSArchiveCommand(logger: BufferLogger.test(), verboseHelp: false);

      final File plistFile = await command.createExportPlist(
        exportMethod: 'app-store',
        app: FakeBuildableIOSApp(FakeIosProject()),
        buildInfo: BuildInfo.release,
        buildSettings: const {'CODE_SIGN_STYLE': 'Automatic'},
        fileSystem: fileSystem,
      );

      final String plistContent = plistFile.readAsStringSync();
      expect(plistContent, contains('<key>method</key>'));
      expect(plistContent, contains('<string>app-store</string>'));
      expect(plistContent, isNot(contains('<key>teamID</key>')));
    });

    test('generates enhanced plist for manual signing when profile found', () async {
      final fileSystem = MemoryFileSystem.test();
      final command = BuildIOSArchiveCommand(logger: BufferLogger.test(), verboseHelp: false);

      final File plistFile = await command.createExportPlist(
        exportMethod: 'app-store',
        app: FakeBuildableIOSApp(FakeIosProject()),
        buildInfo: BuildInfo.release,
        buildSettings: const {
          'CODE_SIGN_STYLE': 'Manual',
          'DEVELOPMENT_TEAM': 'ABC123DEF4',
          'PRODUCT_BUNDLE_IDENTIFIER': 'com.example.myapp',
        },
        fileSystem: fileSystem,
      );

      final String plistContent = plistFile.readAsStringSync();
      expect(plistContent, contains('<key>teamID</key>'));
      expect(plistContent, contains('<string>ABC123DEF4</string>'));
      expect(plistContent, contains('<key>signingStyle</key>'));
      expect(plistContent, contains('<string>manual</string>'));
    });

    test('does not enhance plist for debug builds with manual signing', () async {
      final fileSystem = MemoryFileSystem.test();
      final command = BuildIOSArchiveCommand(logger: BufferLogger.test(), verboseHelp: false);

      final File plistFile = await command.createExportPlist(
        exportMethod: 'app-store',
        app: FakeBuildableIOSApp(FakeIosProject()),
        buildInfo: BuildInfo.debug,
        buildSettings: const {'CODE_SIGN_STYLE': 'Manual', 'DEVELOPMENT_TEAM': 'ABC123DEF4'},
        fileSystem: fileSystem,
      );

      final String plistContent = plistFile.readAsStringSync();
      expect(plistContent, isNot(contains('<key>teamID</key>')));
    });

    test('handles null buildSettings gracefully', () async {
      final fileSystem = MemoryFileSystem.test();
      final command = BuildIOSArchiveCommand(logger: BufferLogger.test(), verboseHelp: false);

      final File plistFile = await command.createExportPlist(
        exportMethod: 'app-store',
        app: FakeBuildableIOSApp(FakeIosProject()),
        buildInfo: BuildInfo.release,
        buildSettings: null,
        fileSystem: fileSystem,
      );

      final String plistContent = plistFile.readAsStringSync();
      expect(plistContent, contains('<key>method</key>'));
      expect(plistContent, isNot(contains('<key>teamID</key>')));
    });

    // TODO(flutter-team): Integration test for full `flutter build ipa` flow with manual signing.
    // See https://github.com/flutter/flutter/issues/177853 for the feature issue.
  });
}
