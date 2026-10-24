// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/testing.dart';
import 'package:test/test.dart';

final class _TestDiagnosticsService extends DiagnosticsExtension {
  @override
  String get title => 'Test Diagnostics';

  @override
  Future<List<ValidationResult>> runDiagnostics() async {
    log('Running test diagnostics', level: .trace, timestamp: DateTime.utc(2026, 10, 21));
    return <ValidationResult>[
      ValidationResult(ValidationType.success, const <ValidationMessage>[
        ValidationMessage('All checks passed'),
      ], statusInfo: 'OK'),
    ];
  }
}

final class _TestConfigService extends ConfigurationExtension {
  @override
  String get title => 'Test Configuration';

  @override
  Future<List<FeatureFlag>> getFeatureFlags() async {
    return const <FeatureFlag>[
      FeatureFlag(name: 'enable-test-ext', help: 'Enable test extension', enabledByDefault: true),
    ];
  }

  @override
  Future<List<ConfigOption>> getConfigurations() async {
    return const <ConfigOption>[
      ConfigOption(name: 'test-sdk-dir', help: 'Path to test SDK', value: '/opt/sdk'),
    ];
  }
}

final class _TestProjectTemplate extends ProjectTemplate {
  _TestProjectTemplate(this.name);

  @override
  final String name;

  @override
  bool get hidden => false;

  @override
  Set<String> get templateDependencies => const <String>{'app'};

  @override
  Set<String> get templateSources => const <String>{'pubspec.yaml.tmpl'};

  @override
  String get templatePath => 'package:test_ext/templates/$name';

  @override
  Future<Map<String, Object?>> generateTemplateParameters(
    Map<String, Object?> toolParameters,
  ) async {
    return <String, Object?>{...toolParameters, 'customKey': 'customValue'};
  }
}

final class _TestTemplateService extends TemplateService {
  @override
  Set<String> get appPlatformTemplates => const <String>{'custom_os/Runner.tmpl'};

  @override
  Set<String> get pluginPlatformTemplates => const <String>{'custom_os/Plugin.tmpl'};

  @override
  Set<ProjectTemplate> get projectTemplates => <ProjectTemplate>{
    _TestProjectTemplate('custom-app'),
  };
}

final class _TestDeviceService extends DeviceService {
  @override
  Future<List<TargetDevice>> getDevices() async {
    return const <TargetDevice>[
      TargetDevice(
        category: Category.mobile,
        id: 'test-device-1',
        name: 'Test Embedder Device',
        targetPlatform: 'custom-arm64',
      ),
    ];
  }

  @override
  Future<bool> isSupportedForProject({
    required String deviceId,
    required ExtensionFlutterProject project,
  }) async {
    return deviceId == 'test-device-1' && project.appName == 'supported_app';
  }
}

final class _TestBuildTarget extends BuildTarget {
  const _TestBuildTarget()
    : super(
        description: 'Builds custom-target',
        outputDir: '${BuiltInPlaceholders.outputDir}/custom',
        targetPlatform: 'linux-x64',
      );

  @override
  String get name => 'custom-target';

  @override
  Future<ExtensionBuildResult> build(ExtensionBuildContext context) async {
    return const ExtensionBuildResult(success: true);
  }
}

final class _TestBuildService extends BuildService {
  @override
  List<BuildTarget> get buildTargets => const <BuildTarget>[_TestBuildTarget()];
}

final class _TestCleanService extends CleanService {
  _TestCleanService({this.cleanedPort});

  final SendPort? cleanedPort;

  @override
  Future<void> clean(CleanEnvironment environment) async {
    cleanedPort?.send(environment.toMap());
  }
}

final class _ExitOnCleanService extends CleanService {
  @override
  Future<void> clean(CleanEnvironment environment) {
    Isolate.exit();
  }
}

void main() {
  const methodNotFoundErrorCode = -32601;
  const invalidParamsErrorCode = -32602;

  group('createTestDependencies (Tier 1)', () {
    test('MemoryExtensionFileSystem supports hermetic file and directory operations', () async {
      final ExtensionDependencies dependencies = createTestDependencies(
        environment: const <String, String>{'CUSTOM_SDK': '/sdk'},
      );
      expect(dependencies.operatingSystem, 'linux');
      expect(dependencies.environment['CUSTOM_SDK'], '/sdk');
      expect(
        () => dependencies.createHttpClient(),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('Unexpected HTTP request in hermetic test.'),
          ),
        ),
      );

      final ExtensionFileSystem fs = dependencies.fileSystem;
      final ExtensionDirectory projectDir = fs.directory(Uri.parse('file:///workspace/app/'));
      expect(projectDir.existsSync(), isFalse);

      expect(() => projectDir.createSync(), throwsA(isA<FileSystemException>()));

      projectDir.createSync(recursive: true);
      expect(projectDir.existsSync(), isTrue);
      expect(projectDir.path, '/workspace/app');
      expect(projectDir.uri, Uri.parse('file:///workspace/app/'));

      final ExtensionFile pubspecFile = projectDir.childFile('pubspec.yaml');
      expect(pubspecFile.existsSync(), isFalse);
      pubspecFile.writeAsStringSync('name: sample\n');
      expect(pubspecFile.existsSync(), isTrue);
      expect(pubspecFile.readAsStringSync(), 'name: sample\n');

      final ExtensionFile binaryFile = projectDir.childDirectory('build').childFile('app.bin');
      expect(
        () => binaryFile.writeAsBytesSync(<int>[1, 2, 3]),
        throwsA(isA<FileSystemException>()),
      );
      binaryFile.createSync(recursive: true);
      binaryFile.writeAsBytesSync(Uint8List.fromList(<int>[10, 20, 30]));
      expect(binaryFile.readAsBytesSync(), <int>[10, 20, 30]);

      expect(() => projectDir.deleteSync(), throwsA(isA<FileSystemException>()));

      await projectDir.delete(recursive: true);
      expect(projectDir.existsSync(), isFalse);
      expect(pubspecFile.existsSync(), isFalse);
      expect(binaryFile.existsSync(), isFalse);
    });

    test('FakeExtensionProcessManager validates command queue and expectations', () async {
      var callbackRan = false;
      final processManager = FakeExtensionProcessManager(<FakeExtensionCommand>[
        FakeExtensionCommand(
          command: const <String>['cmake', '-B', 'build'],
          workingDirectory: '/workspace/app',
          environment: const <String, String>{'CC': 'clang'},
          stdout: 'Configured\n',
          onRun: () {
            callbackRan = true;
          },
        ),
      ]);
      final ExtensionDependencies dependencies = createTestDependencies(
        processManager: processManager,
      );
      expect(processManager.hasRemainingCommands, isTrue);

      final ProcessResult result = await dependencies.processManager.run(
        const <String>['cmake', '-B', 'build'],
        workingDirectory: '/workspace/app',
        environment: const <String, String>{'CC': 'clang', 'EXTRA': '1'},
      );
      expect(result.exitCode, 0);
      expect(result.stdout, 'Configured\n');
      expect(callbackRan, isTrue);
      expect(processManager.hasRemainingCommands, isFalse);
      processManager.assertNoRemainingCommands();

      expect(
        () => dependencies.processManager.runSync(const <String>['ninja']),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('Unexpected command executed: ninja'),
          ),
        ),
      );

      processManager.addCommand(
        const FakeExtensionCommand(command: <String>['ninja', '-C', 'build']),
      );
      expect(() => processManager.assertNoRemainingCommands(), throwsA(isA<StateError>()));
      expect(
        () => dependencies.processManager.runSync(const <String>['ninja', '-C', 'other']),
        throwsA(isA<StateError>()),
      );
    });

    test('BufferExtensionLogger records and clears status, error, warning, and trace logs', () {
      final logger = BufferExtensionLogger();
      final ExtensionDependencies dependencies = createTestDependencies(logger: logger);

      dependencies.logger
        ..printStatus('status line')
        ..printWarning('warning line')
        ..printError('error line')
        ..printTrace('trace line');

      expect(logger.statusText, 'status line\n');
      expect(logger.warningText, 'warning line\n');
      expect(logger.errorText, 'error line\n');
      expect(logger.traceText, 'trace line\n');

      logger.clear();
      expect(logger.statusText, isEmpty);
      expect(logger.warningText, isEmpty);
      expect(logger.errorText, isEmpty);
      expect(logger.traceText, isEmpty);
    });
  });

  group('ExtensionTestHarness (Tier 2)', () {
    test('supports typed clients and logs', () async {
      final cleanedPort = ReceivePort();
      addTearDown(cleanedPort.close);

      final SendPort cleanedSendPort = cleanedPort.sendPort;

      final ExtensionTestHarness harness = await ExtensionTestHarness.spawn((SendPort sendPort) {
        return ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[
            _TestDiagnosticsService(),
            _TestConfigService(),
            _TestTemplateService(),
            _TestDeviceService(),
            _TestBuildService(),
            _TestCleanService(cleanedPort: cleanedSendPort),
          ],
          extensionName: 'test_extension',
          supportedPlatforms: const <String>{'linux'},
        );
      });
      addTearDown(harness.dispose);

      final receivedLogs = <ExtensionLogMessage>[];
      final StreamSubscription<ExtensionLogMessage> logSub = harness.onLog.listen(receivedLogs.add);
      addTearDown(logSub.cancel);

      expect(await harness.diagnosticsClient.getTitle(), 'Test Diagnostics');
      final List<ValidationResult> diagResults = await harness.diagnosticsClient.runDiagnostics();
      expect(diagResults, hasLength(1));
      await pumpEventQueue();
      expect(harness.logs, hasLength(1));
      expect(harness.logs.first.level, ExtensionLogLevel.trace);
      expect(harness.logs.first.message, 'Running test diagnostics');
      expect(harness.logs.first.timestamp, DateTime.utc(2026, 10, 21));
      expect(receivedLogs, equals(harness.logs));

      expect(await harness.configClient.getTitle(), 'Test Configuration');
      expect(await harness.configClient.getFeatureFlags(), hasLength(1));
      expect(await harness.configClient.getConfigurations(), hasLength(1));

      expect(await harness.templateClient.getAppTemplates(), <String>{'custom_os/Runner.tmpl'});
      expect(await harness.templateClient.getPluginTemplates(), <String>{'custom_os/Plugin.tmpl'});
      final List<ExtensionProjectTemplate> projectTemplates = await harness.templateClient
          .getProjectTemplates();
      expect(projectTemplates, hasLength(1));
      expect(projectTemplates.first.name, 'custom-app');
      final Map<String, Object?> generatedParams = await harness.templateClient
          .generateTemplateParameters('custom-app', const <String, Object?>{'projectName': 'app'});
      expect(generatedParams['customKey'], 'customValue');

      final List<TargetDevice> devices = await harness.deviceClient.getDevices();
      expect(devices, hasLength(1));
      final project = ExtensionFlutterProject(
        appName: 'supported_app',
        buildDirectory: Uri.parse('file:///app/build/'),
        directory: Uri.parse('file:///app/'),
      );
      expect(
        await harness.deviceClient.isSupportedForProject(
          deviceId: 'test-device-1',
          project: project,
        ),
        isTrue,
      );

      final ExtensionBuildResult buildResult = await harness.buildClient.build(
        buildMode: .debug,
        mainPath: 'lib/main.dart',
        projectRoot: Uri.parse('file:///app/'),
        targetName: 'custom-target',
      );
      expect(buildResult.success, isTrue);

      final cleanEnv = CleanEnvironment(
        buildDir: Uri.parse('file:///app/build/'),
        projectRoot: Uri.parse('file:///app/'),
      );
      await harness.cleanClient.clean(cleanEnv);
      final Object? rawCleaned = await cleanedPort.first;
      expect(CleanEnvironment.fromJson(rawCleaned! as Map<String, Object?>), cleanEnv);

      await expectLater(
        harness.sendRawRequest('nonexistent.method'),
        throwsA(
          isA<RpcException>().having((RpcException e) => e.code, 'code', methodNotFoundErrorCode),
        ),
      );

      await expectLater(
        harness.sendRawRequest(CleanService.cleanMethod, params: const <String, Object?>{}),
        throwsA(
          isA<RpcException>().having((RpcException e) => e.code, 'code', invalidParamsErrorCode),
        ),
      );

      await harness.dispose();
      expect(harness.isDisposed, isTrue);
      await harness.dispose();
      expect(
        () => harness.sendRawRequest(BuildService.getBuildTargetsMethod),
        throwsA(isA<StateError>()),
      );
    });

    test('cleans up ports and rethrows when isolate fails during startup', () async {
      await expectLater(
        ExtensionTestHarness.spawn((SendPort _) {
          throw StateError('Simulated startup crash');
        }),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('Simulated startup crash'),
          ),
        ),
      );
    });

    test('fails pending requests immediately when isolate exits after handshake', () async {
      final ExtensionTestHarness harness = await ExtensionTestHarness.spawn(
        (SendPort sendPort) => ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[_ExitOnCleanService()],
          extensionName: 'exit_extension',
          supportedPlatforms: const <String>{'linux'},
        ),
      );
      addTearDown(harness.dispose);

      await expectLater(
        harness
            .sendRawRequest(
              CleanService.cleanMethod,
              params: <String, Object?>{
                CleanService.environmentParam: CleanEnvironment(
                  buildDir: Uri.parse('file:///app/build/'),
                  projectRoot: Uri.parse('file:///app/'),
                ).toMap(),
              },
              timeout: const Duration(seconds: 30),
            )
            .timeout(const Duration(seconds: 5)),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('verifyExtensionPackage (Tier 3)', () {
    ExtensionFileSystem createManifestFileSystem({
      String? yamlContent,
      bool createEntrypoint = true,
    }) {
      final fs = MemoryExtensionFileSystem();
      final ExtensionDirectory root = fs.directory(Uri.parse('file:///ext_pkg/'))
        ..createSync(recursive: true);
      if (yamlContent != null) {
        final ExtensionFile manifestFile = root
            .childDirectory('extension')
            .childDirectory('flutter_tools')
            .childFile('config.yaml');
        manifestFile.createSync(recursive: true);
        manifestFile.writeAsStringSync(yamlContent);
      }
      if (createEntrypoint) {
        final ExtensionFile entrypointFile = root.childDirectory('bin').childFile('test_ext.dart');
        entrypointFile.createSync(recursive: true);
        entrypointFile.writeAsStringSync('// entrypoint stub\n');
      }
      return fs;
    }

    Future<void> validEntryPoint(SendPort sendPort) => ToolExtensionEntryPoint.run(
      sendPort,
      <ToolExtensionService>[
        _TestDiagnosticsService(),
        _TestBuildService(),
        _TestTemplateService(),
      ],
      extensionName: 'test_ext',
      supportedPlatforms: const <String>{'linux'},
    );

    test(
      'succeeds when config.yaml matches runtime capabilities, targets, and templates',
      () async {
        final ExtensionFileSystem fs = createManifestFileSystem(
          yamlContent: '''
name: test_ext
protocolVersion: 1
entrypoint: bin/test_ext.dart
supportedPlatforms:
  - linux
services:
  - diagnostics
  - build
  - template
buildTargets:
  - custom-target
templates:
  - custom-app
''',
        );

        await verifyExtensionPackage(
          packageRoot: Uri.parse('file:///ext_pkg/'),
          entryPoint: validEntryPoint,
          fileSystem: fs,
        );
      },
    );

    test('throws StateError when config.yaml is missing', () async {
      final ExtensionFileSystem fs = createManifestFileSystem();

      await expectLater(
        verifyExtensionPackage(
          packageRoot: Uri.parse('file:///ext_pkg/'),
          entryPoint: validEntryPoint,
          fileSystem: fs,
        ),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('Extension manifest not found'),
          ),
        ),
      );
    });

    test('throws FormatException when config.yaml declares an unknown service', () async {
      final ExtensionFileSystem fs = createManifestFileSystem(
        yamlContent: '''
name: test_ext
protocolVersion: 1
entrypoint: bin/test_ext.dart
services:
  - invalid_service
''',
      );

      await expectLater(
        verifyExtensionPackage(
          packageRoot: Uri.parse('file:///ext_pkg/'),
          entryPoint: validEntryPoint,
          fileSystem: fs,
        ),
        throwsA(
          isA<FormatException>().having(
            (FormatException e) => e.message,
            'message',
            contains('Unknown service "invalid_service"'),
          ),
        ),
      );
    });

    test('throws StateError when extensionName mismatches config.yaml', () async {
      final ExtensionFileSystem fs = createManifestFileSystem(
        yamlContent: '''
name: wrong_name
protocolVersion: 1
entrypoint: bin/test_ext.dart
supportedPlatforms: [linux]
services: [diagnostics, build, template]
''',
      );

      await expectLater(
        verifyExtensionPackage(
          packageRoot: Uri.parse('file:///ext_pkg/'),
          entryPoint: validEntryPoint,
          fileSystem: fs,
        ),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('Extension name mismatch'),
          ),
        ),
      );
    });

    test('throws StateError when services mismatch config.yaml', () async {
      final ExtensionFileSystem fs = createManifestFileSystem(
        yamlContent: '''
name: test_ext
protocolVersion: 1
entrypoint: bin/test_ext.dart
supportedPlatforms: [linux]
services: [diagnostics]
''',
      );

      await expectLater(
        verifyExtensionPackage(
          packageRoot: Uri.parse('file:///ext_pkg/'),
          entryPoint: validEntryPoint,
          fileSystem: fs,
        ),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('Services mismatch'),
          ),
        ),
      );
    });

    test('throws StateError when buildTargets mismatch runtime getBuildTargets', () async {
      final ExtensionFileSystem fs = createManifestFileSystem(
        yamlContent: '''
name: test_ext
protocolVersion: 1
entrypoint: bin/test_ext.dart
supportedPlatforms: [linux]
services: [diagnostics, build, template]
buildTargets: [wrong-target]
''',
      );

      await expectLater(
        verifyExtensionPackage(
          packageRoot: Uri.parse('file:///ext_pkg/'),
          entryPoint: validEntryPoint,
          fileSystem: fs,
        ),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('Build targets mismatch'),
          ),
        ),
      );
    });

    test('throws StateError when templates mismatch runtime getProjectTemplates', () async {
      final ExtensionFileSystem fs = createManifestFileSystem(
        yamlContent: '''
name: test_ext
protocolVersion: 1
entrypoint: bin/test_ext.dart
supportedPlatforms: [linux]
services: [diagnostics, build, template]
buildTargets: [custom-target]
templates: [wrong-template]
''',
      );

      await expectLater(
        verifyExtensionPackage(
          packageRoot: Uri.parse('file:///ext_pkg/'),
          entryPoint: validEntryPoint,
          fileSystem: fs,
        ),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('Templates mismatch'),
          ),
        ),
      );
    });

    test('preserves quoted commas in flow lists and rejects unsupported YAML syntax', () async {
      final ExtensionFileSystem quotedCommaFs = createManifestFileSystem(
        yamlContent: '''
name: test_ext
protocolVersion: 1
entrypoint: bin/test_ext.dart
supportedPlatforms: [linux]
services: [diagnostics, build, template]
buildTargets: ["target,with,comma"]
''',
      );

      await expectLater(
        verifyExtensionPackage(
          packageRoot: Uri.parse('file:///ext_pkg/'),
          entryPoint: validEntryPoint,
          fileSystem: quotedCommaFs,
        ),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('config.yaml declares {target,with,comma}'),
          ),
        ),
      );

      final ExtensionFileSystem blockScalarFs = createManifestFileSystem(
        yamlContent: '''
name: |-
  test_ext
''',
      );

      await expectLater(
        verifyExtensionPackage(
          packageRoot: Uri.parse('file:///ext_pkg/'),
          entryPoint: validEntryPoint,
          fileSystem: blockScalarFs,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
