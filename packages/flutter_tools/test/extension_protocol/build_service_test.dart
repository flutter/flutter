// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/flutter_tools_extension.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/experimental/devices.dart';
import 'package:flutter_tools/src/extension_prototypes/linux_extension/build.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:stream_channel/isolate_channel.dart';
import 'package:stream_channel/stream_channel.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/fake_process_manager.dart';

void main() {
  group('BuildEnvironment & ArtifactDependency Serialization', () {
    testWithoutContext('BuildEnvironment serialization and deserialization', () {
      final env = BuildEnvironment(
        cacheDir: Uri.parse('file:///cache'),
        defines: <String, String>{'KEY': 'VALUE'},
        flutterAssetsDir: Uri.parse('file:///assets'),
        outputDirectory: Uri.parse('file:///output'),
        projectRoot: Uri.parse('file:///project'),
      );

      final Map<String, Object?> map = env.toMap();
      expect(map['cacheDir'], 'file:///cache');
      expect(map['defines'], <String, String>{'KEY': 'VALUE'});
      expect(map['flutterAssetsDir'], 'file:///assets');
      expect(map['outputDirectory'], 'file:///output');
      expect(map['projectRoot'], 'file:///project');

      final deserialized = BuildEnvironment.fromJson(map);
      expect(deserialized.cacheDir.toString(), 'file:///cache');
      expect(deserialized.defines, <String, String>{'KEY': 'VALUE'});
      expect(deserialized.flutterAssetsDir.toString(), 'file:///assets');
      expect(deserialized.outputDirectory.toString(), 'file:///output');
      expect(deserialized.projectRoot.toString(), 'file:///project');
    });

    testWithoutContext('ArtifactDependency serialization and deserialization', () {
      final dep = ArtifactDependency(
        hostPlatform: 'linux',
        name: 'gen_snapshot',
        sha256Checksums: <String, String>{'x64': 'hash123'},
        targetArchitecture: 'arm64',
        targetPlatform: 'android',
      );

      final Map<String, Object?> map = dep.toMap();
      expect(map['hostPlatform'], 'linux');
      expect(map['name'], 'gen_snapshot');
      expect(map['sha256Checksums'], <String, String>{'x64': 'hash123'});
      expect(map['targetArchitecture'], 'arm64');
      expect(map['targetPlatform'], 'android');

      final deserialized = ArtifactDependency.fromJson(map);
      expect(deserialized.hostPlatform, 'linux');
      expect(deserialized.name, 'gen_snapshot');
      expect(deserialized.sha256Checksums, <String, String>{'x64': 'hash123'});
      expect(deserialized.targetArchitecture, 'arm64');
      expect(deserialized.targetPlatform, 'android');
    });
  });

  group('Linux Build Service (Extension Side)', () {
    testWithoutContext('LinuxBuildService target execution compiles via CMake', () async {
      final fs = MemoryFileSystem.test();
      fs.directory('/project/linux').createSync(recursive: true);
      fs.directory('/build/out').createSync(recursive: true);

      final fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>['cmake', '-S', '/project/linux', '-B', '/build/out']),
        const FakeCommand(command: <String>['cmake', '--build', '/build/out']),
      ]);

      final buildService = LinuxBuildService(fileSystem: fs, processManager: fakeProcessManager);

      final Map<String, Function> rpcHandlers = await buildService.initialize();
      final build =
          rpcHandlers['build']! as Future<Map<String, Object?>> Function(Map<String, Object?>);

      final env = BuildEnvironment(
        cacheDir: Uri.parse('file:///cache'),
        defines: <String, String>{},
        flutterAssetsDir: Uri.parse('file:///project/build/flutter_assets'),
        outputDirectory: Uri.parse('file:///build/out'),
        projectRoot: Uri.parse('file:///project'),
      );

      final Map<String, Object?> result = await build(<String, Object?>{
        'targetName': 'assemble_linux_app',
        'environment': env.toMap(),
      });

      expect(result['success'], true);
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    testWithoutContext('LinuxBuildService handles missing/invalid parameters safely', () async {
      final buildService = LinuxBuildService();
      final Map<String, Function> rpcHandlers = await buildService.initialize();
      final build =
          rpcHandlers['build']! as Future<Map<String, Object?>> Function(Map<String, Object?>);

      // Missing targetName
      final Map<String, Object?> result1 = await build(<String, Object?>{
        'environment': <String, Object?>{},
      });
      expect(result1['success'], false);
      expect(result1['errorMessage']! as String, contains('Missing or invalid parameters'));

      // Missing environment
      final Map<String, Object?> result2 = await build(<String, Object?>{
        'targetName': 'assemble_linux_app',
      });
      expect(result2['success'], false);
      expect(result2['errorMessage']! as String, contains('Missing or invalid parameters'));
    });

    testWithoutContext('LinuxBuildService handles CMake configure failure', () async {
      final fs = MemoryFileSystem.test();
      fs.directory('/project/linux').createSync(recursive: true);

      final fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['cmake', '-S', '/project/linux', '-B', '/build/out'],
          exitCode: 1,
          stdout: 'CMake configure error stdout',
          stderr: 'CMake configure error stderr',
        ),
      ]);

      final buildService = LinuxBuildService(fileSystem: fs, processManager: fakeProcessManager);

      final Map<String, Function> rpcHandlers = await buildService.initialize();
      final build =
          rpcHandlers['build']! as Future<Map<String, Object?>> Function(Map<String, Object?>);

      final env = BuildEnvironment(
        cacheDir: Uri.parse('file:///cache'),
        defines: <String, String>{},
        flutterAssetsDir: Uri.parse('file:///project/build/flutter_assets'),
        outputDirectory: Uri.parse('file:///build/out'),
        projectRoot: Uri.parse('file:///project'),
      );

      final Map<String, Object?> result = await build(<String, Object?>{
        'targetName': 'assemble_linux_app',
        'environment': env.toMap(),
      });

      expect(result['success'], false);
      expect(
        result['errorMessage']! as String,
        contains('CMake configuration failed with exit code 1'),
      );
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });
  });

  group('ExtensionBackedDevice Build Delegation (Host Side)', () {
    late ToolExtensionManager manager;
    rpc.Peer? mockExtensionPeer;
    ReceivePort? mockExtensionReceivePort;
    StreamChannel<Object?>? mockExtensionChannel;

    setUp(() {
      manager = ToolExtensionManager();
    });

    tearDown(() async {
      await manager.dispose();
      await mockExtensionPeer?.close();
      mockExtensionReceivePort?.close();
    });

    Future<ToolExtension> connectMockExtension({
      required List<String> services,
      bool mockGetTargets = true,
      bool mockBuild = true,
      Map<String, Object?>? buildResponse,
      Completer<Map<String, Object?>>? buildCompleter,
    }) async {
      final managerReceivePort = ReceivePort();
      final Future<ToolExtension> connectFuture = manager.connectExtension(managerReceivePort);

      mockExtensionReceivePort = ReceivePort();
      managerReceivePort.sendPort.send(mockExtensionReceivePort!.sendPort);

      final ToolExtension extension = await connectFuture;

      mockExtensionChannel = IsolateChannel<Object?>.connectReceive(mockExtensionReceivePort!);
      mockExtensionPeer = rpc.Peer.withoutJson(mockExtensionChannel!);

      mockExtensionPeer!.registerMethod('extension.getCapabilities', () {
        return <String, Object?>{'services': services};
      });

      if (mockGetTargets) {
        mockExtensionPeer!.registerMethod('build.getTargets', () {
          return <Map<String, Object?>>[
            <String, Object?>{
              'name': 'assemble_linux_app',
              'dependencies': <String>[],
              'inputs': <String>[],
              'outputs': <String>[],
            },
          ];
        });
      }

      if (mockBuild) {
        mockExtensionPeer!.registerMethod('build.build', (rpc.Parameters params) {
          final String targetName = params['targetName'].asString;
          final Map<String, Object?> environment = params['environment'].asMap
              .cast<String, Object?>();

          buildCompleter?.complete(<String, Object?>{
            'targetName': targetName,
            'environment': environment,
          });

          return buildResponse ?? <String, Object?>{'success': true};
        });
      }

      mockExtensionPeer!.registerMethod('device.launchApp', (rpc.Parameters params) {
        return <String, Object?>{};
      });
      mockExtensionPeer!.registerMethod('device.getVmServiceUri', (rpc.Parameters params) {
        return 'http://127.0.0.1:8181/auth-token-xyz/';
      });

      unawaited(mockExtensionPeer!.listen());
      return extension;
    }

    testUsingContext(
      'ExtensionBackedDevice.startApp delegates build to GEP build.build successfully',
      () async {
        final buildCompleter = Completer<Map<String, Object?>>();
        final ToolExtension extension = await connectMockExtension(
          services: <String>['build'],
          buildCompleter: buildCompleter,
        );

        final Directory projectDir = globals.fs.directory('/project');
        projectDir.createSync(recursive: true);
        projectDir.childFile('pubspec.yaml').writeAsStringSync('name: my_app\n');
        projectDir.childDirectory('linux').createSync(recursive: true);
        globals.fs.currentDirectory = projectDir;

        final device = ExtensionBackedDevice(
          'linux-proto-1',
          category: Category.desktop,
          extension: extension,
          logger: BufferLogger.test(),
          name: 'Mock Device',
        );

        final LaunchResult result = await device.startApp(
          null, // package
          debuggingOptions: DebuggingOptions.enabled(
            const BuildInfo(
              BuildMode.debug,
              null,
              treeShakeIcons: false,
              packageConfigPath: '.dart_tool/package_config.json',
            ),
          ),
        );

        expect(result.started, true);
        expect(result.vmServiceUri, Uri.parse('http://127.0.0.1:8181/auth-token-xyz/'));

        final Map<String, Object?> buildCall = await buildCompleter.future;
        expect(buildCall['targetName'], 'assemble_linux_app');

        final envMap = buildCall['environment']! as Map<String, Object?>;
        final env = BuildEnvironment.fromJson(envMap);

        expect(env.projectRoot, Uri.parse('file:///project/'));
        expect(env.outputDirectory.path, contains('build/linux/x64/debug'));
      },
      overrides: <Type, Generator>{
        FileSystem: () => MemoryFileSystem.test(),
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'throws ToolExit when capability build is missing',
      () async {
        final ToolExtension extension = await connectMockExtension(
          services: <String>[], // No build service
        );

        final Directory projectDir = globals.fs.directory('/project');
        projectDir.createSync(recursive: true);
        projectDir.childFile('pubspec.yaml').writeAsStringSync('name: my_app\n');
        projectDir.childDirectory('linux').createSync(recursive: true);
        globals.fs.currentDirectory = projectDir;

        final device = ExtensionBackedDevice(
          'linux-proto-1',
          category: Category.desktop,
          extension: extension,
          logger: BufferLogger.test(),
          name: 'Mock Device',
        );

        expect(
          () => device.startApp(null, debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug)),
          throwsToolExit(message: 'GEP extension does not support the "build" service.'),
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => MemoryFileSystem.test(),
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'throws ToolExit when GEP build fails',
      () async {
        final ToolExtension extension = await connectMockExtension(
          services: <String>['build'],
          buildResponse: <String, Object?>{
            'success': false,
            'errorMessage': 'Compilation failed due to syntax error',
          },
        );

        final Directory projectDir = globals.fs.directory('/project');
        projectDir.createSync(recursive: true);
        projectDir.childFile('pubspec.yaml').writeAsStringSync('name: my_app\n');
        projectDir.childDirectory('linux').createSync(recursive: true);
        globals.fs.currentDirectory = projectDir;

        final device = ExtensionBackedDevice(
          'linux-proto-1',
          category: Category.desktop,
          extension: extension,
          logger: BufferLogger.test(),
          name: 'Mock Device',
        );

        expect(
          () => device.startApp(
            null,
            debuggingOptions: DebuggingOptions.enabled(
              const BuildInfo(
                BuildMode.debug,
                null,
                treeShakeIcons: false,
                packageConfigPath: '.dart_tool/package_config.json',
              ),
            ),
          ),
          throwsToolExit(
            message: 'GEP build compilation failed: Compilation failed due to syntax error',
          ),
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => MemoryFileSystem.test(),
        ProcessManager: () => FakeProcessManager.any(),
      },
    );
  });
}
