// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_ipa.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';

import '../../src/common.dart';
import '../../src/context.dart';

class FakeXcodeProjectInterpreterWithBuildSettings
    extends FakeXcodeProjectInterpreter {
  @override
  Future<Map<String, String>> getBuildSettings(
    String projectPath, {
    String scheme,
    Duration timeout = const Duration(minutes: 1),
  }) async {
    return <String, String>{
      'PRODUCT_BUNDLE_IDENTIFIER': 'io.flutter.someProject',
    };
  }
}

void main() {
  FakePlatform platform;
  FakeXcodeProjectInterpreterWithBuildSettings xcodeProjectInterpreter;
  FileSystem fileSystem;
  BufferLogger logger;
  File exportOptions;

  setUp(() {
    Cache.disableLocking();
    platform = FakePlatform(
      operatingSystem: 'macos',
      environment: <String, String>{
        'FLUTTER_ROOT': '/',
      },
    );
    xcodeProjectInterpreter = FakeXcodeProjectInterpreterWithBuildSettings();
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    exportOptions = fileSystem.file('ExportOptions.plist');
    fileSystem.file('pubspec.yaml').createSync();
  });

  testUsingContext('validates macOS', () async {
    final BuildIPACommand command = BuildIPACommand(
      platform: FakePlatform(operatingSystem: 'linux'),
      xcodeProjectInterpreter: xcodeProjectInterpreter,
      fileSystem: fileSystem,
      logger: logger,
      processManager: FakeProcessManager.any(),
    );

    await expectToolExitLater(
      createTestCommandRunner(command).run(<String>['ipa']),
      equals('Building for iOS is only supported on macOS.'),
    );
  }, overrides: <Type, Generator>{
    Platform: () => platform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Logger: () => logger,
    XcodeProjectInterpreter: () => xcodeProjectInterpreter,
  });

  testUsingContext('validates export plist', () async {
    final BuildIPACommand command = BuildIPACommand(
      platform: platform,
      xcodeProjectInterpreter: xcodeProjectInterpreter,
      fileSystem: fileSystem,
      logger: logger,
      processManager: FakeProcessManager.any(),
    );

    await expectToolExitLater(
      createTestCommandRunner(command).run(<String>['ipa']),
      contains('--export-options-plist file is required.'),
    );
  }, overrides: <Type, Generator>{
    Platform: () => platform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Logger: () => logger,
    XcodeProjectInterpreter: () => xcodeProjectInterpreter,
  });

  testUsingContext('validates export plist exists', () async {
    final BuildIPACommand command = BuildIPACommand(
      platform: platform,
      xcodeProjectInterpreter: xcodeProjectInterpreter,
      fileSystem: fileSystem,
      logger: logger,
      processManager: FakeProcessManager.any(),
    );

    await expectToolExitLater(
      createTestCommandRunner(command)
          .run(<String>['ipa', '--export-options-plist', 'bogus.plist']),
      contains('property list does not exist'),
    );
  }, overrides: <Type, Generator>{
    Platform: () => platform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Logger: () => logger,
    XcodeProjectInterpreter: () => xcodeProjectInterpreter,
  });

  testUsingContext('validates export plist is file', () async {
    final Directory bogus = fileSystem.directory('bogus')..createSync();
    final BuildIPACommand command = BuildIPACommand(
      platform: platform,
      xcodeProjectInterpreter: xcodeProjectInterpreter,
      fileSystem: fileSystem,
      logger: logger,
      processManager: FakeProcessManager.any(),
    );

    await expectToolExitLater(
      createTestCommandRunner(command)
          .run(<String>['ipa', '--export-options-plist', bogus.path]),
      contains('is not a file.'),
    );
  }, overrides: <Type, Generator>{
    Platform: () => platform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Logger: () => logger,
    XcodeProjectInterpreter: () => xcodeProjectInterpreter,
  });

  testUsingContext('validates Xcode installed', () async {
    exportOptions.createSync();
    xcodeProjectInterpreter.isInstalled = false;
    final BuildIPACommand command = BuildIPACommand(
      platform: platform,
      xcodeProjectInterpreter: xcodeProjectInterpreter,
      fileSystem: fileSystem,
      logger: logger,
      processManager: FakeProcessManager.any(),
    );
    await expectToolExitLater(
      createTestCommandRunner(command)
          .run(<String>['ipa', '--export-options-plist', exportOptions.path]),
      equals('Cannot find "xcodebuild". Run "flutter doctor".'),
    );
  }, overrides: <Type, Generator>{
    Platform: () => platform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Logger: () => logger,
    XcodeProjectInterpreter: () => xcodeProjectInterpreter,
  });

  testUsingContext('validates iOS project', () async {
    exportOptions.createSync();
    final BuildIPACommand command = BuildIPACommand(
      platform: platform,
      xcodeProjectInterpreter: xcodeProjectInterpreter,
      fileSystem: fileSystem,
      logger: logger,
      processManager: FakeProcessManager.any(),
    );

    await expectToolExitLater(
      createTestCommandRunner(command)
          .run(<String>['ipa', '--export-options-plist', exportOptions.path]),
      equals('Application not configured for iOS.'),
    );
  }, overrides: <Type, Generator>{
    Platform: () => platform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Logger: () => logger,
    XcodeProjectInterpreter: () => xcodeProjectInterpreter,
  });

  group('with iOS project', () {
    setUp(() {
      exportOptions.createSync();
      fileSystem
          .directory(fileSystem.path.join('ios', 'Runner.xcodeproj'))
          .createSync(recursive: true);
      fileSystem
          .directory(fileSystem.path.join('ios', 'Runner.xcworkspace'))
          .createSync(recursive: true);
      fileSystem
          .file(fileSystem.path
              .join('ios', 'Runner.xcodeproj', 'project.pbxproj'))
          .createSync();
      fileSystem.file('.packages').createSync();
      fileSystem
          .file(fileSystem.path.join('lib', 'main.dart'))
          .createSync(recursive: true);
    });

    testUsingContext('validates xcarchive present', () async {
      final BuildIPACommand command = BuildIPACommand(
        platform: platform,
        xcodeProjectInterpreter: xcodeProjectInterpreter,
        fileSystem: fileSystem,
        logger: logger,
        processManager: FakeProcessManager.any(),
      );

      await expectToolExitLater(
        createTestCommandRunner(command)
            .run(<String>['ipa', '--export-options-plist', exportOptions.path]),
        contains('xcarchive not found'),
      );
    }, overrides: <Type, Generator>{
      Platform: () => platform,
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Logger: () => logger,
      XcodeProjectInterpreter: () => xcodeProjectInterpreter,
    });

    group('with xcarchive', () {
      Directory xcarchivePath;
      String outputPath;
      setUp(() {
        xcarchivePath = fileSystem.directory(
            fileSystem.path.join('build', 'ios', 'archive', 'Runner.xcarchive'))
          ..createSync(recursive: true);
        outputPath = fileSystem.path
            .absolute(fileSystem.path.join('build', 'ios', 'ipa'));
      });

      testUsingContext('shows xcodebuild error on failure', () async {
        final FakeProcessManager processManager =
            FakeProcessManager.list(<FakeCommand>[
          FakeCommand(
            command: <String>[
              'xcrun',
              'xcodebuild',
              '-exportArchive',
              '-archivePath',
              fileSystem.path.absolute(xcarchivePath.path),
              '-exportPath',
              outputPath,
              '-exportOptionsPlist',
              exportOptions.path,
            ],
            stderr:
                'error: exportArchive: exportOptionsPlist error for key "method": expected one of {app-store, ad-hoc, enterprise, development, validation}, but found developmentasdasd\n'
                ' Error Domain=IDEFoundationErrorDomain Code=1 "exportOptionsPlist error for key "method": expected one of {app-store, ad-hoc, enterprise, development, validation}, but found developmentasdasd"',
            exitCode: 70,
          ),
        ]);

        final BuildIPACommand command = BuildIPACommand(
          platform: platform,
          xcodeProjectInterpreter: xcodeProjectInterpreter,
          fileSystem: fileSystem,
          logger: logger,
          processManager: processManager,
        );

        await expectToolExitLater(
          createTestCommandRunner(command).run(
              <String>['ipa', '--export-options-plist', exportOptions.path]),
          allOf(
              contains(
                  'error: exportArchive: exportOptionsPlist error for key "method"'),
              isNot(contains('Error Domain=IDEFoundationErrorDomain'))),
        );
        expect(processManager.hasRemainingExpectations, isFalse);
      }, overrides: <Type, Generator>{
        Platform: () => platform,
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Logger: () => logger,
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });

      testUsingContext('shows output directory on success', () async {
        final FakeProcessManager processManager =
            FakeProcessManager.list(<FakeCommand>[
          FakeCommand(
            command: <String>[
              'xcrun',
              'xcodebuild',
              '-exportArchive',
              '-archivePath',
              fileSystem.path.absolute(xcarchivePath.path),
              '-exportPath',
              fileSystem.path.absolute(outputPath),
              '-exportOptionsPlist',
              exportOptions.path,
            ],
          ),
        ]);

        final BuildIPACommand command = BuildIPACommand(
          platform: platform,
          xcodeProjectInterpreter: xcodeProjectInterpreter,
          fileSystem: fileSystem,
          logger: logger,
          processManager: processManager,
        );

        await createTestCommandRunner(command)
            .run(<String>['ipa', '--export-options-plist', exportOptions.path]);
        expect(logger.statusText, contains('Built IPA to $outputPath.'));
        expect(processManager.hasRemainingExpectations, isFalse);
      }, overrides: <Type, Generator>{
        Platform: () => platform,
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Logger: () => logger,
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
      });
    });
  });
}
