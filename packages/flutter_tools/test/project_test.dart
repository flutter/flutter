// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/flutter_manifest.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:test/test.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('Project', () {
    group('construction', () {
      testInMemory('fails on null directory', () async {
        await expectLater(
          FlutterProject.fromDirectory(null),
          throwsA(const isInstanceOf<AssertionError>()),
        );
      });

      Future<Null> expectToolExitLater(Future<dynamic> future, Matcher messageMatcher) async {
        try {
          await future;
          fail('ToolExit expected, but nothing thrown');
        } on ToolExit catch(e) {
          expect(e.message, messageMatcher);
        } catch(e) {
          fail('ToolExit expected, got $e');
        }
      }

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

    group('ensure ready for platform-specific tooling', () {
      testInMemory('does nothing, if project is not created', () async {
        final FlutterProject project = new FlutterProject(
          fs.directory('not_created'),
          FlutterManifest.empty(),
          FlutterManifest.empty(),
        );
        await project.ensureReadyForPlatformSpecificTooling();
        expect(project.directory.existsSync(), isFalse);
      });
      testInMemory('does nothing in plugin or package root project', () async {
        final FlutterProject project = await aPluginProject();
        await project.ensureReadyForPlatformSpecificTooling();
        expect(project.ios.directory.childFile('Runner/GeneratedPluginRegistrant.h').existsSync(), isFalse);
        expect(project.android.directory.childFile(
          'app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java',
        ).existsSync(), isFalse);
        expect(project.ios.directory.childFile('Flutter/Generated.xcconfig').existsSync(), isFalse);
        expect(project.android.directory.childFile('local.properties').existsSync(), isFalse);
      });
      testInMemory('injects plugins for iOS', () async {
        final FlutterProject project = await someProject();
        await project.ensureReadyForPlatformSpecificTooling();
        expect(project.ios.directory.childFile('Runner/GeneratedPluginRegistrant.h').existsSync(), isTrue);
      });
      testInMemory('generates Xcode configuration for iOS', () async {
        final FlutterProject project = await someProject();
        await project.ensureReadyForPlatformSpecificTooling();
        expect(project.ios.directory.childFile('Flutter/Generated.xcconfig').existsSync(), isTrue);
      });
      testInMemory('injects plugins for Android', () async {
        final FlutterProject project = await someProject();
        await project.ensureReadyForPlatformSpecificTooling();
        expect(project.android.directory.childFile(
          'app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java',
        ).existsSync(), isTrue);
      });
      testInMemory('updates local properties for Android', () async {
        final FlutterProject project = await someProject();
        await project.ensureReadyForPlatformSpecificTooling();
        expect(project.android.directory.childFile('local.properties').existsSync(), isTrue);
      });
      testInMemory('creates Android library in module', () async {
        final FlutterProject project = await aModuleProject();
        await project.ensureReadyForPlatformSpecificTooling();
        expect(project.android.directory.childFile('settings.gradle').existsSync(), isTrue);
        expect(project.android.directory.childFile('local.properties').existsSync(), isTrue);
        expect(project.android.directory.childFile(
          'Flutter/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java',
        ).existsSync(), isTrue);
      });
      testInMemory('creates iOS pod in module', () async {
        final FlutterProject project = await aModuleProject();
        await project.ensureReadyForPlatformSpecificTooling();
        final Directory flutter = project.ios.directory.childDirectory('Flutter');
        expect(flutter.childFile('podhelper.rb').existsSync(), isTrue);
        expect(flutter.childFile('Generated.xcconfig').existsSync(), isTrue);
        expect(flutter.childFile(
          'FlutterPluginRegistrant/Classes/GeneratedPluginRegistrant.h',
        ).existsSync(), isTrue);
        expect(flutter.childFile(
          'FlutterPluginRegistrant/Classes/GeneratedPluginRegistrant.m',
        ).existsSync(), isTrue);
      });
    });

    group('module status', () {
      testInMemory('is known for module', () async {
        final FlutterProject project = await aModuleProject();
        expect(project.isModule, isTrue);
        expect(project.android.isModule, isTrue);
        expect(project.ios.isModule, isTrue);
        expect(project.android.directory.path, startsWith('module_project/.android'));
        expect(project.ios.directory.path, startsWith('module_project/.ios'));
      });
      testInMemory('is known for non-module', () async {
        final FlutterProject project = await someProject();
        expect(project.isModule, isFalse);
        expect(project.android.isModule, isFalse);
        expect(project.ios.isModule, isFalse);
        expect(project.android.directory.path, startsWith('some_project/android'));
        expect(project.ios.directory.path, startsWith('some_project/ios'));
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

    group('organization names set', () {
      testInMemory('is empty, if project not created', () async {
        final FlutterProject project = await someProject();
        expect(await project.organizationNames(), isEmpty);
      });
      testInMemory('is empty, if no platform folders exist', () async {
        final FlutterProject project = await someProject();
        project.directory.createSync();
        expect(await project.organizationNames(), isEmpty);
      });
      testInMemory('is populated from iOS bundle identifier', () async {
        final FlutterProject project = await someProject();
        addIosWithBundleId(project.directory, 'io.flutter.someProject');
        expect(await project.organizationNames(), <String>['io.flutter']);
      });
      testInMemory('is populated from Android application ID', () async {
        final FlutterProject project = await someProject();
        addAndroidWithApplicationId(project.directory, 'io.flutter.someproject');
        expect(await project.organizationNames(), <String>['io.flutter']);
      });
      testInMemory('is populated from iOS bundle identifier in plugin example', () async {
        final FlutterProject project = await someProject();
        addIosWithBundleId(project.example.directory, 'io.flutter.someProject');
        expect(await project.organizationNames(), <String>['io.flutter']);
      });
      testInMemory('is populated from Android application ID in plugin example', () async {
        final FlutterProject project = await someProject();
        addAndroidWithApplicationId(project.example.directory, 'io.flutter.someproject');
        expect(await project.organizationNames(), <String>['io.flutter']);
      });
      testInMemory('is populated from Android group in plugin', () async {
        final FlutterProject project = await someProject();
        addAndroidWithGroup(project.directory, 'io.flutter.someproject');
        expect(await project.organizationNames(), <String>['io.flutter']);
      });
      testInMemory('is singleton, if sources agree', () async {
        final FlutterProject project = await someProject();
        addIosWithBundleId(project.directory, 'io.flutter.someProject');
        addAndroidWithApplicationId(project.directory, 'io.flutter.someproject');
        expect(await project.organizationNames(), <String>['io.flutter']);
      });
      testInMemory('is non-singleton, if sources disagree', () async {
        final FlutterProject project = await someProject();
        addIosWithBundleId(project.directory, 'io.flutter.someProject');
        addAndroidWithApplicationId(project.directory, 'io.clutter.someproject');
        expect(
          await project.organizationNames(),
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
void testInMemory(String description, Future<Null> testMethod()) {
  Cache.flutterRoot = getFlutterRoot();
  final FileSystem testFileSystem = new MemoryFileSystem();
  // Transfer needed parts of the Flutter installation folder
  // to the in-memory file system used during testing.
  transfer(new Cache().getArtifactDirectory('gradle_wrapper'), testFileSystem);
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
      Cache: () => new Cache(),
    },
  );
}

/// Transfers files and folders from the local file system's Flutter
/// installation to an (in-memory) file system used for testing.
void transfer(FileSystemEntity entity, FileSystem target) {
  if (entity is Directory) {
    target.directory(entity.path).createSync(recursive: true);
    for (FileSystemEntity child in entity.listSync()) {
      transfer(child, target);
    }
  } else if (entity is File) {
    target.file(entity.path).writeAsBytesSync(entity.readAsBytesSync(), flush: true);
  } else {
    throw 'Unsupported FileSystemEntity ${entity.runtimeType}';
  }
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
