// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/dart/package_map.dart';
import 'package:flutter_tools/src/plugins.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';

class MockFlutterProject extends Mock implements FlutterProject {}
class MockIosProject extends Mock implements IosProject {}
class MockMacOSProject extends Mock implements MacOSProject {}

void main() {
  FileSystem fs;
  MockFlutterProject flutterProject;
  MockIosProject iosProject;
  MockMacOSProject macosProject;
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
    when(iosProject.podManifestLock).thenReturn(flutterProject.directory.childDirectory('ios').childFile('Podfile.lock'));
    macosProject = MockMacOSProject();
    when(flutterProject.macos).thenReturn(macosProject);
    when(macosProject.podManifestLock).thenReturn(flutterProject.directory.childDirectory('macos').childFile('Podfile.lock'));

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
    });

    testUsingContext('Refreshing the plugin list deletes the plugin file when there were plugins but no longer are', () {
      flutterProject.flutterPluginsFile.createSync();
      when(iosProject.existsSync()).thenReturn(false);
      when(macosProject.existsSync()).thenReturn(false);
      refreshPluginsList(flutterProject);
      expect(flutterProject.flutterPluginsFile.existsSync(), false);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
    });

    testUsingContext('Refreshing the plugin list creates a plugin directory when there are plugins', () {
      configureDummyPackageAsPlugin();
      when(iosProject.existsSync()).thenReturn(false);
      when(macosProject.existsSync()).thenReturn(false);
      refreshPluginsList(flutterProject);
      expect(flutterProject.flutterPluginsFile.existsSync(), true);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
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
    });
  });
}
