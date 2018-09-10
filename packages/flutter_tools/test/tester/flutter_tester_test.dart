// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/tester/flutter_tester.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';

void main() {
  MemoryFileSystem fs;

  setUp(() {
    fs = MemoryFileSystem();
  });

  group('FlutterTesterApp', () {
    testUsingContext('fromCurrentDirectory', () async {
      const String projectPath = '/home/my/projects/my_project';
      await fs.directory(projectPath).create(recursive: true);
      fs.currentDirectory = projectPath;

      final FlutterTesterApp app = FlutterTesterApp.fromCurrentDirectory();
      expect(app.name, 'my_project');
      expect(app.packagesFile.path, fs.path.join(projectPath, '.packages'));
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
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
      expect(device, isInstanceOf<FlutterTesterDevice>());
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
      MockKernelCompiler mockKernelCompiler;
      MockProcessManager mockProcessManager;
      MockProcess mockProcess;

      final Map<Type, Generator> startOverrides = <Type, Generator>{
        Platform: () => FakePlatform(operatingSystem: 'linux'),
        FileSystem: () => fs,
        Cache: () => Cache(rootOverride: fs.directory(flutterRoot)),
        ProcessManager: () => mockProcessManager,
        KernelCompiler: () => mockKernelCompiler,
        Artifacts: () => mockArtifacts,
      };

      setUp(() {
        flutterRoot = fs.path.join('home', 'me', 'flutter');
        flutterTesterPath = fs.path.join(flutterRoot, 'bin', 'cache',
            'artifacts', 'engine', 'linux-x64', 'flutter_tester');

        final File flutterTesterFile = fs.file(flutterTesterPath);
        flutterTesterFile.parent.createSync(recursive: true);
        flutterTesterFile.writeAsBytesSync(const <int>[]);

        projectPath = fs.path.join('home', 'me', 'hello');
        mainPath = fs.path.join(projectPath, 'lin', 'main.dart');

        mockProcessManager = MockProcessManager();
        mockProcessManager.processFactory =
            (List<String> commands) => mockProcess;

        mockArtifacts = MockArtifacts();
        final String artifactPath = fs.path.join(flutterRoot, 'artifact');
        fs.file(artifactPath).createSync(recursive: true);
        when(mockArtifacts.getArtifactPath(any)).thenReturn(artifactPath);

        mockKernelCompiler = MockKernelCompiler();
      });

      testUsingContext('not debug', () async {
        final LaunchResult result = await device.startApp(null,
            mainPath: mainPath,
            debuggingOptions: DebuggingOptions.disabled(const BuildInfo(BuildMode.release, null)));
        expect(result.started, isFalse);
      }, overrides: startOverrides);

      testUsingContext('no flutter_tester', () async {
        fs.file(flutterTesterPath).deleteSync();
        expect(() async {
          await device.startApp(null,
              mainPath: mainPath,
              debuggingOptions: DebuggingOptions.disabled(const BuildInfo(BuildMode.debug, null)));
        }, throwsToolExit());
      }, overrides: startOverrides);

      testUsingContext('start', () async {
        final Uri observatoryUri = Uri.parse('http://127.0.0.1:6666/');
        mockProcess = MockProcess(
            stdout: Stream<List<int>>.fromIterable(<List<int>>[
          '''
Observatory listening on $observatoryUri
Hello!
'''
              .codeUnits
        ]));

        when(mockKernelCompiler.compile(
          sdkRoot: anyNamed('sdkRoot'),
          incrementalCompilerByteStorePath: anyNamed('incrementalCompilerByteStorePath'),
          mainPath: anyNamed('mainPath'),
          outputFilePath: anyNamed('outputFilePath'),
          depFilePath: anyNamed('depFilePath'),
          trackWidgetCreation: anyNamed('trackWidgetCreation'),
          extraFrontEndOptions: anyNamed('extraFrontEndOptions'),
          fileSystemRoots: anyNamed('fileSystemRoots'),
          fileSystemScheme: anyNamed('fileSystemScheme'),
          packagesPath: anyNamed('packagesPath'),
        )).thenAnswer((_) async {
          fs.file('$mainPath.dill').createSync(recursive: true);
          return CompilerOutput('$mainPath.dill', 0);
        });

        final LaunchResult result = await device.startApp(null,
            mainPath: mainPath,
            debuggingOptions: DebuggingOptions.enabled(const BuildInfo(BuildMode.debug, null)));
        expect(result.started, isTrue);
        expect(result.observatoryUri, observatoryUri);

        expect(logLines.last, 'Hello!');
      }, overrides: startOverrides);
    });
  });
}

class MockArtifacts extends Mock implements Artifacts {}
class MockKernelCompiler extends Mock implements KernelCompiler {}
