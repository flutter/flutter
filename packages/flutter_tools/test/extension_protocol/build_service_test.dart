// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/flutter_tools_extension.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
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
import '../src/test_flutter_command_runner.dart';

void main() {
  group('BuildEnvironment & ArtifactDependency Serialization', () {
    testWithoutContext('BuildEnvironment serialization and deserialization', () {
      final env = BuildEnvironment(
        cacheDir: Uri.parse('file:///cache'),
        defines: <String, String>{'KEY': 'VALUE'},
        flutterAssetsDir: Uri.parse('file:///assets'),
        outputDirectory: Uri.parse('file:///output'),
        projectRoot: Uri.parse('file:///project'),
        plugins: <ExtensionPlugin>[
          ExtensionPlugin(
            configuration: const <String, Object?>{'key': 'val'},
            name: 'my_plugin',
            path: '/path/to/my_plugin',
          ),
        ],
      );

      final Map<String, Object?> map = env.toMap();
      expect(map['cacheDir'], 'file:///cache');
      expect(map['defines'], <String, String>{'KEY': 'VALUE'});
      expect(map['flutterAssetsDir'], 'file:///assets');
      expect(map['outputDirectory'], 'file:///output');
      expect(map['projectRoot'], 'file:///project');
      expect(map['plugins'], isList);
      final pluginsList = map['plugins']! as List<Object?>;
      expect(pluginsList.length, 1);
      final pluginMap = pluginsList.first! as Map<String, Object?>;
      expect(pluginMap['name'], 'my_plugin');
      expect(pluginMap['path'], '/path/to/my_plugin');
      expect(pluginMap['configuration'], <String, Object?>{'key': 'val'});

      final deserialized = BuildEnvironment.fromJson(map);
      expect(deserialized.cacheDir.toString(), 'file:///cache');
      expect(deserialized.defines, <String, String>{'KEY': 'VALUE'});
      expect(deserialized.flutterAssetsDir.toString(), 'file:///assets');
      expect(deserialized.outputDirectory.toString(), 'file:///output');
      expect(deserialized.projectRoot.toString(), 'file:///project');
      expect(deserialized.plugins.length, 1);
      expect(deserialized.plugins.first.name, 'my_plugin');
      expect(deserialized.plugins.first.path, '/path/to/my_plugin');
      expect(deserialized.plugins.first.configuration, <String, Object?>{'key': 'val'});
    });

    testWithoutContext('ArtifactDependency serialization and deserialization', () {
      const dep = ArtifactDependency(
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
        const FakeCommand(
          command: <String>[
            'cmake',
            '-G',
            'Ninja',
            '-DCMAKE_BUILD_TYPE=Debug',
            '-DFLUTTER_TARGET_PLATFORM=linux-x64',
            '-S',
            '/project/linux',
            '-B',
            '/build/out',
          ],
          environment: <String, String>{},
        ),
        const FakeCommand(
          command: <String>['cmake', '--build', '/build/out', '--target', 'install'],
          environment: <String, String>{},
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
        plugins: const <ExtensionPlugin>[],
      );

      final Map<String, Object?> result = await build(<String, Object?>{
        'targetName': 'assemble_linux_app',
        'environment': env.toMap(),
      });

      expect(result['success'], true);
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    testWithoutContext(
      'LinuxBuildService target execution forwards custom defines to cmake and environment',
      () async {
        final fs = MemoryFileSystem.test();
        fs.directory('/project/linux').createSync(recursive: true);
        fs.directory('/build/out').createSync(recursive: true);

        final fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: <String>[
              'cmake',
              '-G',
              'Ninja',
              '-DCMAKE_BUILD_TYPE=Release',
              '-DFLUTTER_TARGET_PLATFORM=linux-arm64',
              '-S',
              '/project/linux',
              '-B',
              '/build/out',
            ],
            environment: <String, String>{
              'CMAKE_BUILD_TYPE': 'Release',
              'FLUTTER_TARGET_PLATFORM': 'linux-arm64',
              'CUSTOM_KEY': 'CUSTOM_VALUE',
            },
          ),
          const FakeCommand(
            command: <String>['cmake', '--build', '/build/out', '--target', 'install'],
            environment: <String, String>{
              'CMAKE_BUILD_TYPE': 'Release',
              'FLUTTER_TARGET_PLATFORM': 'linux-arm64',
              'CUSTOM_KEY': 'CUSTOM_VALUE',
            },
          ),
        ]);

        final buildService = LinuxBuildService(fileSystem: fs, processManager: fakeProcessManager);
        final Map<String, Function> rpcHandlers = await buildService.initialize();
        final build =
            rpcHandlers['build']! as Future<Map<String, Object?>> Function(Map<String, Object?>);

        final env = BuildEnvironment(
          cacheDir: Uri.parse('file:///cache'),
          defines: <String, String>{
            'CMAKE_BUILD_TYPE': 'Release',
            'FLUTTER_TARGET_PLATFORM': 'linux-arm64',
            'CUSTOM_KEY': 'CUSTOM_VALUE',
          },
          flutterAssetsDir: Uri.parse('file:///project/build/flutter_assets'),
          outputDirectory: Uri.parse('file:///build/out'),
          projectRoot: Uri.parse('file:///project'),
          plugins: const <ExtensionPlugin>[],
        );

        final Map<String, Object?> result = await build(<String, Object?>{
          'targetName': 'assemble_linux_app',
          'environment': env.toMap(),
        });

        expect(result['success'], true);
        expect(fakeProcessManager, hasNoRemainingExpectations);
      },
    );

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
          command: <String>[
            'cmake',
            '-G',
            'Ninja',
            '-DCMAKE_BUILD_TYPE=Debug',
            '-DFLUTTER_TARGET_PLATFORM=linux-x64',
            '-S',
            '/project/linux',
            '-B',
            '/build/out',
          ],
          environment: <String, String>{},
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
        plugins: const <ExtensionPlugin>[],
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

    testWithoutContext(
      'LinuxBuildService proactively deletes non-Ninja CMakeCache.txt and CMakeFiles before configure',
      () async {
        final fs = MemoryFileSystem.test();
        fs.directory('/project/linux').createSync(recursive: true);
        fs.directory('/build/out').createSync(recursive: true);

        final File cacheFile = fs.file('/build/out/CMakeCache.txt');
        cacheFile.writeAsStringSync('CMAKE_GENERATOR:INTERNAL=Unix Makefiles\n');
        final Directory cmakeFilesDir = fs.directory('/build/out/CMakeFiles');
        cmakeFilesDir.createSync(recursive: true);
        cmakeFilesDir.childFile('test.cmake').createSync();

        var cacheExistedWhenConfigureRan = false;
        var cmakeFilesExistedWhenConfigureRan = false;

        final fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
          FakeCommand(
            command: const <String>[
              'cmake',
              '-G',
              'Ninja',
              '-DCMAKE_BUILD_TYPE=Debug',
              '-DFLUTTER_TARGET_PLATFORM=linux-x64',
              '-S',
              '/project/linux',
              '-B',
              '/build/out',
            ],
            environment: const <String, String>{},
            onRun: (List<String> command) {
              cacheExistedWhenConfigureRan = fs.file('/build/out/CMakeCache.txt').existsSync();
              cmakeFilesExistedWhenConfigureRan = fs
                  .directory('/build/out/CMakeFiles')
                  .existsSync();
            },
          ),
          const FakeCommand(
            command: <String>['cmake', '--build', '/build/out', '--target', 'install'],
            environment: <String, String>{},
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
          plugins: const <ExtensionPlugin>[],
        );

        final Map<String, Object?> result = await build(<String, Object?>{
          'targetName': 'assemble_linux_app',
          'environment': env.toMap(),
        });

        expect(result['success'], true);
        expect(cacheExistedWhenConfigureRan, false);
        expect(cmakeFilesExistedWhenConfigureRan, false);
        expect(fakeProcessManager, hasNoRemainingExpectations);
      },
    );

    testWithoutContext(
      'LinuxBuildService retries CMake configure once when initial configure fails and cache exists',
      () async {
        final fs = MemoryFileSystem.test();
        fs.directory('/project/linux').createSync(recursive: true);
        fs.directory('/build/out').createSync(recursive: true);

        final File cacheFile = fs.file('/build/out/CMakeCache.txt');
        cacheFile.writeAsStringSync('CMAKE_GENERATOR:INTERNAL=Ninja\n');
        final Directory cmakeFilesDir = fs.directory('/build/out/CMakeFiles');
        cmakeFilesDir.createSync(recursive: true);
        cmakeFilesDir.childFile('test.cmake').createSync();

        var cacheExistedOnRetry = false;
        var cmakeFilesExistedOnRetry = false;

        final fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: <String>[
              'cmake',
              '-G',
              'Ninja',
              '-DCMAKE_BUILD_TYPE=Debug',
              '-DFLUTTER_TARGET_PLATFORM=linux-x64',
              '-S',
              '/project/linux',
              '-B',
              '/build/out',
            ],
            environment: <String, String>{},
            exitCode: 1,
            stdout: 'Initial configure failure stdout',
            stderr: 'Initial configure failure stderr',
          ),
          FakeCommand(
            command: const <String>[
              'cmake',
              '-G',
              'Ninja',
              '-DCMAKE_BUILD_TYPE=Debug',
              '-DFLUTTER_TARGET_PLATFORM=linux-x64',
              '-S',
              '/project/linux',
              '-B',
              '/build/out',
            ],
            environment: const <String, String>{},
            onRun: (List<String> command) {
              cacheExistedOnRetry = fs.file('/build/out/CMakeCache.txt').existsSync();
              cmakeFilesExistedOnRetry = fs.directory('/build/out/CMakeFiles').existsSync();
            },
          ),
          const FakeCommand(
            command: <String>['cmake', '--build', '/build/out', '--target', 'install'],
            environment: <String, String>{},
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
          plugins: const <ExtensionPlugin>[],
        );

        final Map<String, Object?> result = await build(<String, Object?>{
          'targetName': 'assemble_linux_app',
          'environment': env.toMap(),
        });

        expect(result['success'], true);
        expect(cacheExistedOnRetry, false);
        expect(cmakeFilesExistedOnRetry, false);
        expect(fakeProcessManager, hasNoRemainingExpectations);
      },
    );

    testWithoutContext(
      'LinuxBuildService throws error when retried CMake configure fails after cache cleanup',
      () async {
        final fs = MemoryFileSystem.test();
        fs.directory('/project/linux').createSync(recursive: true);
        fs.directory('/build/out').createSync(recursive: true);

        final File cacheFile = fs.file('/build/out/CMakeCache.txt');
        cacheFile.writeAsStringSync('CMAKE_GENERATOR:INTERNAL=Ninja\n');

        final fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: <String>[
              'cmake',
              '-G',
              'Ninja',
              '-DCMAKE_BUILD_TYPE=Debug',
              '-DFLUTTER_TARGET_PLATFORM=linux-x64',
              '-S',
              '/project/linux',
              '-B',
              '/build/out',
            ],
            environment: <String, String>{},
            exitCode: 1,
            stdout: 'First configure failure stdout',
            stderr: 'First configure failure stderr',
          ),
          const FakeCommand(
            command: <String>[
              'cmake',
              '-G',
              'Ninja',
              '-DCMAKE_BUILD_TYPE=Debug',
              '-DFLUTTER_TARGET_PLATFORM=linux-x64',
              '-S',
              '/project/linux',
              '-B',
              '/build/out',
            ],
            environment: <String, String>{},
            exitCode: 1,
            stdout: 'Second configure failure stdout',
            stderr: 'Second configure failure stderr',
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
          plugins: const <ExtensionPlugin>[],
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
        expect(result['errorMessage']! as String, contains('Second configure failure stdout'));
        expect(fakeProcessManager, hasNoRemainingExpectations);
      },
    );
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
      Completer<Map<String, Object?>>? buildCompleter,
      Map<String, Object?>? buildResponse,
      bool mockBuild = true,
      bool mockGetTargets = true,
      List<ExtensionBuildTarget>? targets,
      required List<String> services,
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

          return buildResponse ??
              <String, Object?>{'success': true, 'executablePath': 'file:///build/out/app'};
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

    ExtensionBackedDevice createTestDevice(
      ToolExtension extension, {
      String id = 'linux-proto-1',
      String name = 'Mock Device',
      Category category = Category.desktop,
    }) {
      final hostDevice = HostDevice(
        id,
        extension,
        name: name,
        category: category == Category.mobile
            ? 'mobile'
            : category == Category.web
            ? 'web'
            : 'desktop',
        isEmulator: false,
        platform: 'linux-x64',
        buildTarget: 'assemble_linux_app',
        isSupportedVal: true,
        isRunnableVal: true,
      );
      return ExtensionBackedDevice(hostDevice, logger: BufferLogger.test());
    }

    testUsingContext(
      'ExtensionBackedDevice.startApp delegates build successfully',
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

        final ExtensionBackedDevice device = createTestDevice(extension);

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
        expect(env.outputDirectory.path, contains('build/linux-x64/linux-proto-1/debug'));
        expect(env.defines['FLUTTER_TARGET_PLATFORM'], 'linux-x64');
        expect(env.defines['FLUTTER_BUILD_MODE'], 'debug');
        expect(env.defines['CMAKE_BUILD_TYPE'], 'Debug');
      },
      overrides: <Type, Generator>{
        FileSystem: () => MemoryFileSystem.test(),
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () =>
            FakePlatform(environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'}),
        ToolExtensionManager: () => manager,
      },
    );

    testUsingContext(
      'ExtensionBackedDevice.startApp triggers pre-build plugin discovery and injection when CMake project exists',
      () async {
        final buildCompleter = Completer<Map<String, Object?>>();
        final ToolExtension extension = await connectMockExtension(
          services: <String>['build'],
          buildCompleter: buildCompleter,
        );

        final Directory projectDir = globals.fs.directory('/project');
        projectDir.createSync(recursive: true);
        projectDir.childFile('pubspec.yaml').writeAsStringSync('name: my_app\n');
        projectDir.childDirectory('lib').childFile('main.dart').createSync(recursive: true);
        projectDir.childFile('.packages').createSync();
        projectDir.childDirectory('.dart_tool').childFile('package_config.json')
          ..createSync(recursive: true)
          ..writeAsStringSync(
            '{"configVersion": 2, "packages": [{"name": "my_app", "rootUri": "../", "packageUri": "lib/"}]}',
          );
        projectDir
            .childDirectory('.dart_tool')
            .childFile('package_graph.json')
            .writeAsStringSync(
              '{"configVersion": 1, "roots": ["my_app"], "packages": [{"name": "my_app", "dependencies": [], "devDependencies": []}]}',
            );
        projectDir.childDirectory('linux').childFile('CMakeLists.txt').createSync(recursive: true);
        globals.fs.currentDirectory = projectDir;

        final ExtensionBackedDevice device = createTestDevice(extension);

        final LaunchResult result = await device.startApp(
          null,
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

        final Map<String, Object?> buildCall = await buildCompleter.future;
        final envMap = buildCall['environment']! as Map<String, Object?>;
        final env = BuildEnvironment.fromJson(envMap);
        expect(env.plugins, isEmpty);
      },
      overrides: <Type, Generator>{
        FileSystem: () => MemoryFileSystem.test(),
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () =>
            FakePlatform(environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'}),
        ToolExtensionManager: () => manager,
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

        final ExtensionBackedDevice device = createTestDevice(extension);

        expect(
          () => device.startApp(null, debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug)),
          throwsToolExit(message: 'Tool extension does not support the "build" service.'),
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => MemoryFileSystem.test(),
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () =>
            FakePlatform(environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'}),
        ToolExtensionManager: () => manager,
      },
    );

    testUsingContext(
      'throws ToolExit when build fails',
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

        final ExtensionBackedDevice device = createTestDevice(extension);

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
            message: 'Build compilation failed: Compilation failed due to syntax error',
          ),
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => MemoryFileSystem.test(),
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () =>
            FakePlatform(environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'}),
        ToolExtensionManager: () => manager,
      },
    );
  });
  group('Dynamic Extension Build Subcommands (Tool Extension Protocol CLI)', () {
    testWithoutContext(
      'build.getTargets includes cliSubcommand and cliDescription and ExtensionBuildTarget.fromJson parses them accurately',
      () async {
        final buildService = LinuxBuildService();
        final Map<String, Function> rpcHandlers = await buildService.initialize();
        final getTargets =
            rpcHandlers['getTargets']!
                as Future<List<Map<String, Object?>>> Function(Map<String, Object?>);

        final List<Map<String, Object?>> targetsJson = await getTargets(<String, Object?>{});
        expect(targetsJson, isNotEmpty);
        final Map<String, Object?> targetMap = targetsJson.first;

        expect(targetMap['name'], 'assemble_linux_app');
        expect(targetMap['cliSubcommand'], 'custom-linux');
        expect(
          targetMap['cliDescription'],
          'Build a prototype Linux extension desktop application.',
        );

        final target = ExtensionBuildTarget.fromJson(targetMap);
        expect(target.name, 'assemble_linux_app');
        expect(target.cliSubcommand, 'custom-linux');
        expect(target.cliDescription, 'Build a prototype Linux extension desktop application.');
        expect(target.dependencies, isEmpty);
        expect(target.inputs, isEmpty);
        expect(target.outputs, isEmpty);

        // Verify null-safe parsing when optional lists are omitted
        final minimalTarget = ExtensionBuildTarget.fromJson(<String, Object?>{
          'name': 'minimal_target',
          'cliSubcommand': 'mini',
        });
        expect(minimalTarget.name, 'minimal_target');
        expect(minimalTarget.cliSubcommand, 'mini');
        expect(minimalTarget.cliDescription, isNull);
        expect(minimalTarget.dependencies, isEmpty);
        expect(minimalTarget.inputs, isEmpty);
        expect(minimalTarget.outputs, isEmpty);
      },
    );

    testWithoutContext(
      'LinuxBuildService compiles target and dynamically generates plugin symlinks, CMake configurations, and C++ registrants when plugins are present',
      () async {
        final fs = MemoryFileSystem.test();
        fs.directory('/project/linux').createSync(recursive: true);
        fs.directory('/build/out').createSync(recursive: true);

        final fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
          const FakeCommand(
            command: <String>[
              'cmake',
              '-G',
              'Ninja',
              '-DCMAKE_BUILD_TYPE=Debug',
              '-DFLUTTER_TARGET_PLATFORM=linux-x64',
              '-S',
              '/project/linux',
              '-B',
              '/build/out',
            ],
            environment: <String, String>{},
          ),
          const FakeCommand(
            command: <String>['cmake', '--build', '/build/out', '--target', 'install'],
            environment: <String, String>{},
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
          plugins: <ExtensionPlugin>[
            ExtensionPlugin(
              configuration: const <String, Object?>{'pluginClass': 'UrlLauncherPlugin'},
              name: 'url_launcher_linux',
              path: '/plugins/url_launcher_linux',
            ),
            ExtensionPlugin(
              configuration: const <String, Object?>{'ffiPlugin': true},
              name: 'my_ffi_plugin',
              path: '/plugins/my_ffi_plugin',
            ),
          ],
          projectRoot: Uri.parse('file:///project'),
        );

        final Map<String, Object?> result = await build(<String, Object?>{
          'targetName': 'assemble_linux_app',
          'environment': env.toMap(),
        });

        expect(result['success'], true);
        expect(fakeProcessManager, hasNoRemainingExpectations);

        // Verify symlinks were created
        final Directory symlinkDir = fs.directory(
          '/project/linux/flutter/ephemeral/.plugin_symlinks',
        );
        expect(symlinkDir.childLink('url_launcher_linux').existsSync(), isTrue);
        expect(
          symlinkDir.childLink('url_launcher_linux').targetSync(),
          '/plugins/url_launcher_linux',
        );
        expect(symlinkDir.childLink('my_ffi_plugin').existsSync(), isTrue);
        expect(symlinkDir.childLink('my_ffi_plugin').targetSync(), '/plugins/my_ffi_plugin');

        // Verify generated_plugins.cmake content
        final File cmakeFile = fs.file('/project/linux/flutter/generated_plugins.cmake');
        expect(cmakeFile.existsSync(), isTrue);
        final String cmakeContent = cmakeFile.readAsStringSync();
        expect(cmakeContent, contains('list(APPEND FLUTTER_PLUGIN_LIST\n  url_launcher_linux\n)'));
        expect(cmakeContent, contains('list(APPEND FLUTTER_FFI_PLUGIN_LIST\n  my_ffi_plugin\n)'));
        expect(
          cmakeContent,
          contains(
            r'add_subdirectory(flutter/ephemeral/.plugin_symlinks/${plugin}/linux plugins/${plugin})',
          ),
        );

        // Verify generated_plugin_registrant.h
        final File headerFile = fs.file('/project/linux/flutter/generated_plugin_registrant.h');
        expect(headerFile.existsSync(), isTrue);
        final String headerContent = headerFile.readAsStringSync();
        expect(headerContent, contains('void fl_register_plugins(FlPluginRegistry* registry);'));

        // Verify generated_plugin_registrant.cc
        final File sourceFile = fs.file('/project/linux/flutter/generated_plugin_registrant.cc');
        expect(sourceFile.existsSync(), isTrue);
        final String sourceContent = sourceFile.readAsStringSync();
        expect(sourceContent, contains('#include <url_launcher_linux/url_launcher_plugin.h>'));
        expect(sourceContent, contains('void fl_register_plugins(FlPluginRegistry* registry) {'));
        expect(
          sourceContent,
          contains('g_autoptr(FlPluginRegistrar) url_launcher_linux_registrar ='),
        );
        expect(
          sourceContent,
          contains('fl_plugin_registry_get_registrar_for_plugin(registry, "UrlLauncherPlugin");'),
        );
        expect(
          sourceContent,
          contains('url_launcher_plugin_register_with_registrar(url_launcher_linux_registrar);'),
        );
      },
    );

    group('BuildCommand Dynamic Registration & Delegation', () {
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
        List<Map<String, Object?>>? targets,
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

        mockExtensionPeer!.registerMethod('build.getTargets', () {
          return targets ??
              <Map<String, Object?>>[
                <String, Object?>{
                  'name': 'custom_target',
                  'cliSubcommand': 'custom-ext',
                  'cliDescription': 'Build custom ext target.',
                  'dependencies': <String>[],
                  'inputs': <String>[],
                  'outputs': <String>[],
                },
              ];
        });

        mockExtensionPeer!.registerMethod('build.build', (rpc.Parameters params) {
          final String targetName = params['targetName'].asString;
          final Map<String, Object?> environment = params['environment'].asMap
              .cast<String, Object?>();

          buildCompleter?.complete(<String, Object?>{
            'targetName': targetName,
            'environment': environment,
          });

          return <String, Object?>{'success': true};
        });

        unawaited(mockExtensionPeer!.listen());
        return extension;
      }

      testUsingContext(
        'BuildCommand dynamically registers BuildExtensionSubCommand and delegates build over RPC',
        () async {
          Cache.disableLocking();
          final buildCompleter = Completer<Map<String, Object?>>();
          await connectMockExtension(services: <String>['build'], buildCompleter: buildCompleter);

          final Directory projectDir = globals.fs.directory('/project');
          projectDir.createSync(recursive: true);
          projectDir.childFile('pubspec.yaml').writeAsStringSync('name: my_app\n');
          projectDir.childDirectory('lib').childFile('main.dart').createSync(recursive: true);
          projectDir.childFile('.packages').createSync();
          projectDir.childDirectory('.dart_tool').childFile('package_config.json')
            ..createSync(recursive: true)
            ..writeAsStringSync(
              '{"configVersion": 2, "packages": [{"name": "my_app", "rootUri": "../", "packageUri": "lib/"}]}',
            );
          globals.fs.currentDirectory = projectDir;

          final CommandRunner<void> runner = createTestCommandRunner(
            BuildCommand(
              artifacts: globals.artifacts!,
              cache: globals.cache,
              fileSystem: globals.fs,
              flutterVersion: globals.flutterVersion,
              buildSystem: globals.buildSystem,
              osUtils: globals.os,
              logger: globals.logger,
              androidSdk: globals.androidSdk,
              config: globals.config,
              platform: globals.platform,
              processUtils: globals.processUtils,
              processManager: globals.processManager,
              fileSystemUtils: globals.fsUtils,
              templateRenderer: globals.templateRenderer,
              terminal: globals.terminal,
              plistParser: globals.plistParser,
              xcode: globals.xcode,
            ),
          );
          await runner.run(<String>['build', 'custom-ext', '--debug', '--dart-define=FOO=BAR']);

          final Map<String, Object?> buildCall = await buildCompleter.future;
          expect(buildCall['targetName'], 'custom_target');

          final envMap = buildCall['environment']! as Map<String, Object?>;
          final env = BuildEnvironment.fromJson(envMap);

          expect(env.defines['FLUTTER_BUILD_MODE'], 'debug');
          expect(env.defines['CMAKE_BUILD_TYPE'], 'Debug');
          expect(env.defines['DART_DEFINES'], contains(encodeDartDefines(<String>['FOO=BAR'])));
        },
        overrides: <Type, Generator>{
          Cache: () => Cache.test(processManager: FakeProcessManager.any()),
          FileSystem: () => MemoryFileSystem.test(),
          Platform: () => FakePlatform(
            environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'},
          ),
          ProcessManager: () => FakeProcessManager.any(),
          ToolExtensionManager: () => manager,
        },
      );

      testUsingContext(
        'BuildCommand triggers pre-build plugin discovery and injection hooks prior to RPC delegation',
        () async {
          Cache.disableLocking();
          final buildCompleter = Completer<Map<String, Object?>>();
          await connectMockExtension(
            services: <String>['build'],
            targets: <Map<String, Object?>>[
              <String, Object?>{
                'name': 'custom_plugin_target',
                'cliSubcommand': 'custom-plugin',
                'cliDescription': 'Build custom plugin target.',
                'pluginPlatformKey': 'linux',
                'generatesCmakePluginFiles': true,
                'targetPlatformDirectory': 'linux-x64',
                'dependencies': <String>[],
                'inputs': <String>[],
                'outputs': <String>[],
              },
            ],
            buildCompleter: buildCompleter,
          );

          final Directory projectDir = globals.fs.directory('/project');
          projectDir.createSync(recursive: true);
          projectDir.childFile('pubspec.yaml').writeAsStringSync('name: my_app\n');
          projectDir.childDirectory('lib').childFile('main.dart').createSync(recursive: true);
          projectDir.childFile('.packages').createSync();
          projectDir.childDirectory('.dart_tool').childFile('package_config.json')
            ..createSync(recursive: true)
            ..writeAsStringSync(
              '{"configVersion": 2, "packages": [{"name": "my_app", "rootUri": "../", "packageUri": "lib/"}]}',
            );
          projectDir
              .childDirectory('.dart_tool')
              .childFile('package_graph.json')
              .writeAsStringSync(
                '{"configVersion": 1, "roots": ["my_app"], "packages": [{"name": "my_app", "dependencies": [], "devDependencies": []}]}',
              );
          projectDir
              .childDirectory('linux')
              .childFile('CMakeLists.txt')
              .createSync(recursive: true);
          globals.fs.currentDirectory = projectDir;

          final CommandRunner<void> runner = createTestCommandRunner(
            BuildCommand(
              artifacts: globals.artifacts!,
              cache: globals.cache,
              fileSystem: globals.fs,
              flutterVersion: globals.flutterVersion,
              buildSystem: globals.buildSystem,
              osUtils: globals.os,
              logger: globals.logger,
              androidSdk: globals.androidSdk,
              config: globals.config,
              platform: globals.platform,
              processUtils: globals.processUtils,
              processManager: globals.processManager,
              fileSystemUtils: globals.fsUtils,
              templateRenderer: globals.templateRenderer,
              terminal: globals.terminal,
              plistParser: globals.plistParser,
              xcode: globals.xcode,
            ),
          );
          await runner.run(<String>['build', 'custom-plugin', '--debug']);

          final Map<String, Object?> buildCall = await buildCompleter.future;
          expect(buildCall['targetName'], 'custom_plugin_target');

          final envMap = buildCall['environment']! as Map<String, Object?>;
          final env = BuildEnvironment.fromJson(envMap);
          expect(env.plugins, isEmpty);
        },
        overrides: <Type, Generator>{
          Cache: () => Cache.test(processManager: FakeProcessManager.any()),
          FileSystem: () => MemoryFileSystem.test(),
          Platform: () => FakePlatform(
            environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'},
          ),
          ProcessManager: () => FakeProcessManager.any(),
          ToolExtensionManager: () => manager,
        },
      );
    });
  });
}
