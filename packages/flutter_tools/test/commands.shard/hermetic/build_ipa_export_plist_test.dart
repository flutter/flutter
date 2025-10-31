// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/commands/build_ios.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';

void main() {
  group('ExportOptions.plist generation for manual signing', () {
    test('generates simple plist for automatic signing', () async {
      final fileSystem = MemoryFileSystem.test();
      final processManager = FakeProcessManager.empty();
      final plistParser = FakePlistParser();

      final File plistFile = await BuildIOSArchiveCommand.createExportPlistForTesting(
        exportMethod: 'app-store',
        buildInfo: BuildInfo.release,
        bundleId: 'com.example.myapp',
        codeSignStyle: 'Automatic',
        fileSystem: fileSystem,
        processManager: processManager,
        plistParser: plistParser,
      );

      final String plistContent = plistFile.readAsStringSync();
      expect(plistContent, contains('<key>method</key>'));
      expect(plistContent, contains('<string>app-store</string>'));
      expect(plistContent, contains('<key>uploadBitcode</key>'));
      expect(plistContent, isNot(contains('<key>teamID</key>')));
      expect(plistContent, isNot(contains('<key>signingStyle</key>')));
      expect(plistContent, isNot(contains('<key>provisioningProfiles</key>')));
    });

    test('generates enhanced plist for manual signing when profile found', () async {
      final fileSystem = MemoryFileSystem.test();
      final processManager = FakeProcessManager.empty();
      final plistParser = FakePlistParser();

      final File plistFile = await BuildIOSArchiveCommand.createExportPlistForTesting(
        exportMethod: 'app-store',
        buildInfo: BuildInfo.release,
        bundleId: 'com.example.myapp',
        codeSignStyle: 'Manual',
        profileSpecifier: 'MyApp Distribution',
        teamId: 'ABC123DEF4',
        profileUuid: '12345678-1234-1234-1234-123456789012',
        fileSystem: fileSystem,
        processManager: processManager,
        plistParser: plistParser,
      );

      final String plistContent = plistFile.readAsStringSync();
      expect(plistContent, contains('<key>method</key>'));
      expect(plistContent, contains('<string>app-store</string>'));
      expect(plistContent, contains('<key>teamID</key>'));
      expect(plistContent, contains('<string>ABC123DEF4</string>'));
      expect(plistContent, contains('<key>signingStyle</key>'));
      expect(plistContent, contains('<string>manual</string>'));
      expect(plistContent, contains('<key>provisioningProfiles</key>'));
      expect(plistContent, contains('<key>com.example.myapp</key>'));
      expect(plistContent, contains('<string>12345678-1234-1234-1234-123456789012</string>'));
      expect(plistContent, contains('<key>stripSwiftSymbols</key>'));
      expect(plistContent, contains('<true/>'));
    });

    test('falls back to simple plist when profile UUID not provided for manual signing', () async {
      final fileSystem = MemoryFileSystem.test();
      final processManager = FakeProcessManager.empty();
      final plistParser = FakePlistParser();

      final File plistFile = await BuildIOSArchiveCommand.createExportPlistForTesting(
        exportMethod: 'app-store',
        buildInfo: BuildInfo.release,
        bundleId: 'com.example.myapp',
        codeSignStyle: 'Manual',
        profileSpecifier: 'MyApp Distribution',
        teamId: 'ABC123DEF4',
        // profileUuid is null - should fall back
        fileSystem: fileSystem,
        processManager: processManager,
        plistParser: plistParser,
      );

      final String plistContent = plistFile.readAsStringSync();
      // Should fall back to simple plist when profile UUID not found
      expect(plistContent, contains('<key>method</key>'));
      expect(plistContent, contains('<string>app-store</string>'));
      expect(plistContent, isNot(contains('<key>teamID</key>')));
      expect(plistContent, isNot(contains('<key>signingStyle</key>')));
      expect(plistContent, isNot(contains('<key>provisioningProfiles</key>')));
    });

    test('does not enhance plist for debug builds with manual signing', () async {
      final fileSystem = MemoryFileSystem.test();
      final processManager = FakeProcessManager.empty();
      final plistParser = FakePlistParser();

      final File plistFile = await BuildIOSArchiveCommand.createExportPlistForTesting(
        exportMethod: 'app-store',
        buildInfo: BuildInfo.debug,
        bundleId: 'com.example.myapp',
        codeSignStyle: 'Manual',
        profileSpecifier: 'MyApp Distribution',
        teamId: 'ABC123DEF4',
        profileUuid: '12345678-1234-1234-1234-123456789012',
        fileSystem: fileSystem,
        processManager: processManager,
        plistParser: plistParser,
      );

      final String plistContent = plistFile.readAsStringSync();
      // Should use simple plist for debug builds even with manual signing
      expect(plistContent, contains('<key>method</key>'));
      expect(plistContent, contains('<string>app-store</string>'));
      expect(plistContent, isNot(contains('<key>teamID</key>')));
      expect(plistContent, isNot(contains('<key>signingStyle</key>')));
      expect(plistContent, isNot(contains('<key>provisioningProfiles</key>')));
    });

    test('generates enhanced plist for profile builds with manual signing', () async {
      final fileSystem = MemoryFileSystem.test();
      final processManager = FakeProcessManager.empty();
      final plistParser = FakePlistParser();

      final File plistFile = await BuildIOSArchiveCommand.createExportPlistForTesting(
        exportMethod: 'app-store',
        buildInfo: BuildInfo.profile,
        bundleId: 'com.example.myapp',
        codeSignStyle: 'Manual',
        profileSpecifier: 'MyApp Distribution',
        teamId: 'ABC123DEF4',
        profileUuid: '12345678-1234-1234-1234-123456789012',
        fileSystem: fileSystem,
        processManager: processManager,
        plistParser: plistParser,
      );

      final String plistContent = plistFile.readAsStringSync();
      expect(plistContent, contains('<key>teamID</key>'));
      expect(plistContent, contains('<key>signingStyle</key>'));
      expect(plistContent, contains('<string>manual</string>'));
      expect(plistContent, contains('<key>provisioningProfiles</key>'));
    });

    // TODO(mohamed): Integration test for full `flutter build ipa` flow with manual signing.
    // This is currently skipped because `IosProject.buildSettingsForBuildInfo` does not
    // return mocked settings in the test harness environment. The project discovery logic
    // requires a fully-formed iOS project structure that is difficult to replicate in the
    // current hermetic test setup. See https://github.com/flutter/flutter/issues/177853
    // for the feature issue.
    test(
      'full build ipa path generates plist for manual signing (integration)',
      () {
        // Skipped - see TODO above
      },
      skip: 'Integration test requires hermetic iOS project fixture',
    );
  });
}
