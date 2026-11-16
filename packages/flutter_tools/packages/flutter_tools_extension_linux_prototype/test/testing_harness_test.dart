// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

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

final class _DomainErrorDiagnosticsService extends DiagnosticsExtension {
  @override
  String get title => 'Failing Diagnostics';

  @override
  Future<List<ValidationResult>> runDiagnostics() async {
    throw const ToolExtensionException('Missing custom toolchain at /opt/custom');
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
  _TestTemplateService({this.appTemplates = const <String>{'custom_os/Runner.tmpl'}});

  final Set<String> appTemplates;

  @override
  Set<String> get appPlatformTemplates => appTemplates;

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
  const _TestAssembleTarget([this.name = 'custom_assemble'])
    : super(description: 'Assembles custom_assemble', targetPlatform: 'linux-x64');

  @override
  final String name;

  @override
  Future<ExtensionBuildResult> build(ExtensionAssembleContext context) async {
    return ExtensionBuildResult(
      success: true,
      executableUri: context.buildDir.resolve('assembled.bin'),
    );
  }
}

final class _TestBuildService extends BuildService {
  _TestBuildService({
    this.assembleTargetList = const <AssembleTarget>[_TestAssembleTarget()],
    this.targets = const <BuildTarget>[_TestBuildTarget()],
  });

  final List<AssembleTarget> assembleTargetList;
  final List<BuildTarget> targets;

  @override
  List<BuildTarget> get buildTargets => targets;

  @override
  List<AssembleTarget> get assembleTargets => assembleTargetList;
}

final class _ThrowingBuildService extends BuildService {
  @override
  List<BuildTarget> get buildTargets =>
      throw StateError('Service RPC should not be invoked when host platform is excluded.');
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

final class _GatedShutdownService extends ToolExtensionService {
  _GatedShutdownService({required this.completedSendPort, required this.gateSendPort});

  final SendPort completedSendPort;
  final SendPort gateSendPort;

  @override
  String get namespace => 'lifecycle';

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async =>
      const <String, ExtensionRpcHandler>{};

  @override
  Future<void> shutdown() async {
    final releasePort = ReceivePort();
    gateSendPort.send(releasePort.sendPort);
    await releasePort.first;
    releasePort.close();
    completedSendPort.send('shutdown_complete');
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
      'emitTimestampFreeLog': (Map<String, Object?> _) {
        sendNotification(ToolExtensionService.logNotificationMethod, const <String, Object?>{
          ExtensionLogMessage.levelKey: 'info',
          ExtensionLogMessage.messageKey: 'log without timestamp',
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

final class _UnknownNamespaceService extends ToolExtensionService {
  @override
  String get namespace => 'unknown_namespace';

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async =>
      const <String, ExtensionRpcHandler>{};
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

  group('ExtensionTestHarness', () {
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

    test(
      'dispose sends extension.shutdown and concurrent dispose calls await full shutdown',
      () async {
        final gatePort = ReceivePort();
        final completedPort = ReceivePort();
        addTearDown(gatePort.close);
        addTearDown(completedPort.close);
        final SendPort gateSendPort = gatePort.sendPort;
        final SendPort completedSendPort = completedPort.sendPort;

        final ExtensionTestHarness harness = await ExtensionTestHarness.spawn(
          (SendPort sendPort) => ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
            _GatedShutdownService(completedSendPort: completedSendPort, gateSendPort: gateSendPort),
          ], extensionName: 'gated_shutdown_ext'),
        );

        final Future<void> firstDispose = harness.dispose();
        expect(harness.isDisposed, isTrue);

        final releaseSendPort = await gatePort.first as SendPort;
        var secondDisposeCompleted = false;
        final Future<void> secondDispose = harness.dispose().then((_) {
          secondDisposeCompleted = true;
        });

        await pumpEventQueue();
        expect(secondDisposeCompleted, isFalse);

        releaseSendPort.send(null);
        await Future.wait(<Future<void>>[firstDispose, secondDispose]);
        expect(secondDisposeCompleted, isTrue);
        expect(await completedPort.first, 'shutdown_complete');
      },
    );

    test('unwraps ToolExtensionException (-32001) on typed clients and sendRawRequest', () async {
      final ExtensionTestHarness harness = await ExtensionTestHarness.spawn(
        (SendPort sendPort) => ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
          _DomainErrorDiagnosticsService(),
        ], extensionName: 'domain_error_ext'),
      );
      addTearDown(harness.dispose);

      await expectLater(
        harness.diagnosticsClient.runDiagnostics(),
        throwsA(
          isA<ToolExtensionException>().having(
            (ToolExtensionException e) => e.message,
            'message',
            'Missing custom toolchain at /opt/custom',
          ),
        ),
      );

      await expectLater(
        harness.sendRawRequest(DiagnosticsExtension.runDiagnosticsMethod),
        throwsA(
          isA<ToolExtensionException>().having(
            (ToolExtensionException e) => e.message,
            'message',
            'Missing custom toolchain at /opt/custom',
          ),
        ),
      );
    });

    test('handles timestamp-free extension.log and surfaces malformed notifications as FormatExceptions', () async {
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

      final Future<ExtensionLogMessage> logWithoutTimestamp = harness.onLog.first;
      await harness.sendRawRequest('malformed.emitTimestampFreeLog');
      final ExtensionLogMessage receivedLog = await logWithoutTimestamp;
      expect(receivedLog.message, 'log without timestamp');
      expect(receivedLog.timestamp, isNull);

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

    test('records post-handshake unhandled isolate error in isolateErrors and onIsolateError without emitting on onLog', () async {
      final ExtensionTestHarness harness = await ExtensionTestHarness.spawn(
        (SendPort sendPort) => ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[_AsyncErrorService()],
          extensionName: 'error_extension',
          supportedPlatforms: const <String>{'linux'},
        ),
      );
      addTearDown(harness.dispose);

      final logEvents = <ExtensionLogMessage>[];
      final logErrors = <Object>[];
      final logDone = Completer<void>();
      final StreamSubscription<ExtensionLogMessage> logSub = harness.onLog.listen(
        logEvents.add,
        onError: logErrors.add,
        onDone: logDone.complete,
      );
      addTearDown(logSub.cancel);

      final Future<StateError> isolateErrorFuture = harness.onIsolateError.first;

      await expectLater(
        harness.sendRawRequest('error.triggerUnhandledError', timeout: null),
        throwsA(isA<StateError>()),
      );

      final StateError emittedIsolateError = await isolateErrorFuture;
      expect(emittedIsolateError.message, contains('Simulated post-handshake isolate crash'));
      expect(harness.isolateErrors, hasLength(1));
      expect(
        harness.isolateErrors.single.message,
        contains('Simulated post-handshake isolate crash'),
      );

      await logDone.future;
      expect(logErrors, isEmpty);
      expect(logEvents, isEmpty);
      expect(harness.isDisposed, isTrue);
    });
  });

  group('verifyExtensionPackage', () {
    Directory createTempPackage({
      String entrypointRelativePath = 'extension/flutter_tools/extension.dart',
      bool createEntrypoint = true,
    }) {
      final Directory root = Directory.systemTemp.createTempSync('verify_ext_pkg.');
      addTearDown(() {
        if (root.existsSync()) {
          root.deleteSync(recursive: true);
        }
      });
      if (createEntrypoint) {
        File.fromUri(root.uri.resolve(entrypointRelativePath))
          ..createSync(recursive: true)
          ..writeAsStringSync('// entrypoint stub\n');
      }
      return root;
    }

    Uri resolvePrototypePackageRoot() {
      final Uri? libraryUri = Isolate.resolvePackageUriSync(
        Uri.parse(
          'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart',
        ),
      );
      if (libraryUri == null) {
        throw StateError('Failed to resolve package:flutter_tools_extension_linux_prototype URI.');
      }
      return libraryUri.resolve('../');
    }

    Uri writeTempPackageConfig(Directory pkgDir, {required String packageName}) {
      final Uri? currentConfigUri = Isolate.packageConfigSync;
      if (currentConfigUri == null) {
        throw StateError('Expected Isolate.packageConfigSync to be non-null in test environment.');
      }
      final Object? rawDecoded = jsonDecode(File.fromUri(currentConfigUri).readAsStringSync());
      if (rawDecoded is! Map<String, Object?>) {
        throw StateError('Expected JSON object in package_config.json.');
      }
      final Object? rawPackages = rawDecoded['packages'];
      if (rawPackages is! List<Object?>) {
        throw StateError('Expected packages list in package_config.json.');
      }
      final rewrittenPackages = <Map<String, Object?>>[
        for (final Object? rawEntry in rawPackages)
          if (rawEntry case final Map<String, Object?> entry)
            if (entry['rootUri'] case final String rawRootUri)
              <String, Object?>{
                ...entry,
                'rootUri': () {
                  final Uri resolved = currentConfigUri.resolve(rawRootUri);
                  return resolved.path.endsWith('/') ? resolved.toString() : '$resolved/';
                }(),
              },
        <String, Object?>{
          'name': packageName,
          'rootUri': '../',
          'packageUri': 'lib/',
          'languageVersion': '3.8',
        },
      ];
      final Uri configUri = pkgDir.uri.resolve('.dart_tool/package_config.json');
      File.fromUri(configUri)
        ..createSync(recursive: true)
        ..writeAsStringSync(
          jsonEncode(<String, Object?>{
            'configVersion': rawDecoded['configVersion'] ?? 2,
            'packages': rewrittenPackages,
          }),
        );
      return configUri;
    }

    Future<void> validEntryPoint(SendPort sendPort) =>
        ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
          _TestDiagnosticsService(),
          _TestBuildService(),
          _TestTemplateService(appTemplates: const <String>{'custom_os/app.tmpl'}),
        ], extensionName: 'test_ext');

    test('succeeds for conventional extension/flutter_tools/extension.dart entrypoint', () async {
      final Directory pkgDir = createTempPackage();

      await verifyExtensionPackage(packageRoot: pkgDir.uri, entryPoint: validEntryPoint);
    });

    test('resolves package: template URIs via Isolate.resolvePackageUri when packageConfigUri is null and enforces packageRoot containment', () async {
      final Uri prototypeRoot = resolvePrototypePackageRoot();
      await verifyExtensionPackage(
        packageRoot: prototypeRoot,
        entrypointRelativePath: 'bin/flutter_tools_extension_linux_prototype.dart',
        entryPoint: (SendPort sendPort) =>
            ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
              _TestTemplateService(
                appTemplates: const <String>{'package:flutter_tools_extension_linux_prototype/src'},
              ),
            ], extensionName: 'flutter_tools_extension_linux_prototype'),
      );

      final Directory pkgDir = createTempPackage();
      await expectLater(
        verifyExtensionPackage(
          packageRoot: pkgDir.uri,
          entryPoint: (SendPort sendPort) =>
              ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
                _TestTemplateService(
                  appTemplates: const <String>{'package:flutter_tools_extension/src'},
                ),
              ], extensionName: 'test_ext'),
        ),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('resolves outside package root'),
          ),
        ),
      );
    });

    test('resolves package: template URIs through packageConfigUri on spawnUri and rejects external or symlink-escaped templates', () async {
      const tempPackageName = 'temp_spawned_ext';
      final Directory pkgDir = createTempPackage(createEntrypoint: false);
      Directory.fromUri(pkgDir.uri.resolve('lib/templates/app')).createSync(recursive: true);
      Directory.fromUri(pkgDir.uri.resolve('lib/templates/plugin')).createSync(recursive: true);
      final Uri configUri = writeTempPackageConfig(pkgDir, packageName: tempPackageName);

      void writeEntrypointScript({required String appTemplateUri}) {
        File.fromUri(pkgDir.uri.resolve('extension/flutter_tools/extension.dart'))
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'dart:isolate';
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

final class _SpawnedTemplateService extends TemplateService {
  @override
  Set<String> get appPlatformTemplates => const <String>{'$appTemplateUri'};

  @override
  Set<String> get pluginPlatformTemplates =>
      const <String>{'package:$tempPackageName/templates/plugin'};

  @override
  Set<ProjectTemplate> get projectTemplates => const <ProjectTemplate>{};
}

Future<void> main(List<String> args, SendPort sendPort) {
  return ToolExtensionEntryPoint.run(
    sendPort,
    <ToolExtensionService>[_SpawnedTemplateService()],
    extensionName: '$tempPackageName',
  );
}
''');
      }

      expect(
        await Isolate.resolvePackageUri(Uri.parse('package:$tempPackageName/templates/app')),
        isNull,
      );

      writeEntrypointScript(appTemplateUri: 'package:$tempPackageName/templates/app');
      await verifyExtensionPackage(packageRoot: pkgDir.uri, packageConfigUri: configUri);

      writeEntrypointScript(appTemplateUri: 'package:flutter_tools_extension/src');
      await expectLater(
        verifyExtensionPackage(packageRoot: pkgDir.uri, packageConfigUri: configUri),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('references package "flutter_tools_extension", expected "$tempPackageName"'),
          ),
        ),
      );

      final Directory outsideTemplateDir = Directory.systemTemp.createTempSync(
        'verify_ext_outside_tmpl.',
      );
      addTearDown(() {
        if (outsideTemplateDir.existsSync()) {
          outsideTemplateDir.deleteSync(recursive: true);
        }
      });
      Link.fromUri(pkgDir.uri.resolve('lib/templates/escaped_link'))
          .createSync(outsideTemplateDir.path, recursive: true);
      writeEntrypointScript(appTemplateUri: 'package:$tempPackageName/templates/escaped_link');
      await expectLater(
        verifyExtensionPackage(packageRoot: pkgDir.uri, packageConfigUri: configUri),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('resolves outside package root'),
          ),
        ),
      );
    });

    test('throws StateError when entrypoint file is missing', () async {
      final Directory pkgDir = createTempPackage(createEntrypoint: false);

      await expectLater(
        verifyExtensionPackage(packageRoot: pkgDir.uri, entryPoint: validEntryPoint),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('Extension entrypoint not found'),
          ),
        ),
      );
    });

    test('throws StateError when entrypoint symlink escapes packageRoot', () async {
      final Directory pkgDir = createTempPackage(createEntrypoint: false);
      final Directory outsideDir = Directory.systemTemp.createTempSync('verify_ext_outside.');
      addTearDown(() {
        if (outsideDir.existsSync()) {
          outsideDir.deleteSync(recursive: true);
        }
      });
      final outsideFile = File.fromUri(outsideDir.uri.resolve('outside_extension.dart'))
        ..writeAsStringSync('// outside entrypoint\n');
      final entrypointLink = Link.fromUri(
        pkgDir.uri.resolve('extension/flutter_tools/extension.dart'),
      )..createSync(outsideFile.path, recursive: true);
      expect(entrypointLink.existsSync(), isTrue);

      await expectLater(
        verifyExtensionPackage(packageRoot: pkgDir.uri, entryPoint: validEntryPoint),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('resolves outside package root'),
          ),
        ),
      );
    });

    test('skips service RPCs cleanly when supportedPlatforms excludes host OS', () async {
      final Directory pkgDir = createTempPackage();
      final excludedPlatform = Platform.isLinux ? 'macos' : 'linux';

      await verifyExtensionPackage(
        packageRoot: pkgDir.uri,
        entryPoint: (SendPort sendPort) => ToolExtensionEntryPoint.run(
          sendPort,
          <ToolExtensionService>[_ThrowingBuildService()],
          extensionName: 'excluded_platform_ext',
          supportedPlatforms: <String>{excludedPlatform},
        ),
      );
    });

    test('throws StateError when package: template URI points to nonexistent directory', () async {
      final Directory pkgDir = createTempPackage();

      await expectLater(
        verifyExtensionPackage(
          packageRoot: pkgDir.uri,
          entryPoint: (SendPort sendPort) =>
              ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
                _TestTemplateService(
                  appTemplates: const <String>{
                    'package:flutter_tools_extension/nonexistent_template_dir',
                  },
                ),
              ], extensionName: 'bad_template_ext'),
        ),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains(
              'Template directory "package:flutter_tools_extension/nonexistent_template_dir" does not exist',
            ),
          ),
        ),
      );
    });

    test('throws StateError when build or assemble target names are duplicated', () async {
      final Directory pkgDir = createTempPackage();

      await expectLater(
        verifyExtensionPackage(
          packageRoot: pkgDir.uri,
          entryPoint: (SendPort sendPort) =>
              ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
                _TestBuildService(
                  targets: const <BuildTarget>[
                    _TestBuildTarget('dup-target'),
                    _TestBuildTarget('dup-target'),
                  ],
                ),
              ], extensionName: 'test_ext'),
        ),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('Duplicate build target name "dup-target"'),
          ),
        ),
      );

      await expectLater(
        verifyExtensionPackage(
          packageRoot: pkgDir.uri,
          entryPoint: (SendPort sendPort) =>
              ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
                _TestBuildService(
                  assembleTargetList: const <AssembleTarget>[
                    _TestAssembleTarget('dup_assemble'),
                    _TestAssembleTarget('dup_assemble'),
                  ],
                ),
              ], extensionName: 'test_ext'),
        ),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('Duplicate assemble target name "dup_assemble"'),
          ),
        ),
      );
    });

    test(
      'throws FormatException on unknown service namespace and StateError on empty platforms',
      () async {
        final Directory pkgDir = createTempPackage();

        await expectLater(
          verifyExtensionPackage(
            packageRoot: pkgDir.uri,
            entryPoint: (SendPort sendPort) => ToolExtensionEntryPoint.run(
              sendPort,
              <ToolExtensionService>[_UnknownNamespaceService()],
              extensionName: 'unknown_service_ext',
            ),
          ),
          throwsA(
            isA<FormatException>().having(
              (FormatException e) => e.message,
              'message',
              contains('Extension reported unknown service "unknown_namespace"'),
            ),
          ),
        );

        await expectLater(
          verifyExtensionPackage(
            packageRoot: pkgDir.uri,
            entryPoint: (SendPort sendPort) => ToolExtensionEntryPoint.run(
              sendPort,
              <ToolExtensionService>[_TestDiagnosticsService()],
              extensionName: 'empty_platforms_ext',
              supportedPlatforms: const <String>{},
            ),
          ),
          throwsA(
            isA<StateError>().having(
              (StateError e) => e.message,
              'message',
              contains('Runtime supportedPlatforms must not be empty'),
            ),
          ),
        );
      },
    );
  });
}
