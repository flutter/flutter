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
  _TestDeviceService({this.eventPort});

  final SendPort? eventPort;
  bool _running = false;

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

  @override
  Future<bool> launchApp({
    required ExtensionDebuggingOptions debuggingOptions,
    required String deviceId,
    required Uri executableUri,
  }) async {
    if (deviceId != 'test-device-1') {
      return false;
    }
    _running = true;
    eventPort?.send(<String, Object?>{
      'event': 'launchApp',
      'deviceId': deviceId,
      'executableUri': executableUri.toString(),
      'buildMode': debuggingOptions.buildMode.cliName,
      'debuggingEnabled': debuggingOptions.debuggingEnabled,
    });
    return true;
  }

  @override
  Future<Uri?> getVmServiceUri({required String deviceId}) async {
    if (deviceId != 'test-device-1' || !_running) {
      return null;
    }
    return Uri.parse('http://127.0.0.1:43210/auth=/');
  }

  @override
  Future<bool> stopApp({required String deviceId}) async {
    if (deviceId != 'test-device-1' || !_running) {
      return false;
    }
    _running = false;
    return true;
  }

  @override
  Future<void> startLogStream({required String deviceId}) async {
    emitLogLine(deviceId: deviceId, line: 'device log line 1');
    emitLogLine(deviceId: 'other-device', line: 'other device line');
    emitLogLine(deviceId: deviceId, line: 'device log line 2');
  }

  @override
  Future<void> stopLogStream({required String deviceId}) async {
    eventPort?.send(<String, Object?>{'event': 'stopLogStream', 'deviceId': deviceId});
  }
}

final class _TestBuildTarget extends BuildTarget {
  const _TestBuildTarget([this.name = 'custom-target'])
    : super(
        description: 'Builds custom-target',
        outputDir: '${BuiltInPlaceholders.outputDir}/custom',
        targetPlatform: 'linux-x64',
      );

  @override
  final String name;

  @override
  Future<ExtensionBuildResult> build(ExtensionBuildContext context) async {
    return ExtensionBuildResult(
      success: true,
      executableUri: context.outputDir.resolve('app_bundle'),
    );
  }
}

final class _TestAssembleTarget extends AssembleTarget {
  const _TestAssembleTarget()
    : super(description: 'Assembles custom_assemble', targetPlatform: 'linux-x64');

  @override
  String get name => 'custom_assemble';

  @override
  Future<ExtensionBuildResult> build(ExtensionAssembleContext context) async {
    return ExtensionBuildResult(
      success: true,
      executableUri: context.buildDir.resolve('assembled.bin'),
    );
  }
}

final class _TestBuildService extends BuildService {
  _TestBuildService({this.targets = const <BuildTarget>[_TestBuildTarget()]});

  final List<BuildTarget> targets;

  @override
  List<BuildTarget> get buildTargets => targets;

  @override
  List<AssembleTarget> get assembleTargets => const <AssembleTarget>[_TestAssembleTarget()];
}

final class _TestArtifactService extends ArtifactService {
  static const _sampleSha256 = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

  @override
  Future<List<ArtifactDependency>> listRequiredArtifacts({
    required String engineVersion,
    required HostPlatform hostPlatform,
    Set<String>? targetPlatforms,
  }) async {
    final artifact = ArtifactDependency(
      name: 'custom-sysroot',
      sha256: _sampleSha256,
      url: Uri.parse('https://example.com/$engineVersion/sysroot.zip'),
      hostPlatform: HostPlatform.linux_x64,
      targetPlatform: 'custom-arm64',
    );
    if (!artifact.matchesPlatforms(
      currentHostPlatform: hostPlatform,
      targetPlatforms: targetPlatforms,
    )) {
      return const <ArtifactDependency>[];
    }
    return <ArtifactDependency>[artifact];
  }
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

final class _AsyncErrorService extends ToolExtensionService {
  @override
  String get namespace => 'error';

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      'triggerUnhandledError': (Map<String, Object?> _) {
        Timer.run(() {
          throw StateError('Simulated post-handshake isolate crash');
        });
        return Completer<Object?>().future;
      },
    };
  }
}

final class _MalformedNotificationService extends ToolExtensionService {
  @override
  String get namespace => 'malformed';

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      'emitBadLog': (Map<String, Object?> _) {
        sendNotification(ToolExtensionService.logNotificationMethod, <String, Object?>{
          ExtensionLogMessage.levelKey: 'not_a_valid_level',
          ExtensionLogMessage.messageKey: 'bad log',
          ExtensionLogMessage.timestampKey: '2026-10-21T00:00:00.000Z',
        });
        return 'ok';
      },
      'emitBadDeviceLog': (Map<String, Object?> _) {
        sendNotification(DeviceService.logEntryNotificationMethod, <String, Object?>{
          DeviceService.deviceIdParam: 'test-device-1',
          DeviceService.lineKey: 12345,
        });
        return 'ok';
      },
      'emitValidCustom': (Map<String, Object?> params) {
        sendNotification('malformed.customEvent', params);
        return 'ok';
      },
    };
  }
}

Future<ExtensionTestHarness> _spawnFullTestHarness({
  SendPort? cleanedPort,
  SendPort? deviceEventsPort,
}) {
  return ExtensionTestHarness.spawn((SendPort sendPort) {
    return ToolExtensionEntryPoint.run(
      sendPort,
      <ToolExtensionService>[
        _TestDiagnosticsService(),
        _TestConfigService(),
        _TestTemplateService(),
        _TestDeviceService(eventPort: deviceEventsPort),
        _TestBuildService(),
        _TestArtifactService(),
        _TestCleanService(cleanedPort: cleanedPort),
      ],
      extensionName: 'test_extension',
      supportedPlatforms: const <String>{'linux'},
    );
  });
}

void main() {
  const methodNotFoundErrorCode = -32601;
  const invalidParamsErrorCode = -32602;

  group('createTestDependencies (Tier 1)', () {
    test('MemoryExtensionFileSystem supports hermetic file and directory operations', () async {
      final ExtensionDependencies dependencies = createTestDependencies();
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
  });

  group('ExtensionTestHarness (Tier 2)', () {
    test('diagnosticsClient and configClient query diagnostics, logs, and configuration', () async {
      final ExtensionTestHarness harness = await _spawnFullTestHarness();
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
    });

    test('templateClient queries app, plugin, and project templates', () async {
      final ExtensionTestHarness harness = await _spawnFullTestHarness();
      addTearDown(harness.dispose);

      expect(await harness.templateClient.getAppTemplates(), <String>{'custom_os/Runner.tmpl'});
      expect(await harness.templateClient.getPluginTemplates(), <String>{'custom_os/Plugin.tmpl'});
      final List<ExtensionProjectTemplate> projectTemplates = await harness.templateClient
          .getProjectTemplates();
      expect(projectTemplates, hasLength(1));
      expect(projectTemplates.first.name, 'custom-app');
      final Map<String, Object?> generatedParams = await harness.templateClient
          .generateTemplateParameters('custom-app', const <String, Object?>{'projectName': 'app'});
      expect(generatedParams['customKey'], 'customValue');
    });

    test('deviceClient manages device discovery, app lifecycle, and log streaming', () async {
      final deviceEventsPort = ReceivePort();
      addTearDown(deviceEventsPort.close);
      final deviceEvents = <Map<String, Object?>>[];
      final StreamSubscription<Object?> deviceEventSub = deviceEventsPort.listen((Object? event) {
        if (event case final Map<String, Object?> map) {
          deviceEvents.add(map);
        }
      });
      addTearDown(deviceEventSub.cancel);

      final ExtensionTestHarness harness = await _spawnFullTestHarness(
        deviceEventsPort: deviceEventsPort.sendPort,
      );
      addTearDown(harness.dispose);

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

      final bool launched = await harness.deviceClient.launchApp(
        debuggingOptions: const ExtensionDebuggingOptions(
          buildMode: .debug,
          debuggingEnabled: true,
        ),
        deviceId: 'test-device-1',
        executableUri: Uri.parse('file:///app/build/app_bundle'),
      );
      expect(launched, isTrue);
      expect(
        await harness.deviceClient.getVmServiceUri(deviceId: 'test-device-1'),
        Uri.parse('http://127.0.0.1:43210/auth=/'),
      );
      expect(await harness.deviceClient.stopApp(deviceId: 'test-device-1'), isTrue);
      expect(await harness.deviceClient.getVmServiceUri(deviceId: 'test-device-1'), isNull);

      final streamedLines = <String>[];
      final StreamSubscription<String> deviceLogSub = harness.deviceClient
          .logLines(deviceId: 'test-device-1')
          .listen(streamedLines.add);
      addTearDown(deviceLogSub.cancel);
      await harness.deviceClient.startLogStream(deviceId: 'test-device-1');
      await pumpEventQueue();
      expect(streamedLines, <String>['device log line 1', 'device log line 2']);
      await harness.deviceClient.stopLogStream(deviceId: 'test-device-1');
      await pumpEventQueue();
      expect(
        deviceEvents,
        contains(
          equals(const <String, Object?>{'event': 'stopLogStream', 'deviceId': 'test-device-1'}),
        ),
      );
    });

    test('buildClient, artifactClient, and cleanClient execute RPCs and dispose cleanly', () async {
      final cleanedPort = ReceivePort();
      addTearDown(cleanedPort.close);

      final ExtensionTestHarness harness = await _spawnFullTestHarness(
        cleanedPort: cleanedPort.sendPort,
      );
      addTearDown(harness.dispose);

      final List<ExtensionAssembleTarget> assembleTargets = await harness.buildClient
          .getAssembleTargets();
      expect(assembleTargets, hasLength(1));
      expect(assembleTargets.single.name, 'custom_assemble');

      final Uri flutterRoot = Uri.parse('file:///sdk/flutter/');
      final Uri projectRoot = Uri.parse('file:///app/');
      final Uri outputDir = Uri.parse('file:///app/build/');
      final Uri buildDir = Uri.parse('file:///app/.dart_tool/flutter_build/');

      final ExtensionBuildResult buildResult = await harness.buildClient.build(
        buildMode: .debug,
        flutterRoot: flutterRoot,
        mainPath: 'lib/main.dart',
        outputDir: outputDir,
        projectRoot: projectRoot,
        targetName: 'custom-target',
      );
      expect(buildResult.success, isTrue);
      expect(buildResult.executableUri, Uri.parse('file:///app/build/app_bundle'));

      final ExtensionBuildResult assembleResult = await harness.buildClient.assemble(
        buildDir: buildDir,
        buildMode: .debug,
        flutterRoot: flutterRoot,
        mainPath: 'lib/main.dart',
        outputDir: outputDir,
        projectRoot: projectRoot,
        targetName: 'custom_assemble',
      );
      expect(assembleResult.success, isTrue);
      expect(
        assembleResult.executableUri,
        Uri.parse('file:///app/.dart_tool/flutter_build/assembled.bin'),
      );

      final List<ArtifactDependency> matchingArtifacts = await harness.artifactClient
          .listRequiredArtifacts(
            engineVersion: 'engine123',
            hostPlatform: HostPlatform.linux_x64,
            targetPlatforms: const <String>{'custom-arm64'},
          );
      expect(matchingArtifacts, hasLength(1));
      expect(matchingArtifacts.single.name, 'custom-sysroot');

      final List<ArtifactDependency> filteredOutArtifacts = await harness.artifactClient
          .listRequiredArtifacts(
            engineVersion: 'engine123',
            hostPlatform: HostPlatform.darwin_arm64,
          );
      expect(filteredOutArtifacts, isEmpty);

      final cleanEnv = CleanEnvironment(buildDir: outputDir, projectRoot: projectRoot);
      await harness.cleanClient.clean(cleanEnv);
      final Object? rawCleaned = await cleanedPort.first;
      expect(rawCleaned, isA<Map<String, Object?>>());
      if (rawCleaned case final Map<String, Object?> cleanedMap) {
        expect(CleanEnvironment.fromJson(cleanedMap), cleanEnv);
      }

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
      expect(() => harness.onNotification('custom.event'), throwsA(isA<StateError>()));
    });

    test('surfaces malformed log and device.logEntry notifications as FormatExceptions', () async {
      final ExtensionTestHarness harness = await ExtensionTestHarness.spawn(
        (SendPort sendPort) => ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[_MalformedNotificationService()],
          extensionName: 'malformed_extension',
          supportedPlatforms: const <String>{'linux'},
        ),
      );
      addTearDown(harness.dispose);

      expect(
        () => harness.onNotification(ToolExtensionService.logNotificationMethod),
        throwsArgumentError,
      );

      final Future<void> badLogError = expectLater(
        harness.onLog,
        emitsError(isA<FormatException>()),
      );
      await harness.sendRawRequest('malformed.emitBadLog');
      await badLogError;

      final Future<void> badDeviceLogError = expectLater(
        harness.deviceClient.logLines(deviceId: 'test-device-1'),
        emitsError(isA<FormatException>()),
      );
      await harness.sendRawRequest('malformed.emitBadDeviceLog');
      await badDeviceLogError;

      final customEvents = <Map<String, Object?>>[];
      final StreamSubscription<Map<String, Object?>> customSub = harness
          .onNotification('malformed.customEvent')
          .listen(customEvents.add);
      addTearDown(customSub.cancel);
      await harness.sendRawRequest(
        'malformed.emitValidCustom',
        params: const <String, Object?>{'key': 'value'},
      );
      await pumpEventQueue();
      expect(customEvents, <Map<String, Object?>>[
        const <String, Object?>{'key': 'value'},
      ]);
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

    test('fails pending timeout: null requests and closes notification streams when isolate exits after handshake', () async {
      final ExtensionTestHarness harness = await ExtensionTestHarness.spawn(
        (SendPort sendPort) => ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[_ExitOnCleanService()],
          extensionName: 'exit_extension',
          supportedPlatforms: const <String>{'linux'},
        ),
      );
      addTearDown(harness.dispose);

      final Future<void> logStreamDone = expectLater(harness.onLog, emitsDone);
      final Future<void> customNotificationDone = expectLater(
        harness.onNotification('custom.event'),
        emitsDone,
      );

      await expectLater(
        harness.cleanClient
            .clean(
              CleanEnvironment(
                buildDir: Uri.parse('file:///app/build/'),
                projectRoot: Uri.parse('file:///app/'),
              ),
            )
            .timeout(const Duration(seconds: 5)),
        throwsA(isA<StateError>()),
      );
      await logStreamDone;
      await customNotificationDone;
      expect(harness.isDisposed, isTrue);
    });

    test('surfaces post-handshake unhandled isolate errors with extension details', () async {
      final ExtensionTestHarness harness = await ExtensionTestHarness.spawn(
        (SendPort sendPort) => ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[_AsyncErrorService()],
          extensionName: 'error_extension',
          supportedPlatforms: const <String>{'linux'},
        ),
      );
      addTearDown(harness.dispose);

      final Future<void> logError = expectLater(
        harness.onLog,
        emitsError(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('Simulated post-handshake isolate crash'),
          ),
        ),
      );
      await expectLater(
        harness.sendRawRequest('error.triggerUnhandledError', timeout: null),
        throwsA(isA<StateError>()),
      );
      await logError;

      expect(harness.isolateErrors, hasLength(1));
      expect(
        harness.isolateErrors.single.message,
        contains('Simulated post-handshake isolate crash'),
      );
      expect(harness.isDisposed, isTrue);
    });
  });

  group('verifyExtensionPackage (Tier 3)', () {
    ExtensionFileSystem createPackageFileSystem({
      String entrypointRelativePath = 'extension/flutter_tools/extension.dart',
      bool createEntrypoint = true,
    }) {
      final fs = MemoryExtensionFileSystem();
      final ExtensionDirectory root = fs.directory(Uri.parse('file:///ext_pkg/'))
        ..createSync(recursive: true);
      if (createEntrypoint) {
        final ExtensionFile entrypointFile = fs.file(root.uri.resolve(entrypointRelativePath));
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

    test('succeeds for conventional extension/flutter_tools/extension.dart entrypoint', () async {
      final ExtensionFileSystem fs = createPackageFileSystem();

      await verifyExtensionPackage(
        packageRoot: Uri.parse('file:///ext_pkg/'),
        entryPoint: validEntryPoint,
        fileSystem: fs,
      );
    });

    test(
      'succeeds when expectedConfig matches runtime capabilities, targets, and templates',
      () async {
        final ExtensionFileSystem fs = createPackageFileSystem(
          entrypointRelativePath: 'bin/test_ext.dart',
        );
        final expectedConfig = ExtensionPackageConfig(
          name: 'test_ext',
          entrypoint: 'bin/test_ext.dart',
          hostPlatforms: const <String>{'linux'},
          services: const <String>{'diagnostics', 'build', 'template'},
          buildTargets: const <String>{'custom-target'},
          templates: const <String>{'custom-app'},
          targetPlatforms: const <String>{'custom_os'},
        );

        await verifyExtensionPackage(
          packageRoot: Uri.parse('file:///ext_pkg/'),
          entryPoint: validEntryPoint,
          expectedConfig: expectedConfig,
          fileSystem: fs,
        );
      },
    );

    test('throws StateError when entrypoint file is missing', () async {
      final ExtensionFileSystem fs = createPackageFileSystem(createEntrypoint: false);

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
            contains('Extension entrypoint not found'),
          ),
        ),
      );
    });

    test('throws StateError when build target collides with built-in subcommand', () async {
      final ExtensionFileSystem fs = createPackageFileSystem();

      await expectLater(
        verifyExtensionPackage(
          packageRoot: Uri.parse('file:///ext_pkg/'),
          entryPoint: (SendPort sendPort) => ToolExtensionEntryPoint.run(
            sendPort,
            <ToolExtensionService>[
              _TestBuildService(targets: const <BuildTarget>[_TestBuildTarget('apk')]),
            ],
            extensionName: 'test_ext',
            supportedPlatforms: const <String>{'linux'},
          ),
          fileSystem: fs,
        ),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('collides with built-in flutter build subcommand'),
          ),
        ),
      );
    });

    test('throws FormatException when expectedConfig declares an unknown service', () async {
      final ExtensionFileSystem fs = createPackageFileSystem();
      final expectedConfig = ExtensionPackageConfig(
        name: 'test_ext',
        services: const <String>{'invalid_service'},
      );

      await expectLater(
        verifyExtensionPackage(
          packageRoot: Uri.parse('file:///ext_pkg/'),
          entryPoint: validEntryPoint,
          expectedConfig: expectedConfig,
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

    test(
      'throws StateError when expectedConfig drifts from runtime capabilities or targets',
      () async {
        final ExtensionFileSystem fs = createPackageFileSystem(
          entrypointRelativePath: 'bin/test_ext.dart',
        );

        await expectLater(
          verifyExtensionPackage(
            packageRoot: Uri.parse('file:///ext_pkg/'),
            entryPoint: validEntryPoint,
            expectedConfig: ExtensionPackageConfig(
              name: 'wrong_name',
              entrypoint: 'bin/test_ext.dart',
              hostPlatforms: const <String>{'linux'},
              services: const <String>{'diagnostics', 'build', 'template'},
            ),
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

        await expectLater(
          verifyExtensionPackage(
            packageRoot: Uri.parse('file:///ext_pkg/'),
            entryPoint: validEntryPoint,
            expectedConfig: ExtensionPackageConfig(
              name: 'test_ext',
              entrypoint: 'bin/test_ext.dart',
              hostPlatforms: const <String>{'linux'},
              services: const <String>{'diagnostics'},
            ),
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

        await expectLater(
          verifyExtensionPackage(
            packageRoot: Uri.parse('file:///ext_pkg/'),
            entryPoint: validEntryPoint,
            expectedConfig: ExtensionPackageConfig(
              name: 'test_ext',
              entrypoint: 'bin/test_ext.dart',
              hostPlatforms: const <String>{'linux'},
              services: const <String>{'diagnostics', 'build', 'template'},
              buildTargets: const <String>{'wrong-target'},
            ),
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

        await expectLater(
          verifyExtensionPackage(
            packageRoot: Uri.parse('file:///ext_pkg/'),
            entryPoint: validEntryPoint,
            expectedConfig: ExtensionPackageConfig(
              name: 'test_ext',
              entrypoint: 'bin/test_ext.dart',
              hostPlatforms: const <String>{'linux'},
              services: const <String>{'diagnostics', 'build', 'template'},
              buildTargets: const <String>{'custom-target'},
              templates: const <String>{'wrong-template'},
            ),
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
      },
    );
  });
}
