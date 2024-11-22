// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../src/common.dart';
import '../src/context.dart';


void main() {
  group('IosProject', () {
    testWithoutContext('managedDirectory', () {
      final MemoryFileSystem fs = MemoryFileSystem.test();
      final IosProject project = IosProject.fromFlutter(
        FakeFlutterProject(fileSystem: fs),
      );
      expect(project.managedDirectory.path, 'app_name/ios/Flutter');
    });

    testWithoutContext('module managedDirectory', () {
      final MemoryFileSystem fs = MemoryFileSystem.test();
      final IosProject project = IosProject.fromFlutter(
        FakeFlutterProject(fileSystem: fs, isModule: true),
      );
      expect(project.managedDirectory.path, 'app_name/.ios/Flutter');
    });

    testWithoutContext('ephemeralDirectory', () {
      final MemoryFileSystem fs = MemoryFileSystem.test();
      final IosProject project = IosProject.fromFlutter(
        FakeFlutterProject(fileSystem: fs),
      );
      expect(project.ephemeralDirectory.path, 'app_name/ios/Flutter/ephemeral');
    });

    testWithoutContext('module ephemeralDirectory', () {
      final MemoryFileSystem fs = MemoryFileSystem.test();
      final IosProject project = IosProject.fromFlutter(
        FakeFlutterProject(fileSystem: fs, isModule: true),
      );
      expect(project.ephemeralDirectory.path, 'app_name/.ios/Flutter/ephemeral');
    });

    testWithoutContext('flutterPluginSwiftPackageDirectory', () {
      final MemoryFileSystem fs = MemoryFileSystem.test();
      final IosProject project = IosProject.fromFlutter(
        FakeFlutterProject(fileSystem: fs),
      );
      expect(
        project.flutterPluginSwiftPackageDirectory.path,
        'app_name/ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage',
      );
    });

    testWithoutContext('module flutterPluginSwiftPackageDirectory', () {
      final MemoryFileSystem fs = MemoryFileSystem.test();
      final IosProject project = IosProject.fromFlutter(
        FakeFlutterProject(fileSystem: fs, isModule: true),
      );
      expect(
        project.flutterPluginSwiftPackageDirectory.path,
        'app_name/.ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage',
      );
    });

    testWithoutContext('xcodeConfigFor', () {
      final MemoryFileSystem fs = MemoryFileSystem.test();
      final IosProject project = IosProject.fromFlutter(
        FakeFlutterProject(fileSystem: fs),
      );
      expect(
        project.xcodeConfigFor('Debug').path,
        'app_name/ios/Flutter/Debug.xcconfig',
      );
    });

    group('projectInfo', () {
      testUsingContext('is null if XcodeProjectInterpreter is null', () async {
        final MemoryFileSystem fs = MemoryFileSystem.test();
        final IosProject project = IosProject.fromFlutter(
          FakeFlutterProject(fileSystem: fs),
        );
        project.xcodeProject.createSync(recursive: true);
        expect(await project.projectInfo(), isNull);
      }, overrides: <Type, Generator>{
        XcodeProjectInterpreter: () => null,
      });

      testUsingContext('is null if XcodeProjectInterpreter is not installed', () async {
        final MemoryFileSystem fs = MemoryFileSystem.test();
        final IosProject project = IosProject.fromFlutter(
          FakeFlutterProject(fileSystem: fs),
        );
        project.xcodeProject.createSync(recursive: true);
        expect(await project.projectInfo(), isNull);
      }, overrides: <Type, Generator>{
        XcodeProjectInterpreter: () => FakeXcodeProjectInterpreter(
          isInstalled: false,
        ),
      });

      testUsingContext('is null if xcodeproj does not exist', () async {
        final MemoryFileSystem fs = MemoryFileSystem.test();
        final IosProject project = IosProject.fromFlutter(
          FakeFlutterProject(fileSystem: fs),
        );
        expect(await project.projectInfo(), isNull);
      }, overrides: <Type, Generator>{
        XcodeProjectInterpreter: () => FakeXcodeProjectInterpreter(),
      });

      testUsingContext('returns XcodeProjectInfo', () async {
        final MemoryFileSystem fs = MemoryFileSystem.test();
        final IosProject project = IosProject.fromFlutter(
          FakeFlutterProject(fileSystem: fs),
        );
        project.xcodeProject.createSync(recursive: true);
        expect(await project.projectInfo(), isNotNull);
      }, overrides: <Type, Generator>{
        XcodeProjectInterpreter: () => FakeXcodeProjectInterpreter(),
      });
    });
  });

  group('MacOSProject', () {
    testWithoutContext('managedDirectory', () {
      final MemoryFileSystem fs = MemoryFileSystem.test();
      final MacOSProject project = MacOSProject.fromFlutter(
        FakeFlutterProject(fileSystem: fs),
      );
      expect(project.managedDirectory.path, 'app_name/macos/Flutter');
    });

    testWithoutContext('module managedDirectory', () {
      final MemoryFileSystem fs = MemoryFileSystem.test();
      final MacOSProject project = MacOSProject.fromFlutter(
        FakeFlutterProject(fileSystem: fs),
      );
      expect(project.managedDirectory.path, 'app_name/macos/Flutter');
    });

    testWithoutContext('ephemeralDirectory', () {
      final MemoryFileSystem fs = MemoryFileSystem.test();
      final MacOSProject project = MacOSProject.fromFlutter(
        FakeFlutterProject(fileSystem: fs),
      );
      expect(project.ephemeralDirectory.path, 'app_name/macos/Flutter/ephemeral');
    });

    testWithoutContext('flutterPluginSwiftPackageDirectory', () {
      final MemoryFileSystem fs = MemoryFileSystem.test();
      final MacOSProject project = MacOSProject.fromFlutter(
        FakeFlutterProject(fileSystem: fs),
      );
      expect(
        project.flutterPluginSwiftPackageDirectory.path,
        'app_name/macos/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage',
      );
    });

    testWithoutContext('xcodeConfigFor', () {
      final MemoryFileSystem fs = MemoryFileSystem.test();
      final MacOSProject project = MacOSProject.fromFlutter(
        FakeFlutterProject(fileSystem: fs),
      );
      expect(
        project.xcodeConfigFor('Debug').path,
        'app_name/macos/Flutter/Flutter-Debug.xcconfig',
      );
    });
  });
}

class FakeFlutterProject extends Fake implements FlutterProject {
  FakeFlutterProject({
    required this.fileSystem,
    this.isModule = false,
  });

  MemoryFileSystem fileSystem;

  @override
  late final Directory directory = fileSystem.directory('app_name');

  @override
  bool isModule = false;
}

class FakeXcodeProjectInterpreter extends Fake implements XcodeProjectInterpreter {
  FakeXcodeProjectInterpreter({
    this.isInstalled = true,
  });

  @override
  final bool isInstalled;

  @override
  Future<XcodeProjectInfo?> getInfo(String projectPath, {String? projectFilename}) async {
    return XcodeProjectInfo(
      <String>[],
      <String>[],
      <String>['Runner'],
      BufferLogger.test(),
    );
  }
}
