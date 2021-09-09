// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/flutter_manifest.dart';
import 'package:flutter_tools/src/globals_null_migrated.dart' as globals;
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:meta/meta.dart';
import 'package:test/fake.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/fakes.dart';

void main() {
  // TODO(zanderso): remove once FlutterProject is fully refactored.
  // this is safe since no tests have expectations on the test logger.
  final BufferLogger logger = BufferLogger.test();

  group('Project', () {
    group('construction', () {
      _testInMemory('fails on null directory', () async {
        expect(
          () => FlutterProject.fromDirectory(null),
          throwsAssertionError,
        );
      });

      testWithoutContext('invalid utf8 throws a tool exit', () {
        final FileSystem fileSystem = MemoryFileSystem.test();
        final FlutterProjectFactory projectFactory = FlutterProjectFactory(
          fileSystem: fileSystem,
          logger: BufferLogger.test(),
        );
        fileSystem.file('pubspec.yaml').writeAsBytesSync(<int>[0xFFFE]);

        /// Technically this should throw a FileSystemException but this is
        /// currently a bug in package:file.
        expect(
          () => projectFactory.fromDirectory(fileSystem.currentDirectory),
          throwsToolExit(),
        );
      });

      _testInMemory('fails on invalid pubspec.yaml', () async {
        final Directory directory = globals.fs.directory('myproject');
        directory.childFile('pubspec.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync(invalidPubspec);

        expect(
          () => FlutterProject.fromDirectory(directory),
          throwsToolExit(),
        );
      });

      _testInMemory('fails on pubspec.yaml parse failure', () async {
        final Directory directory = globals.fs.directory('myproject');
        directory.childFile('pubspec.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync(parseErrorPubspec);

        expect(
          () => FlutterProject.fromDirectory(directory),
          throwsToolExit(),
        );
      });

      _testInMemory('fails on invalid example/pubspec.yaml', () async {
        final Directory directory = globals.fs.directory('myproject');
        directory.childDirectory('example').childFile('pubspec.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync(invalidPubspec);

        expect(
          () => FlutterProject.fromDirectory(directory),
          throwsToolExit(),
        );
      });

      _testInMemory('treats missing pubspec.yaml as empty', () async {
        final Directory directory = globals.fs.directory('myproject')
          ..createSync(recursive: true);
        expect(FlutterProject.fromDirectory(directory).manifest.isEmpty,
          true,
        );
      });

      _testInMemory('reads valid pubspec.yaml', () async {
        final Directory directory = globals.fs.directory('myproject');
        directory.childFile('pubspec.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync(validPubspec);
        expect(
          FlutterProject.fromDirectory(directory).manifest.appName,
          'hello',
        );
      });

      _testInMemory('reads dependencies from pubspec.yaml', () async {
        final Directory directory = globals.fs.directory('myproject');
        directory.childFile('pubspec.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync(validPubspecWithDependencies);
        expect(
          FlutterProject.fromDirectory(directory).manifest.dependencies,
          <String>{'plugin_a', 'plugin_b'},
        );
      });

      _testInMemory('sets up location', () async {
        final Directory directory = globals.fs.directory('myproject');
        expect(
          FlutterProject.fromDirectory(directory).directory.absolute.path,
          directory.absolute.path,
        );
        expect(
          FlutterProject.fromDirectoryTest(directory).directory.absolute.path,
          directory.absolute.path,
        );
        expect(
          FlutterProject.current().directory.absolute.path,
          globals.fs.currentDirectory.absolute.path,
        );
      });
    });

    group('ensure ready for platform-specific tooling', () {
      _testInMemory('does nothing, if project is not created', () async {
        final FlutterProject project = FlutterProject(
          globals.fs.directory('not_created'),
          FlutterManifest.empty(logger: logger),
          FlutterManifest.empty(logger: logger),
        );
        await project.regeneratePlatformSpecificTooling();
        expectNotExists(project.directory);
      });
      _testInMemory('does nothing in plugin or package root project', () async {
        final FlutterProject project = await aPluginProject();
        await project.regeneratePlatformSpecificTooling();
        expectNotExists(project.ios.hostAppRoot.childDirectory('Runner').childFile('GeneratedPluginRegistrant.h'));
        expectNotExists(androidPluginRegistrant(project.android.hostAppGradleRoot.childDirectory('app')));
        expectNotExists(project.ios.hostAppRoot.childDirectory('Flutter').childFile('Generated.xcconfig'));
        expectNotExists(project.android.hostAppGradleRoot.childFile('local.properties'));
      });
      _testInMemory('injects plugins for iOS', () async {
        final FlutterProject project = await someProject();
        await project.regeneratePlatformSpecificTooling();
        expectExists(project.ios.hostAppRoot.childDirectory('Runner').childFile('GeneratedPluginRegistrant.h'));
      });
      _testInMemory('generates Xcode configuration for iOS', () async {
        final FlutterProject project = await someProject();
        await project.regeneratePlatformSpecificTooling();
        expectExists(project.ios.hostAppRoot.childDirectory('Flutter').childFile('Generated.xcconfig'));
      });
      _testInMemory('injects plugins for Android', () async {
        final FlutterProject project = await someProject();
        await project.regeneratePlatformSpecificTooling();
        expectExists(androidPluginRegistrant(project.android.hostAppGradleRoot.childDirectory('app')));
      });
      _testInMemory('updates local properties for Android', () async {
        final FlutterProject project = await someProject();
        await project.regeneratePlatformSpecificTooling();
        expectExists(project.android.hostAppGradleRoot.childFile('local.properties'));
      });
      _testInMemory('Android project not on v2 embedding shows a warning', () async {
        final FlutterProject project = await someProject();
        // The default someProject with an empty <manifest> already indicates
        // v1 embedding, as opposed to having <meta-data
        // android:name="flutterEmbedding" android:value="2" />.

        await project.regeneratePlatformSpecificTooling();
        expect(testLogger.statusText, contains('https://flutter.dev/go/android-project-migration'));
      });
      _testInMemory('Android plugin without example app does not show a warning', () async {
        final FlutterProject project = await aPluginProject();
        project.example.directory.deleteSync();

        await project.regeneratePlatformSpecificTooling();
        expect(testLogger.statusText, isNot(contains('https://flutter.dev/go/android-project-migration')));
      });
      _testInMemory('updates local properties for Android', () async {
        final FlutterProject project = await someProject();
        await project.regeneratePlatformSpecificTooling();
        expectExists(project.android.hostAppGradleRoot.childFile('local.properties'));
      });
      testUsingContext('injects plugins for macOS', () async {
        final FlutterProject project = await someProject();
        project.macos.managedDirectory.createSync(recursive: true);
        await project.regeneratePlatformSpecificTooling();
        expectExists(project.macos.managedDirectory.childFile('GeneratedPluginRegistrant.swift'));
      }, overrides: <Type, Generator>{
        FileSystem: () => MemoryFileSystem.test(),
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
        FlutterProjectFactory: () => FlutterProjectFactory(
          logger: logger,
          fileSystem: globals.fs,
        ),
      });
      testUsingContext('generates Xcode configuration for macOS', () async {
        final FlutterProject project = await someProject();
        project.macos.managedDirectory.createSync(recursive: true);
        await project.regeneratePlatformSpecificTooling();
        expectExists(project.macos.generatedXcodePropertiesFile);
      }, overrides: <Type, Generator>{
        FileSystem: () => MemoryFileSystem.test(),
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
        FlutterProjectFactory: () => FlutterProjectFactory(
          logger: logger,
          fileSystem: globals.fs,
        ),
      });
      testUsingContext('injects plugins for Linux', () async {
        final FlutterProject project = await someProject();
        project.linux.cmakeFile.createSync(recursive: true);
        await project.regeneratePlatformSpecificTooling();
        expectExists(project.linux.managedDirectory.childFile('generated_plugin_registrant.h'));
        expectExists(project.linux.managedDirectory.childFile('generated_plugin_registrant.cc'));
      }, overrides: <Type, Generator>{
        FileSystem: () => MemoryFileSystem.test(),
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
        FlutterProjectFactory: () => FlutterProjectFactory(
          logger: logger,
          fileSystem: globals.fs,
        ),
      });
      testUsingContext('injects plugins for Windows', () async {
        final FlutterProject project = await someProject();
        project.windows.cmakeFile.createSync(recursive: true);
        await project.regeneratePlatformSpecificTooling();
        expectExists(project.windows.managedDirectory.childFile('generated_plugin_registrant.h'));
        expectExists(project.windows.managedDirectory.childFile('generated_plugin_registrant.cc'));
      }, overrides: <Type, Generator>{
        FileSystem: () => MemoryFileSystem.test(),
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => TestFeatureFlags(isWindowsEnabled: true),
        FlutterProjectFactory: () => FlutterProjectFactory(
          logger: logger,
          fileSystem: globals.fs,
        ),
      });
      _testInMemory('creates Android library in module', () async {
        final FlutterProject project = await aModuleProject();
        await project.regeneratePlatformSpecificTooling();
        expectExists(project.android.hostAppGradleRoot.childFile('settings.gradle'));
        expectExists(project.android.hostAppGradleRoot.childFile('local.properties'));
        expectExists(androidPluginRegistrant(project.android.hostAppGradleRoot.childDirectory('Flutter')));
      });
      _testInMemory('creates iOS pod in module', () async {
        final FlutterProject project = await aModuleProject();
        await project.regeneratePlatformSpecificTooling();
        final Directory flutter = project.ios.hostAppRoot.childDirectory('Flutter');
        expectExists(flutter.childFile('podhelper.rb'));
        expectExists(flutter.childFile('flutter_export_environment.sh'));
        expectExists(flutter.childFile('${project.manifest.appName}.podspec'));
        expectExists(flutter.childFile('Generated.xcconfig'));
        final Directory pluginRegistrantClasses = flutter
            .childDirectory('FlutterPluginRegistrant')
            .childDirectory('Classes');
        expectExists(pluginRegistrantClasses.childFile('GeneratedPluginRegistrant.h'));
        expectExists(pluginRegistrantClasses.childFile('GeneratedPluginRegistrant.m'));
      });

      testUsingContext('Version.json info is correct', () {
        final MemoryFileSystem fileSystem = MemoryFileSystem.test();
        final FlutterManifest manifest = FlutterManifest.createFromString('''
    name: test
    version: 1.0.0+3
    ''', logger: BufferLogger.test());
        final FlutterProject project = FlutterProject(fileSystem.systemTempDirectory,manifest,manifest);
        final Map<String, dynamic> versionInfo = jsonDecode(project.getVersionInfo()) as Map<String, dynamic>;
        expect(versionInfo['app_name'],'test');
        expect(versionInfo['version'],'1.0.0');
        expect(versionInfo['build_number'],'3');
      });
    });

    group('module status', () {
      _testInMemory('is known for module', () async {
        final FlutterProject project = await aModuleProject();
        expect(project.isModule, isTrue);
        expect(project.android.isModule, isTrue);
        expect(project.ios.isModule, isTrue);
        expect(project.android.hostAppGradleRoot.basename, '.android');
        expect(project.ios.hostAppRoot.basename, '.ios');
      });
      _testInMemory('is known for non-module', () async {
        final FlutterProject project = await someProject();
        expect(project.isModule, isFalse);
        expect(project.android.isModule, isFalse);
        expect(project.ios.isModule, isFalse);
        expect(project.android.hostAppGradleRoot.basename, 'android');
        expect(project.ios.hostAppRoot.basename, 'ios');
      });
    });

    group('example', () {
      _testInMemory('exists for plugin in legacy format', () async {
        final FlutterProject project = await aPluginProject();
        expect(project.isPlugin, isTrue);
        expect(project.hasExampleApp, isTrue);
      });
      _testInMemory('exists for plugin in multi-platform format', () async {
        final FlutterProject project = await aPluginProject(legacy: false);
        expect(project.hasExampleApp, isTrue);
      });
      _testInMemory('does not exist for non-plugin', () async {
        final FlutterProject project = await someProject();
        expect(project.isPlugin, isFalse);
        expect(project.hasExampleApp, isFalse);
      });
    });

    group('language', () {
      XcodeProjectInterpreter xcodeProjectInterpreter;
      MemoryFileSystem fs;
      FlutterProjectFactory flutterProjectFactory;
      setUp(() {
        fs = MemoryFileSystem.test();
        xcodeProjectInterpreter = XcodeProjectInterpreter.test(processManager: FakeProcessManager.any());
        flutterProjectFactory = FlutterProjectFactory(
          logger: logger,
          fileSystem: fs,
        );
      });

      _testInMemory('default host app language', () async {
        final FlutterProject project = await someProject();
        expect(project.android.isKotlin, isFalse);
      });

      testUsingContext('kotlin host app language', () async {
        final FlutterProject project = await someProject();

        addAndroidGradleFile(project.directory,
          gradleFileContent: () {
            return '''
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
''';
        });
        expect(project.android.isKotlin, isTrue);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        XcodeProjectInterpreter: () => xcodeProjectInterpreter,
        FlutterProjectFactory: () => flutterProjectFactory,
      });
    });

    group('product bundle identifier', () {
      MemoryFileSystem fs;
      FakePlistParser testPlistUtils;
      MockXcodeProjectInterpreter mockXcodeProjectInterpreter;
      FlutterProjectFactory flutterProjectFactory;
      setUp(() {
        fs = MemoryFileSystem.test();
        testPlistUtils = FakePlistParser();
        mockXcodeProjectInterpreter = MockXcodeProjectInterpreter();
        flutterProjectFactory = FlutterProjectFactory(
          fileSystem: fs,
          logger: logger,
        );
      });

      void testWithMocks(String description, Future<void> Function() testMethod) {
        testUsingContext(description, testMethod, overrides: <Type, Generator>{
          FileSystem: () => fs,
          ProcessManager: () => FakeProcessManager.any(),
          PlistParser: () => testPlistUtils,
          XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
          FlutterProjectFactory: () => flutterProjectFactory,
        });
      }

      testWithMocks('null, if no build settings or plist entries', () async {
        final FlutterProject project = await someProject();
        expect(await project.ios.productBundleIdentifier(null), isNull);
      });

      testWithMocks('from build settings, if no plist', () async {
        final FlutterProject project = await someProject();
        project.ios.xcodeProject.createSync();
        mockXcodeProjectInterpreter.buildSettings = <String, String>{
          'PRODUCT_BUNDLE_IDENTIFIER': 'io.flutter.someProject',
        };
        mockXcodeProjectInterpreter.xcodeProjectInfo = XcodeProjectInfo(<String>[], <String>[], <String>['Runner'], logger);

        expect(await project.ios.productBundleIdentifier(null), 'io.flutter.someProject');
      });

      testWithMocks('from project file, if no plist or build settings', () async {
        final FlutterProject project = await someProject();
        addIosProjectFile(project.directory, projectFileContent: () {
          return projectFileWithBundleId('io.flutter.someProject');
        });
        expect(await project.ios.productBundleIdentifier(null), 'io.flutter.someProject');
      });

      testWithMocks('from plist, if no variables', () async {
        final FlutterProject project = await someProject();
        project.ios.defaultHostInfoPlist.createSync(recursive: true);
        testPlistUtils.setProperty('CFBundleIdentifier', 'io.flutter.someProject');
        expect(await project.ios.productBundleIdentifier(null), 'io.flutter.someProject');
      });

      testWithMocks('from build settings and plist, if default variable', () async {
        final FlutterProject project = await someProject();
        project.ios.xcodeProject.createSync();
        mockXcodeProjectInterpreter.buildSettings = <String, String>{
          'PRODUCT_BUNDLE_IDENTIFIER': 'io.flutter.someProject',
        };
        mockXcodeProjectInterpreter.xcodeProjectInfo = XcodeProjectInfo(<String>[], <String>[], <String>['Runner'], logger);
        testPlistUtils.setProperty('CFBundleIdentifier', r'$(PRODUCT_BUNDLE_IDENTIFIER)');

        expect(await project.ios.productBundleIdentifier(null), 'io.flutter.someProject');
      });

      testWithMocks('from build settings and plist, by substitution', () async {
        final FlutterProject project = await someProject();
        project.ios.xcodeProject.createSync();
        project.ios.defaultHostInfoPlist.createSync(recursive: true);
        mockXcodeProjectInterpreter.buildSettings = <String, String>{
          'PRODUCT_BUNDLE_IDENTIFIER': 'io.flutter.someProject',
          'SUFFIX': 'suffix',
        };
        mockXcodeProjectInterpreter.xcodeProjectInfo = XcodeProjectInfo(<String>[], <String>[], <String>['Runner'], logger);
        testPlistUtils.setProperty('CFBundleIdentifier', r'$(PRODUCT_BUNDLE_IDENTIFIER).$(SUFFIX)');

        expect(await project.ios.productBundleIdentifier(null), 'io.flutter.someProject.suffix');
      });

      testWithMocks('fails with no flavor and defined schemes', () async {
        final FlutterProject project = await someProject();
        project.ios.xcodeProject.createSync();
        mockXcodeProjectInterpreter.xcodeProjectInfo = XcodeProjectInfo(<String>[], <String>[], <String>['free', 'paid'], logger);

        await expectToolExitLater(
          project.ios.productBundleIdentifier(null),
          contains('You must specify a --flavor option to select one of the available schemes.')
        );
      });

      testWithMocks('handles case insensitive flavor', () async {
        final FlutterProject project = await someProject();
        project.ios.xcodeProject.createSync();
        mockXcodeProjectInterpreter.buildSettings = <String, String>{
          'PRODUCT_BUNDLE_IDENTIFIER': 'io.flutter.someProject',
        };
        mockXcodeProjectInterpreter.xcodeProjectInfo =XcodeProjectInfo(<String>[], <String>[], <String>['Free'], logger);
        const BuildInfo buildInfo = BuildInfo(BuildMode.debug, 'free', treeShakeIcons: false);

        expect(await project.ios.productBundleIdentifier(buildInfo), 'io.flutter.someProject');
      });

      testWithMocks('fails with flavor and default schemes', () async {
        final FlutterProject project = await someProject();
        project.ios.xcodeProject.createSync();
        mockXcodeProjectInterpreter.xcodeProjectInfo = XcodeProjectInfo(<String>[], <String>[], <String>['Runner'], logger);
        const BuildInfo buildInfo = BuildInfo(BuildMode.debug, 'free', treeShakeIcons: false);

        await expectToolExitLater(
          project.ios.productBundleIdentifier(buildInfo),
          contains('The Xcode project does not define custom schemes. You cannot use the --flavor option.')
        );
      });

      testWithMocks('empty surrounded by quotes', () async {
        final FlutterProject project = await someProject();
        addIosProjectFile(project.directory, projectFileContent: () {
          return projectFileWithBundleId('', qualifier: '"');
        });
        expect(await project.ios.productBundleIdentifier(null), '');
      });

      testWithMocks('surrounded by double quotes', () async {
        final FlutterProject project = await someProject();
        addIosProjectFile(project.directory, projectFileContent: () {
          return projectFileWithBundleId('io.flutter.someProject', qualifier: '"');
        });
        expect(await project.ios.productBundleIdentifier(null), 'io.flutter.someProject');
      });

      testWithMocks('surrounded by single quotes', () async {
        final FlutterProject project = await someProject();
        addIosProjectFile(project.directory, projectFileContent: () {
          return projectFileWithBundleId('io.flutter.someProject', qualifier: "'");
        });
        expect(await project.ios.productBundleIdentifier(null), 'io.flutter.someProject');
      });
    });

    group('application bundle name', () {
      MemoryFileSystem fs;
      MockXcodeProjectInterpreter mockXcodeProjectInterpreter;
      setUp(() {
        fs = MemoryFileSystem.test();
        mockXcodeProjectInterpreter = MockXcodeProjectInterpreter();
      });

      testUsingContext('app product name defaults to Runner.app', () async {
        final FlutterProject project = await someProject();
        expect(await project.ios.hostAppBundleName(null), 'Runner.app');
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        XcodeProjectInterpreter: () => mockXcodeProjectInterpreter
      });

      testUsingContext('app product name xcodebuild settings', () async {
        final FlutterProject project = await someProject();
        project.ios.xcodeProject.createSync();
        mockXcodeProjectInterpreter.buildSettings = <String, String>{
          'FULL_PRODUCT_NAME': 'My App.app'
        };
        mockXcodeProjectInterpreter.xcodeProjectInfo = XcodeProjectInfo(<String>[], <String>[], <String>['Runner'], logger);

        expect(await project.ios.hostAppBundleName(null), 'My App.app');
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        XcodeProjectInterpreter: () => mockXcodeProjectInterpreter
      });
    });

    group('organization names set', () {
      _testInMemory('is empty, if project not created', () async {
        final FlutterProject project = await someProject();
        expect(await project.organizationNames, isEmpty);
      });
      _testInMemory('is empty, if no platform folders exist', () async {
        final FlutterProject project = await someProject();
        project.directory.createSync();
        expect(await project.organizationNames, isEmpty);
      });
      _testInMemory('is populated from iOS bundle identifier', () async {
        final FlutterProject project = await someProject();
        addIosProjectFile(project.directory, projectFileContent: () {
          return projectFileWithBundleId('io.flutter.someProject', qualifier: "'");
        });
        expect(await project.organizationNames, <String>['io.flutter']);
      });
      _testInMemory('is populated from Android application ID', () async {
        final FlutterProject project = await someProject();
        addAndroidGradleFile(project.directory,
          gradleFileContent: () {
            return gradleFileWithApplicationId('io.flutter.someproject');
          });
        expect(await project.organizationNames, <String>['io.flutter']);
      });
      _testInMemory('is populated from iOS bundle identifier in plugin example', () async {
        final FlutterProject project = await someProject();
        addIosProjectFile(project.example.directory, projectFileContent: () {
          return projectFileWithBundleId('io.flutter.someProject', qualifier: "'");
        });
        expect(await project.organizationNames, <String>['io.flutter']);
      });
      _testInMemory('is populated from Android application ID in plugin example', () async {
        final FlutterProject project = await someProject();
        addAndroidGradleFile(project.example.directory,
          gradleFileContent: () {
            return gradleFileWithApplicationId('io.flutter.someproject');
          });
        expect(await project.organizationNames, <String>['io.flutter']);
      });
      _testInMemory('is populated from Android group in plugin', () async {
        final FlutterProject project = await someProject();
        addAndroidWithGroup(project.directory, 'io.flutter.someproject');
        expect(await project.organizationNames, <String>['io.flutter']);
      });
      _testInMemory('is singleton, if sources agree', () async {
        final FlutterProject project = await someProject();
        addIosProjectFile(project.directory, projectFileContent: () {
          return projectFileWithBundleId('io.flutter.someProject');
        });
        addAndroidGradleFile(project.directory,
          gradleFileContent: () {
            return gradleFileWithApplicationId('io.flutter.someproject');
          });
        expect(await project.organizationNames, <String>['io.flutter']);
      });
      _testInMemory('is non-singleton, if sources disagree', () async {
        final FlutterProject project = await someProject();
        addIosProjectFile(project.directory, projectFileContent: () {
          return projectFileWithBundleId('io.flutter.someProject');
        });
        addAndroidGradleFile(project.directory,
          gradleFileContent: () {
            return gradleFileWithApplicationId('io.clutter.someproject');
          });
        expect(
          await project.organizationNames,
          <String>['io.flutter', 'io.clutter'],
        );
      });
    });
  });
  group('watch companion', () {
    MemoryFileSystem fs;
    FakePlistParser testPlistParser;
    MockXcodeProjectInterpreter mockXcodeProjectInterpreter;
    FlutterProjectFactory flutterProjectFactory;
    setUp(() {
      fs = MemoryFileSystem.test();
      testPlistParser = FakePlistParser();
      mockXcodeProjectInterpreter = MockXcodeProjectInterpreter();
      flutterProjectFactory = FlutterProjectFactory(
        fileSystem: fs,
        logger: logger,
      );
    });

    testUsingContext('cannot find bundle identifier', () async {
      final FlutterProject project = await someProject();
      expect(await project.ios.containsWatchCompanion(<String>['WatchTarget'], null), isFalse);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
      PlistParser: () => testPlistParser,
      XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
      FlutterProjectFactory: () => flutterProjectFactory,
    });

    group('with bundle identifier', () {
      setUp(() {
        mockXcodeProjectInterpreter.buildSettings = <String, String>{
          'PRODUCT_BUNDLE_IDENTIFIER': 'io.flutter.someProject',
        };
        mockXcodeProjectInterpreter.xcodeProjectInfo = XcodeProjectInfo(<String>[], <String>[], <String>['Runner'], logger);
      });

      testUsingContext('no Info.plist in target', () async {
        final FlutterProject project = await someProject();
        expect(await project.ios.containsWatchCompanion(<String>['WatchTarget'], null), isFalse);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        PlistParser: () => testPlistParser,
        XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
        FlutterProjectFactory: () => flutterProjectFactory,
      });

      testUsingContext('Info.plist in target does not contain WKCompanionAppBundleIdentifier', () async {
        final FlutterProject project = await someProject();
        project.ios.hostAppRoot.childDirectory('WatchTarget').childFile('Info.plist').createSync(recursive: true);

        expect(await project.ios.containsWatchCompanion(<String>['WatchTarget'], null), isFalse);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        PlistParser: () => testPlistParser,
        XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
        FlutterProjectFactory: () => flutterProjectFactory,
      });

      testUsingContext('target WKCompanionAppBundleIdentifier is not project bundle identifier', () async {
        final FlutterProject project = await someProject();
        project.ios.hostAppRoot.childDirectory('WatchTarget').childFile('Info.plist').createSync(recursive: true);

        testPlistParser.setProperty('WKCompanionAppBundleIdentifier', 'io.flutter.someOTHERproject');
        expect(await project.ios.containsWatchCompanion(<String>['WatchTarget'], null), isFalse);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        PlistParser: () => testPlistParser,
        XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
        FlutterProjectFactory: () => flutterProjectFactory,
      });

      testUsingContext('has watch companion', () async {
        final FlutterProject project = await someProject();
        project.ios.xcodeProject.createSync();
        project.ios.hostAppRoot.childDirectory('WatchTarget').childFile('Info.plist').createSync(recursive: true);
        testPlistParser.setProperty('WKCompanionAppBundleIdentifier', 'io.flutter.someProject');

        expect(await project.ios.containsWatchCompanion(<String>['WatchTarget'], null), isTrue);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        PlistParser: () => testPlistParser,
        XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
        FlutterProjectFactory: () => flutterProjectFactory,
      });

      testUsingContext('has watch companion with build settings', () async {
        final FlutterProject project = await someProject();
        project.ios.xcodeProject.createSync();
        mockXcodeProjectInterpreter.buildSettings = <String, String>{
          'PRODUCT_BUNDLE_IDENTIFIER': 'io.flutter.someProject',
        };
        project.ios.hostAppRoot.childDirectory('WatchTarget').childFile('Info.plist').createSync(recursive: true);
        testPlistParser.setProperty('WKCompanionAppBundleIdentifier', r'$(PRODUCT_BUNDLE_IDENTIFIER)');

        expect(await project.ios.containsWatchCompanion(<String>['WatchTarget'], null), isTrue);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        PlistParser: () => testPlistParser,
        XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
        FlutterProjectFactory: () => flutterProjectFactory,
      });
    });
  });
}

Future<FlutterProject> someProject() async {
  final Directory directory = globals.fs.directory('some_project');
  directory.childDirectory('.dart_tool')
    .childFile('package_config.json')
    ..createSync(recursive: true)
    ..writeAsStringSync('{"configVersion":2,"packages":[]}');
  directory.childDirectory('ios').createSync(recursive: true);
  final Directory androidDirectory = directory
      .childDirectory('android')
      ..createSync(recursive: true);
  androidDirectory
    .childFile('AndroidManifest.xml')
    .writeAsStringSync('<manifest></manifest>');
  return FlutterProject.fromDirectory(directory);
}

Future<FlutterProject> aPluginProject({bool legacy = true}) async {
  final Directory directory = globals.fs.directory('plugin_project');
  directory.childDirectory('ios').createSync(recursive: true);
  directory.childDirectory('android').createSync(recursive: true);
  directory.childDirectory('example').createSync(recursive: true);
  String pluginPubSpec;
  if (legacy) {
    pluginPubSpec = '''
name: my_plugin
flutter:
  plugin:
    androidPackage: com.example
    pluginClass: MyPlugin
    iosPrefix: FLT
''';
  } else {
    pluginPubSpec = '''
name: my_plugin
flutter:
  plugin:
    platforms:
      android:
        package: com.example
        pluginClass: MyPlugin
      ios:
        pluginClass: MyPlugin
      linux:
        pluginClass: MyPlugin
      macos:
        pluginClass: MyPlugin
      windows:
        pluginClass: MyPlugin
''';
  }
  directory.childFile('pubspec.yaml').writeAsStringSync(pluginPubSpec);
  return FlutterProject.fromDirectory(directory);
}

Future<FlutterProject> aModuleProject() async {
  final Directory directory = globals.fs.directory('module_project');
  directory
    .childDirectory('.dart_tool')
    .childFile('package_config.json')
    ..createSync(recursive: true)
    ..writeAsStringSync('{"configVersion":2,"packages":[]}');
  directory.childFile('pubspec.yaml').writeAsStringSync('''
name: my_module
flutter:
  module:
    androidPackage: com.example
''');
  return FlutterProject.fromDirectory(directory);
}

/// Executes the [testMethod] in a context where the file system
/// is in memory.
@isTest
void _testInMemory(String description, Future<void> Function() testMethod) {
  Cache.flutterRoot = getFlutterRoot();
  final FileSystem testFileSystem = MemoryFileSystem(
    style: globals.platform.isWindows ? FileSystemStyle.windows : FileSystemStyle.posix,
  );
  testFileSystem
    .directory('.dart_tool')
    .childFile('package_config.json')
    ..createSync(recursive: true)
    ..writeAsStringSync('{"configVersion":2,"packages":[]}');
  // Transfer needed parts of the Flutter installation folder
  // to the in-memory file system used during testing.
  final Logger logger = BufferLogger.test();
  transfer(Cache(
    fileSystem: globals.fs,
    logger: logger,
    artifacts: <ArtifactSet>[],
    osUtils: OperatingSystemUtils(
      fileSystem: globals.fs,
      logger: logger,
      platform: globals.platform,
      processManager: globals.processManager,
    ),
    platform: globals.platform,
  ).getArtifactDirectory('gradle_wrapper'), testFileSystem);
  transfer(globals.fs.directory(Cache.flutterRoot)
      .childDirectory('packages')
      .childDirectory('flutter_tools')
      .childDirectory('templates'), testFileSystem);
  // Set up enough of the packages to satisfy the templating code.
  final File packagesFile = testFileSystem.directory(Cache.flutterRoot)
      .childDirectory('packages')
      .childDirectory('flutter_tools')
      .childDirectory('.dart_tool')
      .childFile('package_config.json');
  final Directory dummyTemplateImagesDirectory = testFileSystem.directory(Cache.flutterRoot).parent;
  dummyTemplateImagesDirectory.createSync(recursive: true);
  packagesFile.createSync(recursive: true);
  packagesFile.writeAsStringSync(json.encode(<String, Object>{
    'configVersion': 2,
    'packages': <Object>[
      <String, Object>{
        'name': 'flutter_template_images',
        'rootUri': dummyTemplateImagesDirectory.uri.toString(),
        'packageUri': 'lib/',
        'languageVersion': '2.6'
      },
    ],
  }));

  testUsingContext(
    description,
    testMethod,
    overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Cache: () => Cache(
        logger: globals.logger,
        fileSystem: testFileSystem,
        osUtils: globals.os,
        platform: globals.platform,
        artifacts: <ArtifactSet>[],
      ),
      FlutterProjectFactory: () => FlutterProjectFactory(
        fileSystem: testFileSystem,
        logger: globals.logger ?? BufferLogger.test(),
      ),
    },
  );
}

/// Transfers files and folders from the local file system's Flutter
/// installation to an (in-memory) file system used for testing.
void transfer(FileSystemEntity entity, FileSystem target) {
  if (entity is Directory) {
    target.directory(entity.absolute.path).createSync(recursive: true);
    for (final FileSystemEntity child in entity.listSync()) {
      transfer(child, target);
    }
  } else if (entity is File) {
    target.file(entity.absolute.path).writeAsBytesSync(entity.readAsBytesSync(), flush: true);
  } else {
    throw 'Unsupported FileSystemEntity ${entity.runtimeType}';
  }
}

void expectExists(FileSystemEntity entity) {
  expect(entity.existsSync(), isTrue);
}

void expectNotExists(FileSystemEntity entity) {
  expect(entity.existsSync(), isFalse);
}

void addIosProjectFile(Directory directory, {String Function() projectFileContent}) {
  directory
      .childDirectory('ios')
      .childDirectory('Runner.xcodeproj')
      .childFile('project.pbxproj')
        ..createSync(recursive: true)
    ..writeAsStringSync(projectFileContent());
}

void addAndroidGradleFile(Directory directory, { String Function() gradleFileContent }) {
  directory
      .childDirectory('android')
      .childDirectory('app')
      .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync(gradleFileContent());
}

void addAndroidWithGroup(Directory directory, String id) {
  directory.childDirectory('android').childFile('build.gradle')
    ..createSync(recursive: true)
    ..writeAsStringSync(gradleFileWithGroupId(id));
}

String get validPubspec => '''
name: hello
flutter:
''';

String get validPubspecWithDependencies => '''
name: hello
flutter:

dependencies:
  plugin_a:
  plugin_b:
''';


String get invalidPubspec => '''
name: hello
flutter:
  invalid:
''';

String get parseErrorPubspec => '''
name: hello
# Whitespace is important.
flutter:
    something:
  something_else:
''';

String projectFileWithBundleId(String id, {String qualifier}) {
  return '''
97C147061CF9000F007C117D /* Debug */ = {
  isa = XCBuildConfiguration;
  baseConfigurationReference = 9740EEB21CF90195004384FC /* Debug.xcconfig */;
  buildSettings = {
    PRODUCT_BUNDLE_IDENTIFIER = ${qualifier ?? ''}$id${qualifier ?? ''};
    PRODUCT_NAME = "\$(TARGET_NAME)";
  };
  name = Debug;
};
''';
}

String gradleFileWithApplicationId(String id) {
  return '''
apply plugin: 'com.android.application'
android {
    compileSdkVersion 30

    defaultConfig {
        applicationId '$id'
    }
}
''';
}

String gradleFileWithGroupId(String id) {
  return '''
group '$id'
version '1.0-SNAPSHOT'

apply plugin: 'com.android.library'

android {
    compileSdkVersion 30
}
''';
}

File androidPluginRegistrant(Directory parent) {
  return parent.childDirectory('src')
    .childDirectory('main')
    .childDirectory('java')
    .childDirectory('io')
    .childDirectory('flutter')
    .childDirectory('plugins')
    .childFile('GeneratedPluginRegistrant.java');
}

class MockXcodeProjectInterpreter extends Fake implements XcodeProjectInterpreter {
  Map<String, String> buildSettings = <String, String>{};
  XcodeProjectInfo xcodeProjectInfo;

  @override
  Future<Map<String, String>> getBuildSettings(String projectPath, {
    XcodeProjectBuildContext buildContext,
    Duration timeout = const Duration(minutes: 1),
  }) async {
    return buildSettings;
  }

  @override
  Future<XcodeProjectInfo> getInfo(String projectPath, {String projectFilename}) async {
    return xcodeProjectInfo;
  }

  @override
  bool get isInstalled => true;
}
