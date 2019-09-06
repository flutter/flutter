// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/flutter_manifest.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/testbed.dart';

void main() {
  group('Project', () {
    group('construction', () {
      testInMemory('fails on null directory', () async {
        expect(
          () => FlutterProject.fromDirectory(null),
          throwsA(isInstanceOf<AssertionError>()),
        );
      });

      testInMemory('fails on invalid pubspec.yaml', () async {
        final Directory directory = fs.directory('myproject');
        directory.childFile('pubspec.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync(invalidPubspec);

        expect(
          () => FlutterProject.fromDirectory(directory),
          throwsA(isInstanceOf<ToolExit>()),
        );
      });

      testInMemory('fails on pubspec.yaml parse failure', () async {
        final Directory directory = fs.directory('myproject');
        directory.childFile('pubspec.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync(parseErrorPubspec);

        expect(
          () => FlutterProject.fromDirectory(directory),
          throwsA(isInstanceOf<ToolExit>()),
        );
      });

      testInMemory('fails on invalid example/pubspec.yaml', () async {
        final Directory directory = fs.directory('myproject');
        directory.childDirectory('example').childFile('pubspec.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync(invalidPubspec);

        expect(
          () => FlutterProject.fromDirectory(directory),
          throwsA(isInstanceOf<ToolExit>()),
        );
      });

      testInMemory('treats missing pubspec.yaml as empty', () async {
        final Directory directory = fs.directory('myproject')
          ..createSync(recursive: true);
        expect((FlutterProject.fromDirectory(directory)).manifest.isEmpty,
          true,
        );
      });

      testInMemory('reads valid pubspec.yaml', () async {
        final Directory directory = fs.directory('myproject');
        directory.childFile('pubspec.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync(validPubspec);
        expect(
          FlutterProject.fromDirectory(directory).manifest.appName,
          'hello',
        );
      });

      testInMemory('sets up location', () async {
        final Directory directory = fs.directory('myproject');
        expect(
          FlutterProject.fromDirectory(directory).directory.absolute.path,
          directory.absolute.path,
        );
        expect(
          FlutterProject.fromPath(directory.path).directory.absolute.path,
          directory.absolute.path,
        );
        expect(
          FlutterProject.current().directory.absolute.path,
          fs.currentDirectory.absolute.path,
        );
      });
    });

    group('editable Android host app', () {
      testInMemory('fails on non-module', () async {
        final FlutterProject project = await someProject();
        await expectLater(
          project.android.makeHostAppEditable(),
          throwsA(isInstanceOf<AssertionError>()),
        );
      });
      testInMemory('exits on already editable module', () async {
        final FlutterProject project = await aModuleProject();
        await project.android.makeHostAppEditable();
        return expectToolExitLater(project.android.makeHostAppEditable(), contains('already editable'));
      });
      testInMemory('creates android/app folder in place of .android/app', () async {
        final FlutterProject project = await aModuleProject();
        await project.android.makeHostAppEditable();
        expectNotExists(project.directory.childDirectory('.android').childDirectory('app'));
        expect(
          project.directory.childDirectory('.android').childFile('settings.gradle').readAsStringSync(),
          isNot(contains("include ':app'")),
        );
        expectExists(project.directory.childDirectory('android').childDirectory('app'));
        expectExists(project.directory.childDirectory('android').childFile('local.properties'));
        expect(
          project.directory.childDirectory('android').childFile('settings.gradle').readAsStringSync(),
          contains("include ':app'"),
        );
      });
      testInMemory('retains .android/Flutter folder and references it', () async {
        final FlutterProject project = await aModuleProject();
        await project.android.makeHostAppEditable();
        expectExists(project.directory.childDirectory('.android').childDirectory('Flutter'));
        expect(
          project.directory.childDirectory('android').childFile('settings.gradle').readAsStringSync(),
          contains('new File(settingsDir.parentFile, \'.android/include_flutter.groovy\')'),
        );
      });
      testInMemory('can be redone after deletion', () async {
        final FlutterProject project = await aModuleProject();
        await project.android.makeHostAppEditable();
        project.directory.childDirectory('android').deleteSync(recursive: true);
        await project.android.makeHostAppEditable();
        expectExists(project.directory.childDirectory('android').childDirectory('app'));
      });
    });

    group('ensure ready for platform-specific tooling', () {
      testInMemory('does nothing, if project is not created', () async {
        final FlutterProject project = FlutterProject(
          fs.directory('not_created'),
          FlutterManifest.empty(),
          FlutterManifest.empty(),
        );
        await project.ensureReadyForPlatformSpecificTooling();
        expectNotExists(project.directory);
      });
      testInMemory('does nothing in plugin or package root project', () async {
        final FlutterProject project = await aPluginProject();
        await project.ensureReadyForPlatformSpecificTooling();
        expectNotExists(project.ios.hostAppRoot.childDirectory('Runner').childFile('GeneratedPluginRegistrant.h'));
        expectNotExists(androidPluginRegistrant(project.android.hostAppGradleRoot.childDirectory('app')));
        expectNotExists(project.ios.hostAppRoot.childDirectory('Flutter').childFile('Generated.xcconfig'));
        expectNotExists(project.android.hostAppGradleRoot.childFile('local.properties'));
      });
      testInMemory('injects plugins for iOS', () async {
        final FlutterProject project = await someProject();
        await project.ensureReadyForPlatformSpecificTooling();
        expectExists(project.ios.hostAppRoot.childDirectory('Runner').childFile('GeneratedPluginRegistrant.h'));
      });
      testInMemory('generates Xcode configuration for iOS', () async {
        final FlutterProject project = await someProject();
        await project.ensureReadyForPlatformSpecificTooling();
        expectExists(project.ios.hostAppRoot.childDirectory('Flutter').childFile('Generated.xcconfig'));
      });
      testInMemory('injects plugins for Android', () async {
        final FlutterProject project = await someProject();
        await project.ensureReadyForPlatformSpecificTooling();
        expectExists(androidPluginRegistrant(project.android.hostAppGradleRoot.childDirectory('app')));
      });
      testInMemory('updates local properties for Android', () async {
        final FlutterProject project = await someProject();
        await project.ensureReadyForPlatformSpecificTooling();
        expectExists(project.android.hostAppGradleRoot.childFile('local.properties'));
      });
      testInMemory('creates Android library in module', () async {
        final FlutterProject project = await aModuleProject();
        await project.ensureReadyForPlatformSpecificTooling();
        expectExists(project.android.hostAppGradleRoot.childFile('settings.gradle'));
        expectExists(project.android.hostAppGradleRoot.childFile('local.properties'));
        expectExists(androidPluginRegistrant(project.android.hostAppGradleRoot.childDirectory('Flutter')));
      });
      testInMemory('creates iOS pod in module', () async {
        final FlutterProject project = await aModuleProject();
        await project.ensureReadyForPlatformSpecificTooling();
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
    });

    group('module status', () {
      testInMemory('is known for module', () async {
        final FlutterProject project = await aModuleProject();
        expect(project.isModule, isTrue);
        expect(project.android.isModule, isTrue);
        expect(project.ios.isModule, isTrue);
        expect(project.android.hostAppGradleRoot.basename, '.android');
        expect(project.ios.hostAppRoot.basename, '.ios');
      });
      testInMemory('is known for non-module', () async {
        final FlutterProject project = await someProject();
        expect(project.isModule, isFalse);
        expect(project.android.isModule, isFalse);
        expect(project.ios.isModule, isFalse);
        expect(project.android.hostAppGradleRoot.basename, 'android');
        expect(project.ios.hostAppRoot.basename, 'ios');
      });
    });

    group('example', () {
      testInMemory('exists for plugin in legacy format', () async {
        final FlutterProject project = await aPluginProject();
        expect(project.hasExampleApp, isTrue);
      });
      testInMemory('exists for plugin in multi-platform format', () async {
        final FlutterProject project = await aPluginProject(legacy: false);
        expect(project.hasExampleApp, isTrue);
      });
      testInMemory('does not exist for non-plugin', () async {
        final FlutterProject project = await someProject();
        expect(project.hasExampleApp, isFalse);
      });
    });

    group('language', () {
      MockXcodeProjectInterpreter mockXcodeProjectInterpreter;
      MemoryFileSystem fs;
      FlutterProjectFactory flutterProjectFactory;
      setUp(() {
        fs = MemoryFileSystem();
        mockXcodeProjectInterpreter = MockXcodeProjectInterpreter();
        flutterProjectFactory = FlutterProjectFactory();
      });

      testInMemory('default host app language', () async {
        final FlutterProject project = await someProject();
        expect(project.ios.isSwift, isFalse);
        expect(project.android.isKotlin, isFalse);
      });

      testUsingContext('swift and kotlin host app language', () async {
        final FlutterProject project = await someProject();

        when(mockXcodeProjectInterpreter.getBuildSettings(any, any)).thenReturn(<String, String>{
          'SWIFT_VERSION': '4.0',
        });
        addAndroidGradleFile(project.directory,
          gradleFileContent: () {
      return '''
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
''';
        });
        expect(project.ios.isSwift, isTrue);
        expect(project.android.isKotlin, isTrue);
      }, overrides: <Type, Generator>{
          FileSystem: () => fs,
          XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
          FlutterProjectFactory: () => flutterProjectFactory,
      });
    });

    group('product bundle identifier', () {
      MemoryFileSystem fs;
      MockPlistUtils mockPlistUtils;
      MockXcodeProjectInterpreter mockXcodeProjectInterpreter;
      FlutterProjectFactory flutterProjectFactory;
      setUp(() {
        fs = MemoryFileSystem();
        mockPlistUtils = MockPlistUtils();
        mockXcodeProjectInterpreter = MockXcodeProjectInterpreter();
        flutterProjectFactory = FlutterProjectFactory();
      });

      void testWithMocks(String description, Future<void> testMethod()) {
        testUsingContext(description, testMethod, overrides: <Type, Generator>{
          FileSystem: () => fs,
          PlistParser: () => mockPlistUtils,
          XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
          FlutterProjectFactory: () => flutterProjectFactory,
        });
      }

      testWithMocks('null, if no pbxproj or plist entries', () async {
        final FlutterProject project = await someProject();
        expect(project.ios.productBundleIdentifier, isNull);
      });
      testWithMocks('from pbxproj file, if no plist', () async {
        final FlutterProject project = await someProject();
        addIosProjectFile(project.directory, projectFileContent: () {
          return projectFileWithBundleId('io.flutter.someProject');
        });
        expect(project.ios.productBundleIdentifier, 'io.flutter.someProject');
      });
      testWithMocks('from plist, if no variables', () async {
        final FlutterProject project = await someProject();
        when(mockPlistUtils.getValueFromFile(any, any)).thenReturn('io.flutter.someProject');
        expect(project.ios.productBundleIdentifier, 'io.flutter.someProject');
      });
      testWithMocks('from pbxproj and plist, if default variable', () async {
        final FlutterProject project = await someProject();
        addIosProjectFile(project.directory, projectFileContent: () {
          return projectFileWithBundleId('io.flutter.someProject');
        });
        when(mockPlistUtils.getValueFromFile(any, any)).thenReturn('\$(PRODUCT_BUNDLE_IDENTIFIER)');
        expect(project.ios.productBundleIdentifier, 'io.flutter.someProject');
      });
      testWithMocks('from pbxproj and plist, by substitution', () async {
        final FlutterProject project = await someProject();
        when(mockXcodeProjectInterpreter.getBuildSettings(any, any)).thenReturn(<String, String>{
          'PRODUCT_BUNDLE_IDENTIFIER': 'io.flutter.someProject',
          'SUFFIX': 'suffix',
        });
        when(mockPlistUtils.getValueFromFile(any, any)).thenReturn('\$(PRODUCT_BUNDLE_IDENTIFIER).\$(SUFFIX)');
        expect(project.ios.productBundleIdentifier, 'io.flutter.someProject.suffix');
      });
      testWithMocks('empty surrounded by quotes', () async {
        final FlutterProject project = await someProject();
        addIosProjectFile(project.directory, projectFileContent: () {
          return projectFileWithBundleId('', qualifier: '"');
        });
        expect(project.ios.productBundleIdentifier, '');
      });
      testWithMocks('surrounded by double quotes', () async {
        final FlutterProject project = await someProject();
        addIosProjectFile(project.directory, projectFileContent: () {
          return projectFileWithBundleId('io.flutter.someProject', qualifier: '"');
        });
        expect(project.ios.productBundleIdentifier, 'io.flutter.someProject');
      });
      testWithMocks('surrounded by single quotes', () async {
        final FlutterProject project = await someProject();
        addIosProjectFile(project.directory, projectFileContent: () {
          return projectFileWithBundleId('io.flutter.someProject', qualifier: '\'');
        });
        expect(project.ios.productBundleIdentifier, 'io.flutter.someProject');
      });
    });

    group('organization names set', () {
      testInMemory('is empty, if project not created', () async {
        final FlutterProject project = await someProject();
        expect(project.organizationNames, isEmpty);
      });
      testInMemory('is empty, if no platform folders exist', () async {
        final FlutterProject project = await someProject();
        project.directory.createSync();
        expect(project.organizationNames, isEmpty);
      });
      testInMemory('is populated from iOS bundle identifier', () async {
        final FlutterProject project = await someProject();
        addIosProjectFile(project.directory, projectFileContent: () {
          return projectFileWithBundleId('io.flutter.someProject', qualifier: '\'');
        });
        expect(project.organizationNames, <String>['io.flutter']);
      });
      testInMemory('is populated from Android application ID', () async {
        final FlutterProject project = await someProject();
        addAndroidGradleFile(project.directory,
          gradleFileContent: () {
            return gradleFileWithApplicationId('io.flutter.someproject');
          });
        expect(project.organizationNames, <String>['io.flutter']);
      });
      testInMemory('is populated from iOS bundle identifier in plugin example', () async {
        final FlutterProject project = await someProject();
        addIosProjectFile(project.example.directory, projectFileContent: () {
          return projectFileWithBundleId('io.flutter.someProject', qualifier: '\'');
        });
        expect(project.organizationNames, <String>['io.flutter']);
      });
      testInMemory('is populated from Android application ID in plugin example', () async {
        final FlutterProject project = await someProject();
        addAndroidGradleFile(project.example.directory,
          gradleFileContent: () {
            return gradleFileWithApplicationId('io.flutter.someproject');
          });
        expect(project.organizationNames, <String>['io.flutter']);
      });
      testInMemory('is populated from Android group in plugin', () async {
        final FlutterProject project = await someProject();
        addAndroidWithGroup(project.directory, 'io.flutter.someproject');
        expect(project.organizationNames, <String>['io.flutter']);
      });
      testInMemory('is singleton, if sources agree', () async {
        final FlutterProject project = await someProject();
        addIosProjectFile(project.directory, projectFileContent: () {
          return projectFileWithBundleId('io.flutter.someProject');
        });
        addAndroidGradleFile(project.directory,
          gradleFileContent: () {
            return gradleFileWithApplicationId('io.flutter.someproject');
          });
        expect(project.organizationNames, <String>['io.flutter']);
      });
      testInMemory('is non-singleton, if sources disagree', () async {
        final FlutterProject project = await someProject();
        addIosProjectFile(project.directory, projectFileContent: () {
          return projectFileWithBundleId('io.flutter.someProject');
        });
        addAndroidGradleFile(project.directory,
          gradleFileContent: () {
            return gradleFileWithApplicationId('io.clutter.someproject');
          });
        expect(
          project.organizationNames,
          <String>['io.flutter', 'io.clutter'],
        );
      });
    });
  });

  group('Regression test for invalid pubspec', () {
    Testbed testbed;
    FlutterProjectFactory flutterProjectFactory;

    setUp(() {
      testbed = Testbed();
      flutterProjectFactory = FlutterProjectFactory();
    });

    test('Handles asking for builders from an invalid pubspec', () => testbed.run(() {
      fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
# Hello, World
''');
      final FlutterProject flutterProject = FlutterProject.current();

      expect(flutterProject.builders, null);
    }, overrides: <Type, Generator>{
      FlutterProjectFactory: () => flutterProjectFactory,
    }));

    test('Handles asking for builders from a trivial pubspec', () => testbed.run(() {
      fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(r'''
# Hello, World
name: foo_bar
''');
      final FlutterProject flutterProject = FlutterProject.current();

      expect(flutterProject.builders, null);
    }, overrides: <Type, Generator>{
      FlutterProjectFactory: () => flutterProjectFactory,
    }));
  });
}

Future<FlutterProject> someProject() async {
  final Directory directory = fs.directory('some_project');
  directory.childFile('.packages').createSync(recursive: true);
  directory.childDirectory('ios').createSync(recursive: true);
  directory.childDirectory('android').createSync(recursive: true);
  return FlutterProject.fromDirectory(directory);
}

Future<FlutterProject> aPluginProject({bool legacy = true}) async {
  final Directory directory = fs.directory('plugin_project');
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
      macos:
        pluginClass: MyPlugin
''';
  }
  directory.childFile('pubspec.yaml').writeAsStringSync(pluginPubSpec);
  return FlutterProject.fromDirectory(directory);
}

Future<FlutterProject> aModuleProject() async {
  final Directory directory = fs.directory('module_project');
  directory.childFile('.packages').createSync(recursive: true);
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
void testInMemory(String description, Future<void> testMethod()) {
  Cache.flutterRoot = getFlutterRoot();
  final FileSystem testFileSystem = MemoryFileSystem(
    style: platform.isWindows ? FileSystemStyle.windows : FileSystemStyle.posix,
  );
  // Transfer needed parts of the Flutter installation folder
  // to the in-memory file system used during testing.
  transfer(Cache().getArtifactDirectory('gradle_wrapper'), testFileSystem);
  transfer(fs.directory(Cache.flutterRoot)
      .childDirectory('packages')
      .childDirectory('flutter_tools')
      .childDirectory('templates'), testFileSystem);
  transfer(fs.directory(Cache.flutterRoot)
      .childDirectory('packages')
      .childDirectory('flutter_tools')
      .childDirectory('schema'), testFileSystem);

  final FlutterProjectFactory flutterProjectFactory = FlutterProjectFactory();

  testUsingContext(
    description,
    testMethod,
    overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      Cache: () => Cache(),
      FlutterProjectFactory: () => flutterProjectFactory,
    },
  );
}

/// Transfers files and folders from the local file system's Flutter
/// installation to an (in-memory) file system used for testing.
void transfer(FileSystemEntity entity, FileSystem target) {
  if (entity is Directory) {
    target.directory(entity.absolute.path).createSync(recursive: true);
    for (FileSystemEntity child in entity.listSync()) {
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

void addIosProjectFile(Directory directory, {String projectFileContent()}) {
  directory
      .childDirectory('ios')
      .childDirectory('Runner.xcodeproj')
      .childFile('project.pbxproj')
        ..createSync(recursive: true)
    ..writeAsStringSync(projectFileContent());
}

void addAndroidGradleFile(Directory directory, { String gradleFileContent() }) {
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
    compileSdkVersion 28

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
    compileSdkVersion 28
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

class MockPlistUtils extends Mock implements PlistParser {}

class MockXcodeProjectInterpreter extends Mock implements XcodeProjectInterpreter {
  @override
  bool get isInstalled => true;
}
