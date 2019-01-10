// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/flutter_manifest.dart';
import 'package:flutter_tools/src/ios/ios_workflow.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mockito/mockito.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('Project', () {
    group('construction', () {
      testInMemory('fails on null directory', () async {
        await expectLater(
          FlutterProject.fromDirectory(null),
          throwsA(isInstanceOf<AssertionError>()),
        );
      });

      testInMemory('fails on invalid pubspec.yaml', () async {
        final Directory directory = fs.directory('myproject');
        directory.childFile('pubspec.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync(invalidPubspec);
        await expectToolExitLater(
          FlutterProject.fromDirectory(directory),
          contains('pubspec.yaml'),
        );
      });

      testInMemory('fails on invalid example/pubspec.yaml', () async {
        final Directory directory = fs.directory('myproject');
        directory.childDirectory('example').childFile('pubspec.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync(invalidPubspec);
        await expectToolExitLater(
          FlutterProject.fromDirectory(directory),
          contains('pubspec.yaml'),
        );
      });

      testInMemory('treats missing pubspec.yaml as empty', () async {
        final Directory directory = fs.directory('myproject')
          ..createSync(recursive: true);
        expect(
          (await FlutterProject.fromDirectory(directory)).manifest.isEmpty,
          true,
        );
      });

      testInMemory('reads valid pubspec.yaml', () async {
        final Directory directory = fs.directory('myproject');
        directory.childFile('pubspec.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync(validPubspec);
        expect(
          (await FlutterProject.fromDirectory(directory)).manifest.appName,
          'hello',
        );
      });

      testInMemory('sets up location', () async {
        final Directory directory = fs.directory('myproject');
        expect(
          (await FlutterProject.fromDirectory(directory)).directory.absolute.path,
          directory.absolute.path,
        );
        expect(
          (await FlutterProject.fromPath(directory.path)).directory.absolute.path,
          directory.absolute.path,
        );
        expect(
          (await FlutterProject.current()).directory.absolute.path,
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
          contains('../.android/include_flutter.groovy'),
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
      testInMemory('exists for plugin', () async {
        final FlutterProject project = await aPluginProject();
        expect(project.hasExampleApp, isTrue);
      });
      testInMemory('does not exist for non-plugin', () async {
        final FlutterProject project = await someProject();
        expect(project.hasExampleApp, isFalse);
      });
    });

    group('product bundle identifier', () {
      MemoryFileSystem fs;
      MockIOSWorkflow mockIOSWorkflow;
      MockXcodeProjectInterpreter mockXcodeProjectInterpreter;
      setUp(() {
        fs = MemoryFileSystem();
        mockIOSWorkflow = MockIOSWorkflow();
        mockXcodeProjectInterpreter = MockXcodeProjectInterpreter();
      });

      void testWithMocks(String description, Future<void> testMethod()) {
        testUsingContext(description, testMethod, overrides: <Type, Generator>{
          FileSystem: () => fs,
          IOSWorkflow: () => mockIOSWorkflow,
          XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
        });
      }

      testWithMocks('null, if no pbxproj or plist entries', () async {
        final FlutterProject project = await someProject();
        expect(project.ios.productBundleIdentifier, isNull);
      });
      testWithMocks('from pbxproj file, if no plist', () async {
        final FlutterProject project = await someProject();
        addIosWithBundleId(project.directory, 'io.flutter.someProject');
        expect(project.ios.productBundleIdentifier, 'io.flutter.someProject');
      });
      testWithMocks('from plist, if no variables', () async {
        final FlutterProject project = await someProject();
        when(mockIOSWorkflow.getPlistValueFromFile(any, any)).thenReturn('io.flutter.someProject');
        expect(project.ios.productBundleIdentifier, 'io.flutter.someProject');
      });
      testWithMocks('from pbxproj and plist, if default variable', () async {
        final FlutterProject project = await someProject();
        addIosWithBundleId(project.directory, 'io.flutter.someProject');
        when(mockIOSWorkflow.getPlistValueFromFile(any, any)).thenReturn('\$(PRODUCT_BUNDLE_IDENTIFIER)');
        expect(project.ios.productBundleIdentifier, 'io.flutter.someProject');
      });
      testWithMocks('from pbxproj and plist, by substitution', () async {
        final FlutterProject project = await someProject();
        when(mockXcodeProjectInterpreter.getBuildSettings(any, any)).thenReturn(<String, String>{
          'PRODUCT_BUNDLE_IDENTIFIER': 'io.flutter.someProject',
          'SUFFIX': 'suffix',
        });
        when(mockIOSWorkflow.getPlistValueFromFile(any, any)).thenReturn('\$(PRODUCT_BUNDLE_IDENTIFIER).\$(SUFFIX)');
        expect(project.ios.productBundleIdentifier, 'io.flutter.someProject.suffix');
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
        addIosWithBundleId(project.directory, 'io.flutter.someProject');
        expect(project.organizationNames, <String>['io.flutter']);
      });
      testInMemory('is populated from Android application ID', () async {
        final FlutterProject project = await someProject();
        addAndroidWithApplicationId(project.directory, 'io.flutter.someproject');
        expect(project.organizationNames, <String>['io.flutter']);
      });
      testInMemory('is populated from iOS bundle identifier in plugin example', () async {
        final FlutterProject project = await someProject();
        addIosWithBundleId(project.example.directory, 'io.flutter.someProject');
        expect(project.organizationNames, <String>['io.flutter']);
      });
      testInMemory('is populated from Android application ID in plugin example', () async {
        final FlutterProject project = await someProject();
        addAndroidWithApplicationId(project.example.directory, 'io.flutter.someproject');
        expect(project.organizationNames, <String>['io.flutter']);
      });
      testInMemory('is populated from Android group in plugin', () async {
        final FlutterProject project = await someProject();
        addAndroidWithGroup(project.directory, 'io.flutter.someproject');
        expect(project.organizationNames, <String>['io.flutter']);
      });
      testInMemory('is singleton, if sources agree', () async {
        final FlutterProject project = await someProject();
        addIosWithBundleId(project.directory, 'io.flutter.someProject');
        addAndroidWithApplicationId(project.directory, 'io.flutter.someproject');
        expect(project.organizationNames, <String>['io.flutter']);
      });
      testInMemory('is non-singleton, if sources disagree', () async {
        final FlutterProject project = await someProject();
        addIosWithBundleId(project.directory, 'io.flutter.someProject');
        addAndroidWithApplicationId(project.directory, 'io.clutter.someproject');
        expect(
          project.organizationNames,
          <String>['io.flutter', 'io.clutter'],
        );
      });
    });
  });
}

Future<FlutterProject> someProject() async {
  final Directory directory = fs.directory('some_project');
  directory.childFile('.packages').createSync(recursive: true);
  directory.childDirectory('ios').createSync(recursive: true);
  directory.childDirectory('android').createSync(recursive: true);
  return FlutterProject.fromDirectory(directory);
}

Future<FlutterProject> aPluginProject() async {
  final Directory directory = fs.directory('plugin_project');
  directory.childDirectory('ios').createSync(recursive: true);
  directory.childDirectory('android').createSync(recursive: true);
  directory.childDirectory('example').createSync(recursive: true);
  directory.childFile('pubspec.yaml').writeAsStringSync('''
name: my_plugin
flutter:
  plugin:
    androidPackage: com.example
    pluginClass: MyPlugin
    iosPrefix: FLT
''');
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
  testUsingContext(
    description,
    testMethod,
    overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
      Cache: () => Cache(),
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

Future<void> expectToolExitLater(Future<dynamic> future, Matcher messageMatcher) async {
  try {
    await future;
    fail('ToolExit expected, but nothing thrown');
  } on ToolExit catch(e) {
    expect(e.message, messageMatcher);
  } catch(e, trace) {
    fail('ToolExit expected, got $e\n$trace');
  }
}

void expectExists(FileSystemEntity entity) {
  expect(entity.existsSync(), isTrue);
}

void expectNotExists(FileSystemEntity entity) {
  expect(entity.existsSync(), isFalse);
}

void addIosWithBundleId(Directory directory, String id) {
  directory
      .childDirectory('ios')
      .childDirectory('Runner.xcodeproj')
      .childFile('project.pbxproj')
        ..createSync(recursive: true)
        ..writeAsStringSync(projectFileWithBundleId(id));
}

void addAndroidWithApplicationId(Directory directory, String id) {
  directory
      .childDirectory('android')
      .childDirectory('app')
      .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync(gradleFileWithApplicationId(id));
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

String projectFileWithBundleId(String id) {
  return '''
97C147061CF9000F007C117D /* Debug */ = {
  isa = XCBuildConfiguration;
  baseConfigurationReference = 9740EEB21CF90195004384FC /* Debug.xcconfig */;
  buildSettings = {
    PRODUCT_BUNDLE_IDENTIFIER = $id;
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
    compileSdkVersion 27

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
    compileSdkVersion 27
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

class MockIOSWorkflow extends Mock implements IOSWorkflow {}

class MockXcodeProjectInterpreter extends Mock implements XcodeProjectInterpreter {
  @override
  bool get isInstalled => true;
}
