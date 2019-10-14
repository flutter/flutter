// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/dart/package_map.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/plugins.dart';
import 'package:flutter_tools/src/project.dart';

import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  FileSystem fs;
  MockFlutterProject flutterProject;
  MockIosProject iosProject;
  MockMacOSProject macosProject;
  MockAndroidProject androidProject;
  File packagesFile;
  Directory dummyPackageDirectory;

  setUp(() async {
    fs = MemoryFileSystem();

    // Add basic properties to the Flutter project and subprojects
    flutterProject = MockFlutterProject();
    when(flutterProject.directory).thenReturn(fs.directory('/'));
    when(flutterProject.flutterPluginsFile).thenReturn(flutterProject.directory.childFile('.plugins'));
    iosProject = MockIosProject();
    when(flutterProject.ios).thenReturn(iosProject);
    when(iosProject.pluginRegistrantHost).thenReturn(flutterProject.directory.childDirectory('Runner'));
    when(iosProject.podfile).thenReturn(flutterProject.directory.childDirectory('ios').childFile('Podfile'));
    when(iosProject.podManifestLock).thenReturn(flutterProject.directory.childDirectory('ios').childFile('Podfile.lock'));
    macosProject = MockMacOSProject();
    when(flutterProject.macos).thenReturn(macosProject);
    when(macosProject.podfile).thenReturn(flutterProject.directory.childDirectory('macos').childFile('Podfile'));
    when(macosProject.podManifestLock).thenReturn(flutterProject.directory.childDirectory('macos').childFile('Podfile.lock'));
    androidProject = MockAndroidProject();
    when(flutterProject.android).thenReturn(androidProject);
    when(androidProject.pluginRegistrantHost).thenReturn(flutterProject.directory.childDirectory('android').childDirectory('app'));
    when(androidProject.hostAppGradleRoot).thenReturn(flutterProject.directory.childDirectory('android'));

    // Set up a simple .packages file for all the tests to use, pointing to one package.
    dummyPackageDirectory = fs.directory('/pubcache/apackage/lib/');
    packagesFile = fs.file(fs.path.join(flutterProject.directory.path, PackageMap.globalPackagesPath));
    packagesFile..createSync(recursive: true)
        ..writeAsStringSync('apackage:file://${dummyPackageDirectory.path}');
  });

  // Makes the dummy package pointed to by packagesFile look like a plugin.
  void configureDummyPackageAsPlugin() {
    dummyPackageDirectory.parent.childFile('pubspec.yaml')..createSync(recursive: true)..writeAsStringSync('''
flutter:
  plugin:
    platforms:
      ios:
        pluginClass: FLESomePlugin
''');
  }

  // Creates the files that would indicate that pod install has run for the
  // given project.
  void simulatePodInstallRun(XcodeBasedProject project) {
    project.podManifestLock.createSync(recursive: true);
  }

  group('refreshPlugins', () {
    testUsingContext('Refreshing the plugin list is a no-op when the plugins list stays empty', () {
      refreshPluginsList(flutterProject);
      expect(flutterProject.flutterPluginsFile.existsSync(), false);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager(<FakeCommand>[]),
    });

    testUsingContext('Refreshing the plugin list deletes the plugin file when there were plugins but no longer are', () {
      flutterProject.flutterPluginsFile.createSync();
      when(iosProject.existsSync()).thenReturn(false);
      when(macosProject.existsSync()).thenReturn(false);
      refreshPluginsList(flutterProject);
      expect(flutterProject.flutterPluginsFile.existsSync(), false);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager(<FakeCommand>[]),
    });

    testUsingContext('Refreshing the plugin list creates a plugin directory when there are plugins', () {
      configureDummyPackageAsPlugin();
      when(iosProject.existsSync()).thenReturn(false);
      when(macosProject.existsSync()).thenReturn(false);
      refreshPluginsList(flutterProject);
      expect(flutterProject.flutterPluginsFile.existsSync(), true);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager(<FakeCommand>[]),
    });

    testUsingContext('Changes to the plugin list invalidates the Cocoapod lockfiles', () {
      simulatePodInstallRun(iosProject);
      simulatePodInstallRun(macosProject);
      configureDummyPackageAsPlugin();
      when(iosProject.existsSync()).thenReturn(true);
      when(macosProject.existsSync()).thenReturn(true);
      refreshPluginsList(flutterProject);
      expect(iosProject.podManifestLock.existsSync(), false);
      expect(macosProject.podManifestLock.existsSync(), false);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager(<FakeCommand>[]),
    });
  });

  group('injectPlugins', () {
    MockFeatureFlags featureFlags;
    MockXcodeProjectInterpreter xcodeProjectInterpreter;

    const String kAndroidManifestUsingOldEmbedding = '''
<manifest>
    <application>
    </application>
</manifest>
''';
    const String kAndroidManifestUsingNewEmbedding = '''
<manifest>
    <application>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
''';

    setUp(() {
      featureFlags = MockFeatureFlags();
      when(featureFlags.isLinuxEnabled).thenReturn(false);
      when(featureFlags.isMacOSEnabled).thenReturn(false);
      when(featureFlags.isWindowsEnabled).thenReturn(false);
      when(featureFlags.isWebEnabled).thenReturn(false);

      xcodeProjectInterpreter = MockXcodeProjectInterpreter();
      when(xcodeProjectInterpreter.isInstalled).thenReturn(false);
    });

    testUsingContext('Registrant uses old embedding in app project', () async {
      when(flutterProject.isModule).thenReturn(false);
      when(featureFlags.isNewAndroidEmbeddingEnabled).thenReturn(false);

      await injectPlugins(flutterProject);

      final File registrant = flutterProject.directory
        .childDirectory(fs.path.join('android', 'app', 'src', 'main', 'java', 'io', 'flutter', 'plugins'))
        .childFile('GeneratedPluginRegistrant.java');

      expect(registrant.existsSync(), isTrue);
      expect(registrant.readAsStringSync(), contains('package io.flutter.plugins'));
      expect(registrant.readAsStringSync(), contains('class GeneratedPluginRegistrant'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager(<FakeCommand>[]),
      FeatureFlags: () => featureFlags,
    });

    testUsingContext('Registrant uses new embedding if app uses new embedding', () async {
      when(flutterProject.isModule).thenReturn(false);
      when(featureFlags.isNewAndroidEmbeddingEnabled).thenReturn(true);

      final File androidManifest = flutterProject.directory
        .childDirectory('android')
        .childFile('AndroidManifest.xml')
        ..createSync(recursive: true)
        ..writeAsStringSync(kAndroidManifestUsingNewEmbedding);
      when(androidProject.appManifestFile).thenReturn(androidManifest);

      await injectPlugins(flutterProject);

      final File registrant = flutterProject.directory
        .childDirectory(fs.path.join('android', 'app', 'src', 'main', 'java', 'dev', 'flutter', 'plugins'))
        .childFile('GeneratedPluginRegistrant.java');

      expect(registrant.existsSync(), isTrue);
      expect(registrant.readAsStringSync(), contains('package dev.flutter.plugins'));
      expect(registrant.readAsStringSync(), contains('class GeneratedPluginRegistrant'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager(<FakeCommand>[]),
      FeatureFlags: () => featureFlags,
    });

    testUsingContext('Registrant uses shim for plugins using old embedding if app uses new embedding', () async {
      when(flutterProject.isModule).thenReturn(false);
      when(featureFlags.isNewAndroidEmbeddingEnabled).thenReturn(true);

      final File androidManifest = flutterProject.directory
        .childDirectory('android')
        .childFile('AndroidManifest.xml')
        ..createSync(recursive: true)
        ..writeAsStringSync(kAndroidManifestUsingNewEmbedding);
      when(androidProject.appManifestFile).thenReturn(androidManifest);

      final Directory pluginUsingJavaAndNewEmbeddingDir =
        fs.systemTempDirectory.createTempSync('flutter_plugin_using_java_and_new_embedding_dir.');
      pluginUsingJavaAndNewEmbeddingDir
        .childFile('pubspec.yaml')
        .writeAsStringSync('''
flutter:
  plugin:
    androidPackage: plugin1
    pluginClass: UseNewEmbedding
''');
      pluginUsingJavaAndNewEmbeddingDir
        .childDirectory('android')
        .childDirectory('src')
        .childDirectory('main')
        .childDirectory('java')
        .childDirectory('plugin1')
        .childFile('UseNewEmbedding.java')
        ..createSync(recursive: true)
        ..writeAsStringSync('import io.flutter.embedding.engine.plugins.FlutterPlugin;');

      final Directory pluginUsingKotlinAndNewEmbeddingDir =
        fs.systemTempDirectory.createTempSync('flutter_plugin_using_kotlin_and_new_embedding_dir.');
      pluginUsingKotlinAndNewEmbeddingDir
        .childFile('pubspec.yaml')
        .writeAsStringSync('''
flutter:
  plugin:
    androidPackage: plugin2
    pluginClass: UseNewEmbedding
''');
      pluginUsingKotlinAndNewEmbeddingDir
        .childDirectory('android')
        .childDirectory('src')
        .childDirectory('main')
        .childDirectory('kotlin')
        .childDirectory('plugin2')
        .childFile('UseNewEmbedding.kt')
        ..createSync(recursive: true)
        ..writeAsStringSync('import io.flutter.embedding.engine.plugins.FlutterPlugin');

      final Directory pluginUsingOldEmbeddingDir =
        fs.systemTempDirectory.createTempSync('flutter_plugin_using_old_embedding_dir.');
      pluginUsingOldEmbeddingDir
        .childFile('pubspec.yaml')
        .writeAsStringSync('''
flutter:
  plugin:
    androidPackage: plugin3
    pluginClass: UseOldEmbedding
''');
      pluginUsingOldEmbeddingDir
        .childDirectory('android')
        .childDirectory('src')
        .childDirectory('main')
        .childDirectory('java')
        .childDirectory('plugin3')
        .childFile('UseOldEmbedding.java')
        ..createSync(recursive: true);

      flutterProject.directory
        .childFile('.packages')
        .writeAsStringSync('''
plugin1:${pluginUsingJavaAndNewEmbeddingDir.childDirectory('lib').uri.toString()}
plugin2:${pluginUsingKotlinAndNewEmbeddingDir.childDirectory('lib').uri.toString()}
plugin3:${pluginUsingOldEmbeddingDir.childDirectory('lib').uri.toString()}
''');

      await injectPlugins(flutterProject);

      final File registrant = flutterProject.directory
        .childDirectory(fs.path.join('android', 'app', 'src', 'main', 'java', 'dev', 'flutter', 'plugins'))
        .childFile('GeneratedPluginRegistrant.java');

      expect(registrant.readAsStringSync(),
        contains('flutterEngine.getPlugins().add(new plugin1.UseNewEmbedding());'));
      expect(registrant.readAsStringSync(),
        contains('flutterEngine.getPlugins().add(new plugin2.UseNewEmbedding());'));
      expect(registrant.readAsStringSync(),
        contains('plugin3.UseOldEmbedding.registerWith(shimPluginRegistry.registrarFor("plugin3.UseOldEmbedding"));'));

    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager(<FakeCommand>[]),
      FeatureFlags: () => featureFlags,
      XcodeProjectInterpreter: () => xcodeProjectInterpreter,
    });

    testUsingContext('Registrant doesn\'t use new embedding if app doesn\'t use new embedding', () async {
      when(flutterProject.isModule).thenReturn(false);
      when(featureFlags.isNewAndroidEmbeddingEnabled).thenReturn(true);

      final File androidManifest = flutterProject.directory
        .childDirectory('android')
        .childFile('AndroidManifest.xml')
        ..createSync(recursive: true)
        ..writeAsStringSync(kAndroidManifestUsingOldEmbedding);
      when(androidProject.appManifestFile).thenReturn(androidManifest);

      await injectPlugins(flutterProject);

      final File registrant = flutterProject.directory
        .childDirectory(fs.path.join('android', 'app', 'src', 'main', 'java', 'io', 'flutter', 'plugins'))
        .childFile('GeneratedPluginRegistrant.java');

      expect(registrant.existsSync(), isTrue);
      expect(registrant.readAsStringSync(), contains('package io.flutter.plugins'));
      expect(registrant.readAsStringSync(), contains('class GeneratedPluginRegistrant'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager(<FakeCommand>[]),
      FeatureFlags: () => featureFlags,
    });

    testUsingContext('Registrant uses old embedding in module project', () async {
      when(flutterProject.isModule).thenReturn(true);
      when(featureFlags.isNewAndroidEmbeddingEnabled).thenReturn(false);

      await injectPlugins(flutterProject);

      final File registrant = flutterProject.directory
        .childDirectory(fs.path.join('android', 'app', 'src', 'main', 'java', 'io', 'flutter', 'plugins'))
        .childFile('GeneratedPluginRegistrant.java');

      expect(registrant.existsSync(), isTrue);
      expect(registrant.readAsStringSync(), contains('package io.flutter.plugins'));
      expect(registrant.readAsStringSync(), contains('class GeneratedPluginRegistrant'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager(<FakeCommand>[]),
      FeatureFlags: () => featureFlags,
    });

    testUsingContext('Registrant uses new embedding if module uses new embedding', () async {
      when(flutterProject.isModule).thenReturn(true);
      when(featureFlags.isNewAndroidEmbeddingEnabled).thenReturn(true);

      final File androidManifest = flutterProject.directory
        .childDirectory('android')
        .childFile('AndroidManifest.xml')
        ..createSync(recursive: true)
        ..writeAsStringSync(kAndroidManifestUsingNewEmbedding);
      when(androidProject.appManifestFile).thenReturn(androidManifest);

      await injectPlugins(flutterProject);

      final File registrant = flutterProject.directory
        .childDirectory(fs.path.join('android', 'app', 'src', 'main', 'java', 'dev', 'flutter', 'plugins'))
        .childFile('GeneratedPluginRegistrant.java');

      expect(registrant.existsSync(), isTrue);
      expect(registrant.readAsStringSync(), contains('package dev.flutter.plugins'));
      expect(registrant.readAsStringSync(), contains('class GeneratedPluginRegistrant'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager(<FakeCommand>[]),
      FeatureFlags: () => featureFlags,
    });

    testUsingContext('Registrant doesn\'t use new embedding if module doesn\'t use new embedding', () async {
      when(flutterProject.isModule).thenReturn(true);
      when(featureFlags.isNewAndroidEmbeddingEnabled).thenReturn(true);

      final File androidManifest = flutterProject.directory
        .childDirectory('android')
        .childFile('AndroidManifest.xml')
        ..createSync(recursive: true)
        ..writeAsStringSync(kAndroidManifestUsingOldEmbedding);
      when(androidProject.appManifestFile).thenReturn(androidManifest);

      await injectPlugins(flutterProject);

      final File registrant = flutterProject.directory
        .childDirectory(fs.path.join('android', 'app', 'src', 'main', 'java', 'io', 'flutter', 'plugins'))
        .childFile('GeneratedPluginRegistrant.java');

      expect(registrant.existsSync(), isTrue);
      expect(registrant.readAsStringSync(), contains('package io.flutter.plugins'));
      expect(registrant.readAsStringSync(), contains('class GeneratedPluginRegistrant'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager(<FakeCommand>[]),
      FeatureFlags: () => featureFlags,
    });
  });
}

class MockAndroidProject extends Mock implements AndroidProject {}
class MockFeatureFlags extends Mock implements FeatureFlags {}
class MockFlutterProject extends Mock implements FlutterProject {}
class MockIosProject extends Mock implements IosProject {}
class MockMacOSProject extends Mock implements MacOSProject {}
class MockXcodeProjectInterpreter extends Mock implements XcodeProjectInterpreter {}
