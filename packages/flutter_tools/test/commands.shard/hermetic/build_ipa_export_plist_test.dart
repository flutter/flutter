// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Unit tests for ExportOptions.plist generation in manual signing scenarios.
//
// These tests verify the logic for generating export options without requiring
// a full `flutter build ipa` integration, which would require a hermetic iOS project
// fixture that's difficult to maintain.
//
// **Test strategy:**
// - Use `createExportPlistForTesting` to directly test plist generation logic
// - Mock dependencies (FileSystem) to avoid filesystem dependencies
// - Verify plist XML content contains expected keys and values
// - Cover both success and fallback scenarios
//
// **Test coverage:**
// - Automatic signing: Generates simple plist (existing behavior preserved)
// - Manual signing + profile found: Generates enhanced plist with signing config
// - Manual signing + profile not found: Falls back to simple plist gracefully
// - Debug builds: Skips enhancement (not App Store export, avoids overhead)
// - Profile builds: Applies enhancement (same as Release)
// - Different export methods: Respects ad-hoc, app-store, etc.
// - Null codeSignStyle: Handles gracefully (defaults to simple plist)
//
// See https://github.com/flutter/flutter/issues/177853 for the feature issue.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/commands/build_ios.dart';

import '../../src/common.dart';

void main() {
  group('ExportOptions.plist generation for manual signing', () {
    test('generates simple plist for automatic signing', () async {
      final fileSystem = MemoryFileSystem.test();

      final File plistFile = await BuildIOSArchiveCommand.createExportPlistForTesting(
        exportMethod: 'app-store',
        buildInfo: BuildInfo.release,
        bundleId: 'com.example.myapp',
        codeSignStyle: 'Automatic',
        fileSystem: fileSystem,
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

      final File plistFile = await BuildIOSArchiveCommand.createExportPlistForTesting(
        exportMethod: 'app-store',
        buildInfo: BuildInfo.release,
        bundleId: 'com.example.myapp',
        codeSignStyle: 'Manual',
        profileSpecifier: 'MyApp Distribution',
        teamId: 'ABC123DEF4',
        profileUuid: '12345678-1234-1234-1234-123456789012',
        fileSystem: fileSystem,
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

      final File plistFile = await BuildIOSArchiveCommand.createExportPlistForTesting(
        exportMethod: 'app-store',
        buildInfo: BuildInfo.release,
        bundleId: 'com.example.myapp',
        codeSignStyle: 'Manual',
        profileSpecifier: 'MyApp Distribution',
        teamId: 'ABC123DEF4',
        // profileUuid is null - should fall back
        fileSystem: fileSystem,
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

      final File plistFile = await BuildIOSArchiveCommand.createExportPlistForTesting(
        exportMethod: 'app-store',
        buildInfo: BuildInfo.debug,
        bundleId: 'com.example.myapp',
        codeSignStyle: 'Manual',
        profileSpecifier: 'MyApp Distribution',
        teamId: 'ABC123DEF4',
        profileUuid: '12345678-1234-1234-1234-123456789012',
        fileSystem: fileSystem,
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

      final File plistFile = await BuildIOSArchiveCommand.createExportPlistForTesting(
        exportMethod: 'app-store',
        buildInfo: BuildInfo.profile,
        bundleId: 'com.example.myapp',
        codeSignStyle: 'Manual',
        profileSpecifier: 'MyApp Distribution',
        teamId: 'ABC123DEF4',
        profileUuid: '12345678-1234-1234-1234-123456789012',
        fileSystem: fileSystem,
      );

      final String plistContent = plistFile.readAsStringSync();
      expect(plistContent, contains('<key>teamID</key>'));
      expect(plistContent, contains('<key>signingStyle</key>'));
      expect(plistContent, contains('<string>manual</string>'));
      expect(plistContent, contains('<key>provisioningProfiles</key>'));
    });

    test('generates enhanced plist with different export methods', () async {
      final fileSystem = MemoryFileSystem.test();

      final File plistFile = await BuildIOSArchiveCommand.createExportPlistForTesting(
        exportMethod: 'ad-hoc',
        buildInfo: BuildInfo.release,
        bundleId: 'com.example.myapp',
        codeSignStyle: 'Manual',
        profileSpecifier: 'MyApp Distribution',
        teamId: 'ABC123DEF4',
        profileUuid: '12345678-1234-1234-1234-123456789012',
        fileSystem: fileSystem,
      );

      final String plistContent = plistFile.readAsStringSync();
      expect(plistContent, contains('<string>ad-hoc</string>'));
      expect(plistContent, contains('<key>teamID</key>'));
      expect(plistContent, contains('<key>signingStyle</key>'));
      expect(plistContent, contains('<string>manual</string>'));
    });

    test('handles null codeSignStyle gracefully', () async {
      final fileSystem = MemoryFileSystem.test();

      final File plistFile = await BuildIOSArchiveCommand.createExportPlistForTesting(
        exportMethod: 'app-store',
        buildInfo: BuildInfo.release,
        bundleId: 'com.example.myapp',
        fileSystem: fileSystem,
      );

      final String plistContent = plistFile.readAsStringSync();
      // Should generate simple plist when codeSignStyle is null
      expect(plistContent, contains('<key>method</key>'));
      expect(plistContent, contains('<string>app-store</string>'));
      expect(plistContent, isNot(contains('<key>teamID</key>')));
      expect(plistContent, isNot(contains('<key>signingStyle</key>')));
    });

    // TODO(mohamed): Integration test for full `flutter build ipa` flow with manual signing.
    //
    // This is currently skipped because `IosProject.buildSettingsForBuildInfo` does not
    // return mocked settings in the test harness environment. The project discovery logic
    // requires a fully-formed iOS project structure that is difficult to replicate in the
    // current hermetic test setup.
    //
    // **To implement this test, we would need:**
    // 1. A fully-formed iOS project fixture in the test environment (with proper Xcode
    //    project structure, pbxproj files, etc.)
    // 2. Mocking of the `security cms` command for profile decoding
    // 3. Proper `XcodeProjectInterpreter` mocking that returns build settings
    // 4. Integration with the full `build ipa` command execution path
    //
    // **When implemented, this test should verify:**
    // - Profile lookup integration with real provisioning profile files
    // - Full `xcodebuild -exportArchive` flow with generated plist
    // - Error handling when profile is missing or malformed
    // - Trace logging output when profile lookup fails
    // - Successful IPA generation end-to-end
    //
    // See https://github.com/flutter/flutter/issues/177853 for the feature issue.
    // Unit tests above provide sufficient coverage for the plist generation logic itself.
    test(
      'full build ipa path generates plist for manual signing (integration)',
      () {
        // Integration test skipped - see justification comment below.
      },
      // Integration test skipped because `IosProject.buildSettingsForBuildInfo` does not
      // return mocked settings in the test harness environment. The project discovery logic
      // requires a fully-formed iOS project structure that is difficult to replicate in the
      // current hermetic test setup. See TODO comment above for full requirements.
      // Unit tests above provide sufficient coverage for the plist generation logic itself.
      skip: 'Integration test requires hermetic iOS project fixture',
    );
  });
}
