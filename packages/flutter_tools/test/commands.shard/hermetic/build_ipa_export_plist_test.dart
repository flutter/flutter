// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/commands/build_ios.dart';
import 'package:flutter_tools/src/ios/application_package.dart';
import 'package:flutter_tools/src/ios/code_signing.dart';
import 'package:flutter_tools/src/project.dart';

import '../../src/common.dart';

void main() {
  group('ExportOptions.plist generation for manual signing', () {
    late FakeXcodeCodeSigningSettings fakeCodeSigningSettings;

    setUp(() {
      fakeCodeSigningSettings = FakeXcodeCodeSigningSettings();
    });

    test('generates simple plist for automatic signing', () async {
      final fileSystem = MemoryFileSystem.test();
      final command = BuildIOSArchiveCommand(logger: BufferLogger.test(), verboseHelp: false);

      final File plistFile = await command.createExportPlist(
        exportMethod: 'app-store',
        app: FakeBuildableIOSApp(FakeIosProject()),
        buildInfo: BuildInfo.release,
        buildSettings: const {'CODE_SIGN_STYLE': 'Automatic'},
        fileSystem: fileSystem,
        codeSigningSettings: fakeCodeSigningSettings,
      );

      final String plistContent = plistFile.readAsStringSync();
      expect(plistContent, contains('<key>method</key>'));
      expect(plistContent, contains('<string>app-store</string>'));
      expect(plistContent, isNot(contains('<key>teamID</key>')));
    });

    test('falls back to simple plist when profile UUID cannot be found', () async {
      final fileSystem = MemoryFileSystem.test();
      final command = BuildIOSArchiveCommand(logger: BufferLogger.test(), verboseHelp: false);

      // Even with manual signing, if we can't find a profile UUID, we fall back to simple plist
      final File plistFile = await command.createExportPlist(
        exportMethod: 'app-store',
        app: FakeBuildableIOSApp(FakeIosProject()),
        buildInfo: BuildInfo.release,
        buildSettings: const {
          'CODE_SIGN_STYLE': 'Manual',
          'DEVELOPMENT_TEAM': 'ABC123DEF4',
          'PRODUCT_BUNDLE_IDENTIFIER': 'com.example.myapp',
          'PROVISIONING_PROFILE_SPECIFIER': 'MyProfile',
        },
        fileSystem: fileSystem,
        codeSigningSettings: fakeCodeSigningSettings, // Returns null - no profile found
      );

      final String plistContent = plistFile.readAsStringSync();
      // Should fall back to simple plist when profile UUID can't be determined
      expect(plistContent, contains('<key>method</key>'));
      expect(plistContent, contains('<string>app-store</string>'));
      expect(plistContent, isNot(contains('<key>teamID</key>')));
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
        codeSigningSettings: fakeCodeSigningSettings,
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
        codeSigningSettings: fakeCodeSigningSettings,
      );

      final String plistContent = plistFile.readAsStringSync();
      expect(plistContent, contains('<key>method</key>'));
      expect(plistContent, isNot(contains('<key>teamID</key>')));
    });

    test('generates enhanced plist for manual signing when profile is found', () async {
      final fileSystem = MemoryFileSystem.test();
      final command = BuildIOSArchiveCommand(logger: BufferLogger.test(), verboseHelp: false);

      // Set up home directory path for the MemoryFileSystem
      final String homeDir = fileSystem.currentDirectory.path;
      final fakeFileSystemUtils = FakeFileSystemUtils(homeDirPath: homeDir);

      // Create the provisioning profiles directory structure in the memory filesystem.
      // _findProvisioningProfileUuid iterates over files in this directory.
      final Directory provisioningProfilesDir = fileSystem.directory(
        fileSystem.path.join(
          homeDir,
          'Library',
          'Developer',
          'Xcode',
          'UserData',
          'Provisioning Profiles',
        ),
      );
      provisioningProfilesDir.createSync(recursive: true);

      // Create a dummy provisioning profile file for the fake to "parse"
      final File dummyProfileFile = provisioningProfilesDir.childFile(
        'MyDistProfile.mobileprovision',
      );
      dummyProfileFile.writeAsStringSync('dummy content');

      // Configure fake to return a valid provisioning profile when parseProvisioningProfile is called
      final fakeWithProfile = FakeXcodeCodeSigningSettings(
        profileToReturn: ProvisioningProfile(
          filePath: dummyProfileFile.path,
          name: 'MyDistProfile',
          uuid: '12345678-1234-1234-1234-123456789012',
          teamIdentifier: 'ABC123DEF4',
          expirationDate: DateTime.now().add(const Duration(days: 365)),
          developerCertificates: <File>[],
        ),
      );

      final File plistFile = await command.createExportPlist(
        exportMethod: 'app-store',
        app: FakeBuildableIOSApp(FakeIosProject()),
        buildInfo: BuildInfo.release,
        buildSettings: const {
          'CODE_SIGN_STYLE': 'Manual',
          'DEVELOPMENT_TEAM': 'ABC123DEF4',
          'PRODUCT_BUNDLE_IDENTIFIER': 'com.example.myapp',
          'PROVISIONING_PROFILE_SPECIFIER': 'MyDistProfile',
        },
        fileSystem: fileSystem,
        codeSigningSettings: fakeWithProfile,
        fileSystemUtils: fakeFileSystemUtils,
      );

      final String plistContent = plistFile.readAsStringSync();
      // Should contain enhanced manual signing configuration
      expect(plistContent, contains('<key>method</key>'));
      expect(plistContent, contains('<string>app-store</string>'));
      expect(plistContent, contains('<key>teamID</key>'));
      expect(plistContent, contains('<string>ABC123DEF4</string>'));
      expect(plistContent, contains('<key>signingStyle</key>'));
      expect(plistContent, contains('<string>manual</string>'));
      expect(plistContent, contains('<key>provisioningProfiles</key>'));
      expect(plistContent, contains('<key>com.example.myapp</key>'));
      expect(plistContent, contains('<string>12345678-1234-1234-1234-123456789012</string>'));
    });
  });
}

// Fake implementation for testing dependency injection - simplified without Fake base class
class FakeXcodeCodeSigningSettings implements XcodeCodeSigningSettings {
  FakeXcodeCodeSigningSettings({this.profileToReturn});

  final ProvisioningProfile? profileToReturn;

  @override
  Future<ProvisioningProfile?> parseProvisioningProfile(File provisioningProfileFile) async {
    return profileToReturn;
  }

  @override
  Future<void> selectSettings() async {
    // No-op for test cases - no interactive selection needed
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeIosProject implements IosProject {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeBuildableIOSApp implements BuildableIOSApp {
  FakeBuildableIOSApp(this.project);

  @override
  final IosProject project;

  @override
  String get id => 'com.example.app';

  @override
  String get name => 'app';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFileSystemUtils implements FileSystemUtils {
  FakeFileSystemUtils({this.homeDirPath});

  @override
  final String? homeDirPath;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
