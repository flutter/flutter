// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/tester/flutter_tester.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:platform/platform.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

void main() {
  MemoryFileSystem fileSystem;

  setUp(() {
    fileSystem = MemoryFileSystem();
  });

  group('FlutterTesterApp', () {
    testUsingContext('fromCurrentDirectory', () async {
      const String projectPath = '/home/my/projects/my_project';
      await fileSystem.directory(projectPath).create(recursive: true);
      fileSystem.currentDirectory = projectPath;

      final FlutterTesterApp app = FlutterTesterApp.fromCurrentDirectory();
      expect(app.name, 'my_project');
      expect(app.packagesFile.path, fileSystem.path.join(projectPath, '.packages'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });
  });

  group('FlutterTesterDevices', () {
    tearDown(() {
      FlutterTesterDevices.showFlutterTesterDevice = false;
    });

    testUsingContext('no device', () async {
      final FlutterTesterDevices discoverer = FlutterTesterDevices();

      final List<Device> devices = await discoverer.devices;
      expect(devices, isEmpty);
    });

    testUsingContext('has device', () async {
      FlutterTesterDevices.showFlutterTesterDevice = true;
      final FlutterTesterDevices discoverer = FlutterTesterDevices();

      final List<Device> devices = await discoverer.devices;
      expect(devices, hasLength(1));

      final Device device = devices.single;
      expect(device, isA<FlutterTesterDevice>());
      expect(device.id, 'flutter-tester');
    });
  });

  group('FlutterTesterDevice', () {
    FlutterTesterDevice device;
    List<String> logLines;

    setUp(() {
      device = FlutterTesterDevice('flutter-tester');

      logLines = <String>[];
      device.getLogReader().logLines.listen(logLines.add);
    });

    testUsingContext('getters', () async {
      expect(device.id, 'flutter-tester');
      expect(await device.isLocalEmulator, isFalse);
      expect(device.name, 'Flutter test device');
      expect(device.portForwarder, isNot(isNull));
      expect(await device.targetPlatform, TargetPlatform.tester);

      expect(await device.installApp(null), isTrue);
      expect(await device.isAppInstalled(null), isFalse);
      expect(await device.isLatestBuildInstalled(null), isFalse);
      expect(await device.uninstallApp(null), isTrue);

      expect(device.isSupported(), isTrue);
    });

    group('startApp', () {
      String flutterRoot;
      String flutterTesterPath;

      String projectPath;
      String mainPath;

      MockArtifacts mockArtifacts;
      MockProcessManager mockProcessManager;
      MockProcess mockProcess;
      MockBuildSystem mockBuildSystem;

      final Map<Type, Generator> startOverrides = <Type, Generator>{
        Platform: () => FakePlatform(operatingSystem: 'linux'),
        FileSystem: () => fileSystem,
        ProcessManager: () => mockProcessManager,
        Artifacts: () => mockArtifacts,
        BuildSystem: () => mockBuildSystem,
      };

      setUp(() {
        mockBuildSystem = MockBuildSystem();
        flutterRoot = fileSystem.path.join('home', 'me', 'flutter');
        flutterTesterPath = fileSystem.path.join(flutterRoot, 'bin', 'cache',
            'artifacts', 'engine', 'linux-x64', 'flutter_tester');
        final File flutterTesterFile = fileSystem.file(flutterTesterPath);
        flutterTesterFile.parent.createSync(recursive: true);
        flutterTesterFile.writeAsBytesSync(const <int>[]);

        projectPath = fileSystem.path.join('home', 'me', 'hello');
        mainPath = fileSystem.path.join(projectPath, 'lin', 'main.dart');

        mockProcessManager = MockProcessManager();
        mockProcessManager.processFactory =
            (List<String> commands) => mockProcess;

        mockArtifacts = MockArtifacts();
        final String artifactPath = fileSystem.path.join(flutterRoot, 'artifact');
        fileSystem.file(artifactPath).createSync(recursive: true);
        when(mockArtifacts.getArtifactPath(
          any,
          mode: anyNamed('mode')
        )).thenReturn(artifactPath);

        when(mockBuildSystem.build(
          any,
          any,
        )).thenAnswer((_) async {
          fileSystem.file('$mainPath.dill').createSync(recursive: true);
          return BuildResult(success: true);
        });
      });

      testUsingContext('not debug', () async {
        final LaunchResult result = await device.startApp(null,
            mainPath: mainPath,
            debuggingOptions: DebuggingOptions.disabled(const BuildInfo(BuildMode.release, null, treeShakeIcons: false)));

        expect(result.started, isFalse);
      }, overrides: startOverrides);


      testUsingContext('start', () async {
        final Uri observatoryUri = Uri.parse('http://127.0.0.1:6666/');
        mockProcess = MockProcess(stdout: Stream<List<int>>.fromIterable(<List<int>>[
          '''
Observatory listening on $observatoryUri
Hello!
'''
              .codeUnits,
        ]));

        final LaunchResult result = await device.startApp(null,
            mainPath: mainPath,
            debuggingOptions: DebuggingOptions.enabled(const BuildInfo(BuildMode.debug, null, treeShakeIcons: false)));
        expect(result.started, isTrue);
        expect(result.observatoryUri, observatoryUri);
        expect(logLines.last, 'Hello!');
      }, overrides: startOverrides);
    });
  });
}

class MockBuildSystem extends Mock implements BuildSystem {}
class MockArtifacts extends Mock implements Artifacts {}
