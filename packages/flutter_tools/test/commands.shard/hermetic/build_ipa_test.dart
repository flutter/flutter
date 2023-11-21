// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/commands/build_ios.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:test/fake.dart';

import '../../general.shard/ios/xcresult_test_data.dart';
import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';
import '../../src/test_build_system.dart';
import '../../src/test_flutter_command_runner.dart';

class FakeXcodeProjectInterpreterWithBuildSettings extends FakeXcodeProjectInterpreter {
  FakeXcodeProjectInterpreterWithBuildSettings({ this.overrides = const <String, String>{} });

  final Map<String, String> overrides;

  @override
  Future<Map<String, String>> getBuildSettings(
      String projectPath, {
        XcodeProjectBuildContext? buildContext,
        Duration timeout = const Duration(minutes: 1),
      }) async {
    return <String, String>{
      ...overrides,
      'PRODUCT_BUNDLE_IDENTIFIER': 'io.flutter.someProject',
      'DEVELOPMENT_TEAM': 'abc',
    };
  }
}

final Platform macosPlatform = FakePlatform(
  operatingSystem: 'macos',
  environment: <String, String>{
    'FLUTTER_ROOT': '/',
    'HOME': '/',
  }
);
final Platform notMacosPlatform = FakePlatform(
  environment: <String, String>{
    'FLUTTER_ROOT': '/',
  }
);

class FakePlistUtils extends Fake implements PlistParser {
  final Map<String, Map<String, Object>> fileContents = <String, Map<String, Object>>{};

  @override
  T? getValueFromFile<T>(String plistFilePath, String key) {
    final Map<String, Object>? plistFile = fileContents[plistFilePath];
    return plistFile == null ? null : plistFile[key] as T?;
  }
}

void main() {
  late FileSystem fileSystem;
  late TestUsage usage;
  late FakeProcessManager fakeProcessManager;
  late FakePlistUtils plistUtils;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    usage = TestUsage();
    fakeProcessManager = FakeProcessManager.empty();
    plistUtils = FakePlistUtils();
  });

  // Sets up the minimal mock project files necessary to look like a Flutter project.
  void createCoreMockProjectFiles() {
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.packages').createSync();
    fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
  }

  // Sets up the minimal mock project files necessary for iOS builds to succeed.
  void createMinimalMockProjectFiles() {
    fileSystem.directory(fileSystem.path.join('ios', 'Runner.xcodeproj')).createSync(recursive: true);
    fileSystem.directory(fileSystem.path.join('ios', 'Runner.xcworkspace')).createSync(recursive: true);
    fileSystem.file(fileSystem.path.join('ios', 'Runner.xcodeproj', 'project.pbxproj')).createSync();
    final String packageConfigPath = '${Cache.flutterRoot!}/packages/flutter_tools/.dart_tool/package_config.json';
    fileSystem.file(packageConfigPath)
      ..createSync(recursive: true)
      ..writeAsStringSync('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "flutter_template_images",
      "rootUri": "/flutter_template_images",
      "packageUri": "lib/",
      "languageVersion": "2.12"
    }
  ]
}
''');
    createCoreMockProjectFiles();
  }

  const FakeCommand xattrCommand = FakeCommand(command: <String>[
    'xattr', '-r', '-d', 'com.apple.FinderInfo', '/',
  ]);

  FakeCommand setUpXCResultCommand({String stdout = '', void Function()? onRun}) {
    return FakeCommand(
      command: const <String>[
        'xcrun',
        'xcresulttool',
        'get',
        '--path',
        _xcBundleFilePath,
        '--format',
        'json',
      ],
      stdout: stdout,
      onRun: onRun,
    );
  }

  // Creates a FakeCommand for the xcodebuild call to build the app
  // in the given configuration.
  FakeCommand setUpFakeXcodeBuildHandler({ bool verbose = false, int exitCode = 0, void Function()? onRun }) {
    return FakeCommand(
      command: <String>[
        'xcrun',
        'xcodebuild',
        '-configuration', 'Release',
        if (verbose)
          'VERBOSE_SCRIPT_LOGGING=YES'
        else
          '-quiet',
        '-workspace', 'Runner.xcworkspace',
        '-scheme', 'Runner',
        '-sdk', 'iphoneos',
        '-destination',
        'generic/platform=iOS',
        '-resultBundlePath', '/.tmp_rand0/flutter_ios_build_temp_dirrand0/temporary_xcresult_bundle',
        '-resultBundleVersion', '3',
        'FLUTTER_SUPPRESS_ANALYTICS=true',
        'COMPILER_INDEX_STORE_ENABLE=NO',
        '-archivePath', '/build/ios/archive/Runner',
        'archive',
      ],
      stdout: 'STDOUT STUFF',
      exitCode: exitCode,
      onRun: onRun,
    );
  }

  FakeCommand exportArchiveCommand({
    String exportOptionsPlist =  '/ExportOptions.plist',
    File? cachePlist,
    bool deleteExportOptionsPlist = false,
  }) {
    return FakeCommand(
      command: <String>[
        'xcrun',
        'xcodebuild',
        '-exportArchive',
        '-allowProvisioningDeviceRegistration',
        '-allowProvisioningUpdates',
        '-archivePath',
        '/build/ios/archive/Runner.xcarchive',
        '-exportPath',
        '/build/ios/ipa',
        '-exportOptionsPlist',
        exportOptionsPlist,
      ],
      onRun: () {
        // exportOptionsPlist will be cleaned up within the command.
        // Save it somewhere else so test expectations can be run on it.
        if (cachePlist != null) {
          cachePlist.writeAsStringSync(fileSystem.file(_exportOptionsPlist).readAsStringSync());
        }
        if (deleteExportOptionsPlist) {
          fileSystem.file(_exportOptionsPlist).deleteSync();
        }
      }
    );
  }

  testUsingContext('ipa build fails when there is no ios project', () async {
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    createCoreMockProjectFiles();

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'ipa', '--no-pub']
    ), throwsToolExit(message: 'Application not configured for iOS'));
  }, overrides: <Type, Generator>{
    Platform: () => macosPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ipa build fails in debug with code analysis', () async {
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    createCoreMockProjectFiles();

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'ipa', '--no-pub', '--debug', '--analyze-size']
    ), throwsToolExit(message: '--analyze-size" can only be used on release builds'));
  }, overrides: <Type, Generator>{
    Platform: () => macosPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ipa build fails on non-macOS platform', () async {
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.packages').createSync();
    fileSystem.file(fileSystem.path.join('lib', 'main.dart'))
      .createSync(recursive: true);

    final bool supported = BuildIOSArchiveCommand(logger: BufferLogger.test(), verboseHelp: false).supported;
    expect(createTestCommandRunner(command).run(
      const <String>['build', 'ipa', '--no-pub']
    ), supported ? throwsToolExit() : throwsA(isA<UsageException>()));
  }, overrides: <Type, Generator>{
    Platform: () => notMacosPlatform,
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ipa build fails when export plist does not exist',
      () async {
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    createMinimalMockProjectFiles();

    await expectToolExitLater(
      createTestCommandRunner(command).run(<String>[
        'build',
        'ipa',
        '--export-options-plist',
        'bogus.plist',
        '--no-pub',
      ]),
      contains('property list does not exist'),
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () =>
        FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ipa build fails when export plist is not a file', () async {
    final Directory bogus = fileSystem.directory('bogus')..createSync();
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    createMinimalMockProjectFiles();

    await expectToolExitLater(
      createTestCommandRunner(command).run(<String>[
        'build',
        'ipa',
        '--export-options-plist',
        bogus.path,
        '--no-pub',
      ]),
      contains('is not a file.'),
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ipa build fails when --export-options-plist and --export-method are used together', () async {
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    createMinimalMockProjectFiles();

    await expectToolExitLater(
      createTestCommandRunner(command).run(<String>[
        'build',
        'ipa',
        '--export-options-plist',
        'ExportOptions.plist',
        '--export-method',
        'app-store',
        '--no-pub',
      ]),
      contains('"--export-options-plist" is not compatible with "--export-method"'),
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ipa build reports when IPA fails', () async {
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(),
      const FakeCommand(
        command: <String>[
          'xcrun',
          'xcodebuild',
          '-exportArchive',
          '-allowProvisioningDeviceRegistration',
          '-allowProvisioningUpdates',
          '-archivePath',
          '/build/ios/archive/Runner.xcarchive',
          '-exportPath',
          '/build/ios/ipa',
          '-exportOptionsPlist',
          _exportOptionsPlist,
        ],
        exitCode: 1,
        stderr: 'error: exportArchive: "Runner.app" requires a provisioning profile.',
      ),
    ]);
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>['build', 'ipa', '--no-pub']
    );

    expect(testLogger.statusText, contains('build/ios/archive/Runner.xcarchive'));
    expect(testLogger.statusText, contains('Building App Store IPA'));
    expect(testLogger.errorText, contains('Encountered error while creating the IPA:'));
    expect(testLogger.errorText, contains('error: exportArchive: "Runner.app" requires a provisioning profile.'));
    expect(fakeProcessManager, hasNoRemainingExpectations);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ipa build ignores deletion failure if generatedExportPlist does not exist', () async {
    final File cachedExportOptionsPlist = fileSystem.file('/CachedExportOptions.plist');
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      logger: BufferLogger.test(),
      fileSystem: fileSystem,
      osUtils: FakeOperatingSystemUtils(),
    );
    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(),
      exportArchiveCommand(
        exportOptionsPlist: _exportOptionsPlist,
        cachePlist: cachedExportOptionsPlist,
        deleteExportOptionsPlist: true,
      ),
    ]);
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>['build', 'ipa', '--no-pub']
    );
    expect(fakeProcessManager, hasNoRemainingExpectations);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ipa build invokes xcodebuild and archives for app store', () async {
    final File cachedExportOptionsPlist = fileSystem.file('/CachedExportOptions.plist');
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(),
      exportArchiveCommand(exportOptionsPlist: _exportOptionsPlist, cachePlist: cachedExportOptionsPlist),
    ]);
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>['build', 'ipa', '--no-pub']
    );

    const String expectedIpaPlistContents = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>method</key>
        <string>app-store</string>
        <key>uploadBitcode</key>
        <false/>
    </dict>
</plist>
''';

    final String actualIpaPlistContents = fileSystem.file(cachedExportOptionsPlist).readAsStringSync();
    expect(actualIpaPlistContents, expectedIpaPlistContents);

    expect(testLogger.statusText, contains('build/ios/archive/Runner.xcarchive'));
    expect(testLogger.statusText, contains('Building App Store IPA'));
    expect(testLogger.statusText, contains('Built IPA to /build/ios/ipa'));
    expect(testLogger.statusText, contains('To upload to the App Store'));
    expect(testLogger.statusText, contains('Apple Transporter macOS app'));
    expect(fakeProcessManager, hasNoRemainingExpectations);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ipa build invokes xcodebuild and archives for ad-hoc distribution', () async {
    final File cachedExportOptionsPlist = fileSystem.file('/CachedExportOptions.plist');
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(),
      exportArchiveCommand(exportOptionsPlist: _exportOptionsPlist, cachePlist: cachedExportOptionsPlist),
    ]);
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
        const <String>['build', 'ipa', '--no-pub', '--export-method', 'ad-hoc']
    );

    const String expectedIpaPlistContents = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>method</key>
        <string>ad-hoc</string>
        <key>uploadBitcode</key>
        <false/>
    </dict>
</plist>
''';

    final String actualIpaPlistContents = fileSystem.file(cachedExportOptionsPlist).readAsStringSync();
    expect(actualIpaPlistContents, expectedIpaPlistContents);

    expect(testLogger.statusText, contains('build/ios/archive/Runner.xcarchive'));
    expect(testLogger.statusText, contains('Building ad-hoc IPA'));
    expect(testLogger.statusText, contains('Built IPA to /build/ios/ipa'));
    // Don't instruct how to upload to the App Store.
    expect(testLogger.statusText, isNot(contains('To upload')));
    expect(fakeProcessManager, hasNoRemainingExpectations);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ipa build invokes xcodebuild and archives for enterprise distribution', () async {
    final File cachedExportOptionsPlist = fileSystem.file('/CachedExportOptions.plist');
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(),
      exportArchiveCommand(exportOptionsPlist: _exportOptionsPlist, cachePlist: cachedExportOptionsPlist),
    ]);
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
        const <String>['build', 'ipa', '--no-pub', '--export-method', 'enterprise']
    );

    const String expectedIpaPlistContents = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>method</key>
        <string>enterprise</string>
        <key>uploadBitcode</key>
        <false/>
    </dict>
</plist>
''';

    final String actualIpaPlistContents = fileSystem.file(cachedExportOptionsPlist).readAsStringSync();
    expect(actualIpaPlistContents, expectedIpaPlistContents);

    expect(testLogger.statusText, contains('build/ios/archive/Runner.xcarchive'));
    expect(testLogger.statusText, contains('Building enterprise IPA'));
    expect(testLogger.statusText, contains('Built IPA to /build/ios/ipa'));
    // Don't instruct how to upload to the App Store.
    expect(testLogger.statusText, isNot(contains('To upload')));
    expect(fakeProcessManager, hasNoRemainingExpectations);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ipa build invokes xcode build with verbosity', () async {
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(verbose: true),
      exportArchiveCommand(exportOptionsPlist: _exportOptionsPlist),
    ]);
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>['build', 'ipa', '--no-pub', '-v']
    );
    expect(fakeProcessManager, hasNoRemainingExpectations);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ipa build --no-codesign skips codesigning and IPA creation', () async {
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      const FakeCommand(
        command: <String>[
          'xcrun',
          'xcodebuild',
          '-configuration', 'Release',
          '-quiet',
          '-workspace', 'Runner.xcworkspace',
          '-scheme', 'Runner',
          '-sdk', 'iphoneos',
          '-destination',
          'generic/platform=iOS',
          'CODE_SIGNING_ALLOWED=NO',
          'CODE_SIGNING_REQUIRED=NO',
          'CODE_SIGNING_IDENTITY=""',
          '-resultBundlePath',
          '/.tmp_rand0/flutter_ios_build_temp_dirrand0/temporary_xcresult_bundle',
          '-resultBundleVersion', '3',
          'FLUTTER_SUPPRESS_ANALYTICS=true',
          'COMPILER_INDEX_STORE_ENABLE=NO',
          '-archivePath',
          '/build/ios/archive/Runner',
          'archive',
        ],
      ),
    ]);
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      const <String>['build', 'ipa', '--no-pub', '--no-codesign']
    );
    expect(fakeProcessManager, hasNoRemainingExpectations);
    expect(testLogger.statusText, contains('Codesigning disabled with --no-codesign, skipping IPA'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('code size analysis fails when app not found', () async {
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    createMinimalMockProjectFiles();

    await expectToolExitLater(
      createTestCommandRunner(command).run(
          const <String>['build', 'ipa', '--no-pub', '--analyze-size']
      ),
      contains('Could not find app to analyze code size'),
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('Performs code size analysis and sends analytics', () async {
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    createMinimalMockProjectFiles();

    fileSystem.file('build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app/Frameworks/App.framework/App')
      ..createSync(recursive: true)
      ..writeAsBytesSync(List<int>.generate(10000, (int index) => 0));
    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(onRun: () {
        fileSystem.file('build/flutter_size_01/snapshot.arm64.json')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
[
  {
    "l": "dart:_internal",
    "c": "SubListIterable",
    "n": "[Optimized] skip",
    "s": 2400
  }
]''');
        fileSystem.file('build/flutter_size_01/trace.arm64.json')
          ..createSync(recursive: true)
          ..writeAsStringSync('{}');
      }),
      exportArchiveCommand(exportOptionsPlist: _exportOptionsPlist),
    ]);

    await createTestCommandRunner(command).run(
      const <String>['build', 'ipa', '--no-pub', '--analyze-size']
    );

    expect(testLogger.statusText, contains('A summary of your iOS bundle analysis can be found at'));
    expect(testLogger.statusText, contains('dart devtools --appSizeBase='));
    expect(usage.events, contains(
      const TestUsageEvent('code-size-analysis', 'ios'),
    ));
    expect(fakeProcessManager, hasNoRemainingExpectations);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    FileSystemUtils: () => FileSystemUtils(fileSystem: fileSystem, platform: macosPlatform),
    Usage: () => usage,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('ipa build invokes xcode build export archive when passed plist', () async {
    final String outputPath =
        fileSystem.path.absolute(fileSystem.path.join('build', 'ios', 'ipa'));
    final File exportOptions = fileSystem.file('ExportOptions.plist')
      ..createSync();
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(),
      exportArchiveCommand(),
    ]);
    createMinimalMockProjectFiles();

    await createTestCommandRunner(command).run(
      <String>[
        'build',
        'ipa',
        '--no-pub',
        '--export-options-plist',
        exportOptions.path,
      ],
    );

    expect(testLogger.statusText, contains('Built IPA to $outputPath.'));
    expect(fakeProcessManager, hasNoRemainingExpectations);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('Trace error if xcresult is empty.', () async {
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(exitCode: 1, onRun: () {
        fileSystem.systemTempDirectory.childDirectory(_xcBundleFilePath).createSync();
      }),
      setUpXCResultCommand(),
    ]);
    createMinimalMockProjectFiles();

    await expectLater(
      createTestCommandRunner(command).run(const <String>['build', 'ipa', '--no-pub']),
      throwsToolExit(),
    );

    expect(testLogger.traceText, contains('xcresult parser: Unrecognized top level json format.'));
    expect(fakeProcessManager, hasNoRemainingExpectations);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('Display xcresult issues on console if parsed.', () async {
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(exitCode: 1, onRun: () {
        fileSystem.systemTempDirectory.childDirectory(_xcBundleFilePath).createSync();
      }),
      setUpXCResultCommand(stdout: kSampleResultJsonWithIssues),
    ]);
    createMinimalMockProjectFiles();

    await expectLater(
      createTestCommandRunner(command).run(const <String>['build', 'ipa', '--no-pub']),
      throwsToolExit(),
    );

    expect(testLogger.errorText, contains("Use of undeclared identifier 'asdas'"));
    expect(testLogger.errorText, contains('/Users/m/Projects/test_create/ios/Runner/AppDelegate.m:7:56'));
    expect(fakeProcessManager, hasNoRemainingExpectations);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('Do not display xcresult issues that needs to be discarded.', () async {
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(exitCode: 1, onRun: () {
        fileSystem.systemTempDirectory.childDirectory(_xcBundleFilePath).createSync();
      }),
      setUpXCResultCommand(stdout: kSampleResultJsonWithIssuesToBeDiscarded),
    ]);
    createMinimalMockProjectFiles();

    await expectLater(
      createTestCommandRunner(command).run(const <String>['build', 'ipa', '--no-pub']),
      throwsToolExit(),
    );

    expect(testLogger.errorText, contains("Use of undeclared identifier 'asdas'"));
    expect(testLogger.errorText, contains('/Users/m/Projects/test_create/ios/Runner/AppDelegate.m:7:56'));
    expect(testLogger.errorText, isNot(contains('Command PhaseScriptExecution failed with a nonzero exit code')));
    expect(testLogger.warningText, isNot(contains("The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 8.0, but the range of supported deployment target versions is 9.0 to 14.0.99.")));
    expect(fakeProcessManager, hasNoRemainingExpectations);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('Trace if xcresult bundle does not exist.', () async {
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(exitCode: 1),
    ]);
    createMinimalMockProjectFiles();

    await expectLater(
      createTestCommandRunner(command).run(const <String>['build', 'ipa', '--no-pub']),
      throwsToolExit(),
    );

    expect(testLogger.traceText, contains('The xcresult bundle are not generated. Displaying xcresult is disabled.'));
    expect(fakeProcessManager, hasNoRemainingExpectations);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });


  testUsingContext('Extra error message for provision profile issue in xcresulb bundle.', () async {
    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(exitCode: 1, onRun: () {
        fileSystem.systemTempDirectory.childDirectory(_xcBundleFilePath).createSync();
      }),
      setUpXCResultCommand(stdout: kSampleResultJsonWithProvisionIssue),
    ]);
    createMinimalMockProjectFiles();

    await expectLater(
      createTestCommandRunner(command).run(const <String>['build', 'ipa', '--no-pub']),
      throwsToolExit(),
    );

    expect(testLogger.errorText, contains('Some Provisioning profile issue.'));
    expect(testLogger.errorText, contains('It appears that there was a problem signing your application prior to installation on the device.'));
    expect(testLogger.errorText, contains('Verify that the Bundle Identifier in your project is your signing id in Xcode'));
    expect(testLogger.errorText, contains('open ios/Runner.xcworkspace'));
    expect(testLogger.errorText, contains("Also try selecting 'Product > Build' to fix the problem."));
    expect(fakeProcessManager, hasNoRemainingExpectations);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext(
      'Validate basic Xcode settings with missing settings', () async {

    const String plistPath = 'build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app/Info.plist';
    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(onRun: () {
        fileSystem.file(plistPath).createSync(recursive: true);
      }),
      exportArchiveCommand(exportOptionsPlist: _exportOptionsPlist),
    ]);

    createMinimalMockProjectFiles();

    plistUtils.fileContents[plistPath] = <String,String>{
      'CFBundleIdentifier': 'io.flutter.someProject',
    };

    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    await createTestCommandRunner(command).run(
        <String>['build', 'ipa', '--no-pub']);

    expect(
      testLogger.statusText,
      contains(
        '[!] App Settings Validation\n'
        '    ! Version Number: Missing\n'
        '    ! Build Number: Missing\n'
        '    ! Display Name: Missing\n'
        '    ! Deployment Target: Missing\n'
        '    • Bundle Identifier: io.flutter.someProject\n'
        '    ! You must set up the missing app settings.\n'
    ));
    expect(
      testLogger.statusText,
      contains('To update the settings, please refer to https://docs.flutter.dev/deployment/ios')
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    PlistParser: () => plistUtils,
  });

  testUsingContext(
      'Validate basic Xcode settings with full settings', () async {
    const String plistPath = 'build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app/Info.plist';
    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(onRun: () {
        fileSystem.file(plistPath).createSync(recursive: true);
      }),
      exportArchiveCommand(exportOptionsPlist: _exportOptionsPlist),
    ]);

    createMinimalMockProjectFiles();

    plistUtils.fileContents[plistPath] = <String,String>{
      'CFBundleIdentifier': 'io.flutter.someProject',
      'CFBundleDisplayName': 'Awesome Gallery',
      // Will not use CFBundleName since CFBundleDisplayName is present.
      'CFBundleName': 'Awesome Gallery 2',
      'MinimumOSVersion': '11.0',
      'CFBundleVersion': '666',
      'CFBundleShortVersionString': '12.34.56',
    };

    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    await createTestCommandRunner(command).run(
        <String>['build', 'ipa', '--no-pub']);

    expect(
      testLogger.statusText,
      contains(
        '[✓] App Settings Validation\n'
        '    • Version Number: 12.34.56\n'
        '    • Build Number: 666\n'
        '    • Display Name: Awesome Gallery\n'
        '    • Deployment Target: 11.0\n'
        '    • Bundle Identifier: io.flutter.someProject\n'
      )
    );
    expect(
      testLogger.statusText,
      contains('To update the settings, please refer to https://docs.flutter.dev/deployment/ios')
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    PlistParser: () => plistUtils,
  });

  testUsingContext(
      'Validate basic Xcode settings with CFBundleDisplayName fallback to CFBundleName', () async {
    const String plistPath = 'build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app/Info.plist';
    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(onRun: () {
        fileSystem.file(plistPath).createSync(recursive: true);
      }),
      exportArchiveCommand(exportOptionsPlist: _exportOptionsPlist),
    ]);

    createMinimalMockProjectFiles();

    plistUtils.fileContents[plistPath] = <String,String>{
      'CFBundleIdentifier': 'io.flutter.someProject',
      // Will use CFBundleName since CFBundleDisplayName is absent.
      'CFBundleName': 'Awesome Gallery',
      'MinimumOSVersion': '11.0',
      'CFBundleVersion': '666',
      'CFBundleShortVersionString': '12.34.56',
    };

    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    await createTestCommandRunner(command).run(
        <String>['build', 'ipa', '--no-pub']);

    expect(
        testLogger.statusText,
        contains(
            '[✓] App Settings Validation\n'
            '    • Version Number: 12.34.56\n'
            '    • Build Number: 666\n'
            '    • Display Name: Awesome Gallery\n'
            '    • Deployment Target: 11.0\n'
            '    • Bundle Identifier: io.flutter.someProject\n'
        )
    );
    expect(
        testLogger.statusText,
        contains('To update the settings, please refer to https://docs.flutter.dev/deployment/ios')
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    PlistParser: () => plistUtils,
  });


  testUsingContext(
      'Validate basic Xcode settings with default bundle identifier prefix', () async {
    const String plistPath = 'build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app/Info.plist';
    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(onRun: () {
        fileSystem.file(plistPath).createSync(recursive: true);
      }),
      exportArchiveCommand(exportOptionsPlist: _exportOptionsPlist),
    ]);

    createMinimalMockProjectFiles();

    plistUtils.fileContents[plistPath] = <String,String>{
      'CFBundleIdentifier': 'com.example.my_app',
    };

    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    await createTestCommandRunner(command).run(
        <String>['build', 'ipa', '--no-pub']);

    expect(
      testLogger.statusText,
      contains('    ! Your application still contains the default "com.example" bundle identifier.')
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    PlistParser: () => plistUtils,
  });

  testUsingContext(
      'Validate basic Xcode settings with custom bundle identifier prefix', () async {
    const String plistPath = 'build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app/Info.plist';
    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(onRun: () {
        fileSystem.file(plistPath).createSync(recursive: true);
      }),
      exportArchiveCommand(exportOptionsPlist: _exportOptionsPlist),
    ]);

    createMinimalMockProjectFiles();

    plistUtils.fileContents[plistPath] = <String,String>{
      'CFBundleIdentifier': 'com.my_company.my_app',
    };

    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    await createTestCommandRunner(command).run(
        <String>['build', 'ipa', '--no-pub']);

    expect(
      testLogger.statusText,
      isNot(contains('    ! Your application still contains the default "com.example" bundle identifier.'))
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
    PlistParser: () => plistUtils,
  });


  testUsingContext('Validate template app icons with conflicts', () async {
    const String projectIconContentsJsonPath = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json';
    const String projectIconImagePath = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png';
    final String templateIconContentsJsonPath = '${Cache.flutterRoot!}/packages/flutter_tools/templates/app_shared/ios.tmpl/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json';
    const String templateIconImagePath = '/flutter_template_images/templates/app_shared/ios.tmpl/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png';

    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(onRun: () {
        fileSystem.file(templateIconContentsJsonPath)
        ..createSync(recursive: true)
        ..writeAsStringSync('''
{
  "images": [
    {
      "size": "20x20",
      "idiom": "iphone",
      "filename": "Icon-App-20x20@2x.png",
      "scale": "2x"
    }
  ],
  "info": {
    "version": 1,
    "author": "xcode"
  }
}
''');
        fileSystem.file(templateIconImagePath)
        ..createSync(recursive: true)
        ..writeAsBytes(<int>[1, 2, 3]);

        fileSystem.file(projectIconContentsJsonPath)
            ..createSync(recursive: true)
            ..writeAsStringSync('''
{
  "images": [
    {
      "size": "20x20",
      "idiom": "iphone",
      "filename": "Icon-App-20x20@2x.png",
      "scale": "2x"
    }
  ],
  "info": {
    "version": 1,
    "author": "xcode"
  }
}
''');
        fileSystem.file(projectIconImagePath)
            ..createSync(recursive: true)
            ..writeAsBytes(<int>[1, 2, 3]);
      }),
      exportArchiveCommand(exportOptionsPlist: _exportOptionsPlist),
    ]);

    createMinimalMockProjectFiles();

    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    await createTestCommandRunner(command).run(
        <String>['build', 'ipa', '--no-pub']);

    expect(
      testLogger.statusText,
      contains('    ! App icon is set to the default placeholder icon. Replace with unique icons.'),
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('Validate template app icons without conflicts', () async {
    const String projectIconContentsJsonPath = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json';
    const String projectIconImagePath = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png';
    final String templateIconContentsJsonPath = '${Cache.flutterRoot!}/packages/flutter_tools/templates/app_shared/ios.tmpl/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json';
    const String templateIconImagePath = '/flutter_template_images/templates/app_shared/ios.tmpl/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png';

    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(onRun: () {
        fileSystem.file(templateIconContentsJsonPath)
          ..createSync(recursive: true)
          ..writeAsStringSync('''
{
  "images": [
    {
      "size": "20x20",
      "idiom": "iphone",
      "filename": "Icon-App-20x20@2x.png",
      "scale": "2x"
    }
  ],
  "info": {
    "version": 1,
    "author": "xcode"
  }
}
''');
        fileSystem.file(templateIconImagePath)
          ..createSync(recursive: true)
          ..writeAsBytes(<int>[1, 2, 3]);

        fileSystem.file(projectIconContentsJsonPath)
          ..createSync(recursive: true)
          ..writeAsStringSync('''
{
  "images": [
    {
      "size": "20x20",
      "idiom": "iphone",
      "filename": "Icon-App-20x20@2x.png",
      "scale": "2x"
    }
  ],
  "info": {
    "version": 1,
    "author": "xcode"
  }
}
''');
        fileSystem.file(projectIconImagePath)
          ..createSync(recursive: true)
          ..writeAsBytes(<int>[4, 5, 6]);
      }),
      exportArchiveCommand(exportOptionsPlist: _exportOptionsPlist),
    ]);

    createMinimalMockProjectFiles();

    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    await createTestCommandRunner(command).run(
        <String>['build', 'ipa', '--no-pub']);

    expect(
      testLogger.statusText,
      isNot(contains('    ! App icon is set to the default placeholder icon. Replace with unique icons.'))
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('Validate app icon using the wrong width', () async {
    const String projectIconContentsJsonPath = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json';
    const String projectIconImagePath = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png';

    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(onRun: () {
        fileSystem.file(projectIconContentsJsonPath)
          ..createSync(recursive: true)
          ..writeAsStringSync('''
{
  "images": [
    {
      "size": "20x20",
      "idiom": "iphone",
      "filename": "Icon-App-20x20@2x.png",
      "scale": "2x"
    }
  ],
  "info": {
    "version": 1,
    "author": "xcode"
  }
}
''');
        fileSystem.file(projectIconImagePath)
          ..createSync(recursive: true)
          ..writeAsBytes(Uint8List(16))
          // set width to 1 pixel
          ..writeAsBytes(Uint8List(4)..buffer.asByteData().setInt32(0, 1), mode: FileMode.append)
          // set height to 40 pixels
          ..writeAsBytes(Uint8List(4)..buffer.asByteData().setInt32(0, 40), mode: FileMode.append);
      }),
      exportArchiveCommand(exportOptionsPlist: _exportOptionsPlist),
    ]);

    createMinimalMockProjectFiles();

    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    await createTestCommandRunner(command).run(
        <String>['build', 'ipa', '--no-pub']);

    expect(
      testLogger.statusText,
      contains('    ! App icon is using the incorrect size (e.g. Icon-App-20x20@2x.png).')
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('Validate app icon using the wrong height', () async {
    const String projectIconContentsJsonPath = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json';
    const String projectIconImagePath = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png';

    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(onRun: () {
        fileSystem.file(projectIconContentsJsonPath)
          ..createSync(recursive: true)
          ..writeAsStringSync('''
{
  "images": [
    {
      "size": "20x20",
      "idiom": "iphone",
      "filename": "Icon-App-20x20@2x.png",
      "scale": "2x"
    }
  ],
  "info": {
    "version": 1,
    "author": "xcode"
  }
}
''');
        fileSystem.file(projectIconImagePath)
          ..createSync(recursive: true)
          ..writeAsBytes(Uint8List(16))
          // set width to 40 pixels
          ..writeAsBytes(Uint8List(4)..buffer.asByteData().setInt32(0, 40), mode: FileMode.append)
          // set height to 1 pixel
          ..writeAsBytes(Uint8List(4)..buffer.asByteData().setInt32(0, 1), mode: FileMode.append);
      }),
      exportArchiveCommand(exportOptionsPlist: _exportOptionsPlist),
    ]);

    createMinimalMockProjectFiles();

    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    await createTestCommandRunner(command).run(
        <String>['build', 'ipa', '--no-pub']);

    expect(
      testLogger.statusText,
      contains('    ! App icon is using the incorrect size (e.g. Icon-App-20x20@2x.png).')
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('Validate app icon using the correct width and height', () async {
    const String projectIconContentsJsonPath = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json';
    const String projectIconImagePath = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png';

    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(onRun: () {
        fileSystem.file(projectIconContentsJsonPath)
          ..createSync(recursive: true)
          ..writeAsStringSync('''
{
  "images": [
    {
      "size": "20x20",
      "idiom": "iphone",
      "filename": "Icon-App-20x20@2x.png",
      "scale": "2x"
    }
  ],
  "info": {
    "version": 1,
    "author": "xcode"
  }
}
''');
        fileSystem.file(projectIconImagePath)
          ..createSync(recursive: true)
          ..writeAsBytes(Uint8List(16))
          // set width to 40 pixels
          ..writeAsBytes(Uint8List(4)..buffer.asByteData().setInt32(0, 40), mode: FileMode.append)
          // set height to 40 pixel
          ..writeAsBytes(Uint8List(4)..buffer.asByteData().setInt32(0, 40), mode: FileMode.append);
      }),
      exportArchiveCommand(exportOptionsPlist: _exportOptionsPlist),
    ]);

    createMinimalMockProjectFiles();

    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    await createTestCommandRunner(command).run(
        <String>['build', 'ipa', '--no-pub']);

    expect(
      testLogger.statusText,
      isNot(contains('    ! App icon is using the incorrect size (e.g. Icon-App-20x20@2x.png).'))
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('Validate app icon should skip validation for unknown format version', () async {
    const String projectIconContentsJsonPath = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json';
    const String projectIconImagePath = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png';

    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(onRun: () {
        // Uses unknown format version 123.
        fileSystem.file(projectIconContentsJsonPath)
          ..createSync(recursive: true)
          ..writeAsStringSync('''
{
  "images": [
    {
      "size": "20x20",
      "idiom": "iphone",
      "filename": "Icon-App-20x20@2x.png",
      "scale": "2x"
    }
  ],
  "info": {
    "version": 123,
    "author": "xcode"
  }
}
''');
        fileSystem.file(projectIconImagePath)
          ..createSync(recursive: true)
          ..writeAsBytes(Uint8List(16))
          // set width to 1 pixel
          ..writeAsBytes(Uint8List(4)..buffer.asByteData().setInt32(0, 1), mode: FileMode.append)
          // set height to 1 pixel
          ..writeAsBytes(Uint8List(4)..buffer.asByteData().setInt32(0, 1), mode: FileMode.append);
      }),
      exportArchiveCommand(exportOptionsPlist: _exportOptionsPlist),
    ]);

    createMinimalMockProjectFiles();

    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    await createTestCommandRunner(command).run(
        <String>['build', 'ipa', '--no-pub']);

    // The validation should be skipped, even when the icon size is incorrect.
    expect(
      testLogger.statusText,
      isNot(contains('    ! App icon is using the incorrect size (e.g. Icon-App-20x20@2x.png).')),
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('Validate app icon should skip validation of an icon image if invalid format', () async {
    const String projectIconContentsJsonPath = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json';
    final List<String> imageFileNames = <String>[
      'Icon-App-20x20@1x.png',
      'Icon-App-20x20@2x.png',
      'Icon-App-20x20@3x.png',
      'Icon-App-29x29@1x.png',
      'Icon-App-29x29@2x.png',
      'Icon-App-29x29@3x.png',
    ];

    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(onRun: () {
        // The following json contains examples of:
        // - invalid size
        // - invalid scale
        // - missing size
        // - missing idiom
        // - missing filename
        // - missing scale
        fileSystem.file(projectIconContentsJsonPath)
          ..createSync(recursive: true)
          ..writeAsStringSync('''
{
  "images": [
    {
      "size": "20*20",
      "idiom": "iphone",
      "filename": "Icon-App-20x20@2x.png",
      "scale": "1x"
    },
    {
      "size": "20x20",
      "idiom": "iphone",
      "filename": "Icon-App-20x20@2x.png",
      "scale": "2@"
    },
    {
      "idiom": "iphone",
      "filename": "Icon-App-20x20@3x.png",
      "scale": "3x"
    },
    {
      "size": "29x29",
      "filename": "Icon-App-29x29@1x.png",
      "scale": "1x"
    },
    {
      "size": "29x29",
      "idiom": "iphone",
      "scale": "2x"
    },
    {
      "size": "29x29",
      "idiom": "iphone",
      "filename": "Icon-App-20x20@3x.png"
    }
  ],
  "info": {
    "version": 1,
    "author": "xcode"
  }
}
''');

        // Resize all related images to 1x1.
        for (final String imageFileName in imageFileNames) {
          fileSystem.file('ios/Runner/Assets.xcassets/AppIcon.appiconset/$imageFileName')
            ..createSync(recursive: true)
            ..writeAsBytes(Uint8List(16))
            // set width to 1 pixel
            ..writeAsBytes(Uint8List(4)..buffer.asByteData().setInt32(0, 1), mode: FileMode.append)
            // set height to 1 pixel
            ..writeAsBytes(Uint8List(4)..buffer.asByteData().setInt32(0, 1), mode: FileMode.append);
        }
      }),
      exportArchiveCommand(exportOptionsPlist: _exportOptionsPlist),
    ]);

    createMinimalMockProjectFiles();

    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    await createTestCommandRunner(command).run(
        <String>['build', 'ipa', '--no-pub']);

    // The validation should be skipped, even when the image size is incorrect.
    for (final String imageFileName in imageFileNames) {
      expect(
        testLogger.statusText,
        isNot(contains('    ! App icon is using the incorrect size (e.g. $imageFileName).'))
      );
    }
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

  testUsingContext('Validate template launch images with conflicts', () async {
    const String projectLaunchImageContentsJsonPath = 'ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json';
    const String projectLaunchImagePath = 'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png';
    final String templateLaunchImageContentsJsonPath = '${Cache.flutterRoot!}/packages/flutter_tools/templates/app_shared/ios.tmpl/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json';
    const String templateLaunchImagePath = '/flutter_template_images/templates/app_shared/ios.tmpl/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png';

    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(onRun: () {
        fileSystem.file(templateLaunchImageContentsJsonPath)
          ..createSync(recursive: true)
          ..writeAsStringSync('''
{
  "images": [
    {
      "idiom": "iphone",
      "filename": "LaunchImage@2x.png",
      "scale": "2x"
    }
  ],
  "info": {
    "version": 1,
    "author": "xcode"
  }
}
''');
        fileSystem.file(templateLaunchImagePath)
          ..createSync(recursive: true)
          ..writeAsBytes(<int>[1, 2, 3]);

        fileSystem.file(projectLaunchImageContentsJsonPath)
          ..createSync(recursive: true)
          ..writeAsStringSync('''
{
  "images": [
    {
      "idiom": "iphone",
      "filename": "LaunchImage@2x.png",
      "scale": "2x"
    }
  ],
  "info": {
    "version": 1,
    "author": "xcode"
  }
}
''');
        fileSystem.file(projectLaunchImagePath)
          ..createSync(recursive: true)
          ..writeAsBytes(<int>[1, 2, 3]);
      }),
      exportArchiveCommand(exportOptionsPlist: _exportOptionsPlist),
    ]);

    createMinimalMockProjectFiles();

    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    await createTestCommandRunner(command).run(
        <String>['build', 'ipa', '--no-pub']);

    expect(
      testLogger.statusText,
      contains('    ! Launch image is set to the default placeholder icon. Replace with unique launch image.'),
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });


  testUsingContext('Validate template launch images without conflicts', () async {
    const String projectLaunchImageContentsJsonPath = 'ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json';
    const String projectLaunchImagePath = 'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png';
    final String templateLaunchImageContentsJsonPath = '${Cache.flutterRoot!}/packages/flutter_tools/templates/app_shared/ios.tmpl/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json';
    const String templateLaunchImagePath = '/flutter_template_images/templates/app_shared/ios.tmpl/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png';

    fakeProcessManager.addCommands(<FakeCommand>[
      xattrCommand,
      setUpFakeXcodeBuildHandler(onRun: () {
        fileSystem.file(templateLaunchImageContentsJsonPath)
          ..createSync(recursive: true)
          ..writeAsStringSync('''
{
  "images": [
    {
      "idiom": "iphone",
      "filename": "LaunchImage@2x.png",
      "scale": "2x"
    }
  ],
  "info": {
    "version": 1,
    "author": "xcode"
  }
}
''');
        fileSystem.file(templateLaunchImagePath)
          ..createSync(recursive: true)
          ..writeAsBytes(<int>[1, 2, 3]);

        fileSystem.file(projectLaunchImageContentsJsonPath)
          ..createSync(recursive: true)
          ..writeAsStringSync('''
{
  "images": [
    {
      "idiom": "iphone",
      "filename": "LaunchImage@2x.png",
      "scale": "2x"
    }
  ],
  "info": {
    "version": 1,
    "author": "xcode"
  }
}
''');
        fileSystem.file(projectLaunchImagePath)
          ..createSync(recursive: true)
          ..writeAsBytes(<int>[4, 5, 6]);
      }),
      exportArchiveCommand(exportOptionsPlist: _exportOptionsPlist),
    ]);

    createMinimalMockProjectFiles();

    final BuildCommand command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      osUtils: FakeOperatingSystemUtils(),
    );
    await createTestCommandRunner(command).run(
        <String>['build', 'ipa', '--no-pub']);

    expect(
      testLogger.statusText,
      isNot(contains('    ! Launch image is set to the default placeholder icon. Replace with unique launch image.')),
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => fakeProcessManager,
    Platform: () => macosPlatform,
    XcodeProjectInterpreter: () => FakeXcodeProjectInterpreterWithBuildSettings(),
  });

}


const String _xcBundleFilePath = '/.tmp_rand0/flutter_ios_build_temp_dirrand0/temporary_xcresult_bundle';
const String _exportOptionsPlist = '/.tmp_rand0/flutter_build_ios.rand0/ExportOptions.plist';
