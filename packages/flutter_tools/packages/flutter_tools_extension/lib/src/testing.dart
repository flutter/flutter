// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:meta/meta.dart';
import 'package:stream_channel/isolate_channel.dart';

import 'build.dart';
import 'clean.dart';
import 'config.dart';
import 'dependencies.dart';
import 'device.dart';
import 'diagnostics.dart';
import 'protocol_base/provider.dart';
import 'protocol_base/service.dart';
import 'templates.dart';

/// Typedef for an extension isolate entrypoint function accepted by
/// [ExtensionTestHarness.spawn] and [verifyExtensionPackage].
typedef ExtensionEntryPoint = FutureOr<void> Function(SendPort sendPort);

/// Re-exported JSON-RPC 2.0 exception type thrown when an extension RPC fails.
typedef RpcException = json_rpc.RpcException;

/// Structured log message emitted by an extension over the `'extension.log'`
/// JSON-RPC notification channel.
@immutable
final class ExtensionLogMessage {
  const ExtensionLogMessage({required this.message, this.level = .info, this.timestamp});

  /// Deserializes an [ExtensionLogMessage] from a JSON notification payload.
  factory ExtensionLogMessage.fromJson(Map<String, Object?> json) {
    final String? rawLevel = json.nullableField<String>(ToolExtensionService.levelKey);
    final ExtensionLogLevel level = rawLevel != null ? ExtensionLogLevel.fromName(rawLevel) : .info;
    final String? rawTimestamp = json.nullableField<String>(ToolExtensionService.timestampKey);
    DateTime? parsedTimestamp;
    if (rawTimestamp != null) {
      parsedTimestamp = DateTime.tryParse(rawTimestamp);
      if (parsedTimestamp == null) {
        throw FormatException(
          'Invalid "${ToolExtensionService.timestampKey}" ISO-8601 timestamp: "$rawTimestamp".',
        );
      }
    }
    return ExtensionLogMessage(
      level: level,
      message: json.requiredField<String>(ToolExtensionService.messageKey),
      timestamp: parsedTimestamp,
    );
  }

  /// Severity level of the log message.
  final ExtensionLogLevel level;

  /// Human-readable log message content.
  final String message;

  /// Optional timestamp when the log entry was emitted.
  final DateTime? timestamp;

  /// Serializes this log message to a JSON-compatible map.
  Map<String, Object?> toJson() => <String, Object?>{
    ToolExtensionService.levelKey: level.name,
    ToolExtensionService.messageKey: message,
    ToolExtensionService.timestampKey: ?timestamp?.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionLogMessage &&
            other.level == level &&
            other.message == message &&
            other.timestamp == timestamp);
  }

  @override
  int get hashCode => Object.hash(level, message, timestamp);

  @override
  String toString() =>
      'ExtensionLogMessage(level: ${level.name}, message: $message, timestamp: $timestamp)';
}

/// Sealed base class for liveness and progress notifications emitted by a
/// tool extension during a long-running request.
@immutable
sealed class ExtensionProgressEvent {
  const ExtensionProgressEvent({required this.requestId});

  /// Identifier of the in-flight request associated with this notification.
  final Object requestId;
}

/// A structured `'extension.progress'` notification emitted by a tool
/// extension via [ToolExtensionService.reportProgress].
@immutable
final class ExtensionProgressNotification extends ExtensionProgressEvent {
  const ExtensionProgressNotification({required super.requestId, this.message, this.progress});

  /// Deserializes an [ExtensionProgressNotification] from a JSON map payload.
  factory ExtensionProgressNotification.fromJson(Map<String, Object?> json) {
    final Object? rawProgress = json[ToolExtensionService.progressKey];
    final double? progress = switch (rawProgress) {
      null => null,
      final num value => value.toDouble(),
      _ => throw FormatException(
        'Field "${ToolExtensionService.progressKey}" must be a number, '
        'got ${rawProgress.runtimeType}.',
      ),
    };
    return ExtensionProgressNotification(
      requestId: json.requiredField<Object>(ToolExtensionService.requestIdKey),
      message: json.nullableField<String>(ToolExtensionService.messageKey),
      progress: progress,
    );
  }

  /// Optional human-readable progress status message.
  final String? message;

  /// Optional fractional progress value between `0.0` and `1.0`.
  final double? progress;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionProgressNotification &&
            other.requestId == requestId &&
            other.message == message &&
            other.progress == progress);
  }

  @override
  int get hashCode => Object.hash(requestId, message, progress);

  @override
  String toString() =>
      'ExtensionProgressNotification(requestId: $requestId, message: $message, progress: $progress)';
}

/// A structured `'extension.heartbeat'` notification emitted by a tool
/// extension via [ToolExtensionService.sendHeartbeat].
@immutable
final class ExtensionHeartbeatNotification extends ExtensionProgressEvent {
  const ExtensionHeartbeatNotification({required super.requestId});

  /// Deserializes an [ExtensionHeartbeatNotification] from a JSON map payload.
  factory ExtensionHeartbeatNotification.fromJson(Map<String, Object?> json) {
    return ExtensionHeartbeatNotification(
      requestId: json.requiredField<Object>(ToolExtensionService.requestIdKey),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionHeartbeatNotification && other.requestId == requestId);
  }

  @override
  int get hashCode => Object.hash(ExtensionHeartbeatNotification, requestId);

  @override
  String toString() => 'ExtensionHeartbeatNotification(requestId: $requestId)';
}

/// Typed JSON-RPC client for invoking [DiagnosticsExtension] methods on an
/// [ExtensionTestHarness].
final class ExtensionDiagnosticsClient {
  ExtensionDiagnosticsClient._(this._harness);

  final ExtensionTestHarness _harness;

  /// Queries `diagnostics.getTitle` over JSON-RPC.
  Future<String> getTitle() async {
    final Object? response = await _harness.sendRawRequest(DiagnosticsExtension.getTitleMethod);
    if (response case final String value) {
      return value;
    }
    throw StateError(
      'Expected String from ${DiagnosticsExtension.getTitleMethod}, got ${response.runtimeType}.',
    );
  }

  /// Queries `diagnostics.runDiagnostics` over JSON-RPC.
  Future<List<ValidationResult>> runDiagnostics() async {
    final Object? response = await _harness.sendRawRequest(
      DiagnosticsExtension.runDiagnosticsMethod,
    );
    if (response case final List<Object?> list) {
      return <ValidationResult>[
        for (final Object? item in list)
          if (item case final Map<String, Object?> map)
            ValidationResult.fromJson(map)
          else
            throw FormatException(
              'Invalid element from ${DiagnosticsExtension.runDiagnosticsMethod}: '
              'expected Map<String, Object?>, got ${item.runtimeType}.',
            ),
      ];
    }
    throw StateError(
      'Expected List<Object?> from ${DiagnosticsExtension.runDiagnosticsMethod}, '
      'got ${response.runtimeType}.',
    );
  }
}

/// Typed JSON-RPC client for invoking [ConfigurationExtension] methods on an
/// [ExtensionTestHarness].
final class ExtensionConfigurationClient {
  ExtensionConfigurationClient._(this._harness);

  final ExtensionTestHarness _harness;

  /// Queries `config.getTitle` over JSON-RPC.
  Future<String> getTitle() async {
    final Object? response = await _harness.sendRawRequest(ConfigurationExtension.getTitleMethod);
    if (response case final String value) {
      return value;
    }
    throw StateError(
      'Expected String from ${ConfigurationExtension.getTitleMethod}, got ${response.runtimeType}.',
    );
  }

  /// Queries `config.getFeatureFlags` over JSON-RPC.
  Future<List<FeatureFlag>> getFeatureFlags() async {
    final Object? response = await _harness.sendRawRequest(
      ConfigurationExtension.getFeatureFlagsMethod,
    );
    if (response case final List<Object?> list) {
      return <FeatureFlag>[
        for (final Object? item in list)
          if (item case final Map<String, Object?> map)
            FeatureFlag.fromJson(map)
          else
            throw FormatException(
              'Invalid element from ${ConfigurationExtension.getFeatureFlagsMethod}: '
              'expected Map<String, Object?>, got ${item.runtimeType}.',
            ),
      ];
    }
    throw StateError(
      'Expected List<Object?> from ${ConfigurationExtension.getFeatureFlagsMethod}, '
      'got ${response.runtimeType}.',
    );
  }

  /// Queries `config.getConfigurations` over JSON-RPC.
  Future<List<ConfigOption>> getConfigurations() async {
    final Object? response = await _harness.sendRawRequest(
      ConfigurationExtension.getConfigurationsMethod,
    );
    if (response case final List<Object?> list) {
      return <ConfigOption>[
        for (final Object? item in list)
          if (item case final Map<String, Object?> map)
            ConfigOption.fromJson(map)
          else
            throw FormatException(
              'Invalid element from ${ConfigurationExtension.getConfigurationsMethod}: '
              'expected Map<String, Object?>, got ${item.runtimeType}.',
            ),
      ];
    }
    throw StateError(
      'Expected List<Object?> from ${ConfigurationExtension.getConfigurationsMethod}, '
      'got ${response.runtimeType}.',
    );
  }
}

/// Typed JSON-RPC client for invoking [TemplateService] methods on an
/// [ExtensionTestHarness].
final class ExtensionTemplateClient {
  ExtensionTemplateClient._(this._harness);

  static const String _templateNameParam = 'templateName';
  static const String _toolParametersParam = 'toolParameters';

  final ExtensionTestHarness _harness;

  /// Queries `template.getAppTemplates` over JSON-RPC.
  Future<Set<String>> getAppTemplates() async {
    final Object? response = await _harness.sendRawRequest(TemplateService.getAppTemplatesMethod);
    return _stringSetFromRpc(response, TemplateService.getAppTemplatesMethod);
  }

  /// Queries `template.getPluginTemplates` over JSON-RPC.
  Future<Set<String>> getPluginTemplates() async {
    final Object? response = await _harness.sendRawRequest(
      TemplateService.getPluginTemplatesMethod,
    );
    return _stringSetFromRpc(response, TemplateService.getPluginTemplatesMethod);
  }

  /// Queries `template.getProjectTemplates` over JSON-RPC.
  Future<List<ExtensionProjectTemplate>> getProjectTemplates() async {
    final Object? response = await _harness.sendRawRequest(
      TemplateService.getProjectTemplatesMethod,
    );
    return ExtensionProjectTemplate.listFromJson(response);
  }

  /// Queries `template.generateTemplateParameters` over JSON-RPC.
  Future<Map<String, Object?>> generateTemplateParameters(
    String templateName,
    Map<String, Object?> toolParameters,
  ) async {
    final Object? response = await _harness.sendRawRequest(
      TemplateService.generateTemplateParametersMethod,
      params: <String, Object?>{
        _templateNameParam: templateName,
        _toolParametersParam: toolParameters,
      },
    );
    if (response case final Map<String, Object?> map) {
      return map;
    }
    throw StateError(
      'Expected Map<String, Object?> from ${TemplateService.generateTemplateParametersMethod}, '
      'got ${response.runtimeType}.',
    );
  }

  static Set<String> _stringSetFromRpc(Object? response, String method) {
    if (response case final Iterable<Object?> items) {
      return Set<String>.unmodifiable(<String>[
        for (final Object? item in items)
          switch (item) {
            final String value => value,
            _ => throw FormatException(
              'Invalid element from $method: expected String, got ${item.runtimeType}.',
            ),
          },
      ]);
    }
    throw StateError('Expected List<Object?> from $method, got ${response.runtimeType}.');
  }
}

/// Typed JSON-RPC client for invoking [DeviceService] methods on an
/// [ExtensionTestHarness].
final class ExtensionDeviceClient {
  ExtensionDeviceClient._(this._harness);

  final ExtensionTestHarness _harness;

  /// Queries `device.getDevices` over JSON-RPC.
  Future<List<TargetDevice>> getDevices() async {
    final Object? response = await _harness.sendRawRequest(DeviceService.getDevicesMethod);
    return TargetDevice.listFromJson(response);
  }

  /// Queries `device.isSupportedForProject` over JSON-RPC.
  Future<bool> isSupportedForProject({
    required String deviceId,
    required ExtensionFlutterProject project,
  }) async {
    final Object? response = await _harness.sendRawRequest(
      DeviceService.isSupportedForProjectMethod,
      params: <String, Object?>{
        DeviceService.deviceIdParam: deviceId,
        DeviceService.projectParam: project.toMap(),
      },
    );
    if (response case final bool supported) {
      return supported;
    }
    throw StateError(
      'Expected bool from ${DeviceService.isSupportedForProjectMethod}, '
      'got ${response.runtimeType}.',
    );
  }
}

/// Typed JSON-RPC client for invoking [BuildService] methods on an
/// [ExtensionTestHarness].
final class ExtensionBuildClient {
  ExtensionBuildClient._(this._harness);

  final ExtensionTestHarness _harness;

  /// Queries `build.getBuildTargets` over JSON-RPC.
  Future<List<ExtensionBuildTarget>> getBuildTargets() async {
    final Object? response = await _harness.sendRawRequest(BuildService.getBuildTargetsMethod);
    return ExtensionBuildTarget.listFromJson(response);
  }

  /// Queries `build.build` over JSON-RPC.
  Future<ExtensionBuildResult> build({
    required BuildMode buildMode,
    required String mainPath,
    required Uri projectRoot,
    required String targetName,
  }) async {
    final Object? response = await _harness.sendRawRequest(
      BuildService.buildMethod,
      params: <String, Object?>{
        BuildService.buildModeParam: buildMode.cliName,
        BuildService.mainPathParam: mainPath,
        BuildService.projectRootParam: projectRoot.toString(),
        BuildService.targetNameParam: targetName,
      },
    );
    if (response case final Map<String, Object?> map) {
      return ExtensionBuildResult.fromJson(map);
    }
    throw StateError(
      'Expected Map<String, Object?> from ${BuildService.buildMethod}, '
      'got ${response.runtimeType}.',
    );
  }
}

/// Typed JSON-RPC client for invoking [CleanService] methods on an
/// [ExtensionTestHarness].
final class ExtensionCleanClient {
  ExtensionCleanClient._(this._harness);

  final ExtensionTestHarness _harness;

  /// Queries `clean.clean` over JSON-RPC.
  Future<void> clean(CleanEnvironment environment) async {
    await _harness.sendRawRequest(
      CleanService.cleanMethod,
      params: <String, Object?>{CleanService.environmentParam: environment.toMap()},
    );
  }
}

/// In-process Isolate and JSON-RPC 2.0 test harness for Flutter tool extensions.
///
/// Spawns an extension isolate via [spawn] or [spawnUri], completes the
/// `extension.getCapabilities` handshake, and exposes typed protocol clients
/// ([diagnosticsClient], [configClient], [templateClient], [deviceClient],
/// [buildClient], [cleanClient]) along with notification streams ([onLog],
/// [progressNotifications]) and raw JSON-RPC helpers ([sendRawRequest],
/// [sendNotification], [cancelRequest]).
final class ExtensionTestHarness {
  ExtensionTestHarness._({
    required this.capabilities,
    required this._defaultTimeout,
    required this._errorPort,
    required this._exitPort,
    required Isolate this._isolate,
    required this._logController,
    required this._logs,
    required this._peer,
    required this._progressController,
    required this._receivePort,
  });

  /// Capabilities reported by the extension isolate during handshake.
  final ToolExtensionCapabilities capabilities;

  final Duration _defaultTimeout;
  final RawReceivePort _errorPort;
  final RawReceivePort _exitPort;
  Isolate? _isolate;
  final StreamController<ExtensionLogMessage> _logController;
  final List<ExtensionLogMessage> _logs;
  final json_rpc.Peer _peer;
  final StreamController<ExtensionProgressEvent> _progressController;
  final ReceivePort _receivePort;

  /// Typed client for invoking `diagnostics.*` RPCs on the extension.
  late final diagnosticsClient = ExtensionDiagnosticsClient._(this);

  /// Typed client for invoking `config.*` RPCs on the extension.
  late final configClient = ExtensionConfigurationClient._(this);

  /// Typed client for invoking `template.*` RPCs on the extension.
  late final templateClient = ExtensionTemplateClient._(this);

  /// Typed client for invoking `device.*` RPCs on the extension.
  late final deviceClient = ExtensionDeviceClient._(this);

  /// Typed client for invoking `build.*` RPCs on the extension.
  late final buildClient = ExtensionBuildClient._(this);

  /// Typed client for invoking `clean.*` RPCs on the extension.
  late final cleanClient = ExtensionCleanClient._(this);

  bool _isDisposed = false;

  /// Whether this harness has been disposed.
  bool get isDisposed => _isDisposed;

  /// Unmodifiable snapshot of all `'extension.log'` messages received so far.
  List<ExtensionLogMessage> get logs => List<ExtensionLogMessage>.unmodifiable(_logs);

  /// Broadcast stream of `'extension.log'` messages emitted by the extension.
  Stream<ExtensionLogMessage> get onLog => _logController.stream;

  /// Broadcast stream of `'extension.progress'` and `'extension.heartbeat'`
  /// notifications emitted by the extension.
  Stream<ExtensionProgressEvent> get progressNotifications => _progressController.stream;

  /// Spawns an extension isolate running [entryPoint] and completes the
  /// `extension.getCapabilities` handshake.
  static Future<ExtensionTestHarness> spawn(
    ExtensionEntryPoint entryPoint, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    return _spawnWith(
      (SendPort sendPort, SendPort onError, SendPort onExit) =>
          Isolate.spawn(entryPoint, sendPort, onError: onError, onExit: onExit),
      timeout: timeout,
    );
  }

  /// Spawns an extension isolate from [entrypointUri] via [Isolate.spawnUri]
  /// and completes the `extension.getCapabilities` handshake.
  static Future<ExtensionTestHarness> spawnUri(
    Uri entrypointUri, {
    List<String> args = const <String>[],
    Uri? packageConfigUri,
    Duration timeout = const Duration(seconds: 5),
  }) {
    return _spawnWith((SendPort sendPort, SendPort onError, SendPort onExit) async {
      final Uri? resolvedPackageConfig = packageConfigUri ?? await Isolate.packageConfig;
      return Isolate.spawnUri(
        entrypointUri,
        args,
        sendPort,
        packageConfig: resolvedPackageConfig,
        automaticPackageResolution: resolvedPackageConfig == null,
        onError: onError,
        onExit: onExit,
      );
    }, timeout: timeout);
  }

  static Future<ExtensionTestHarness> _spawnWith(
    Future<Isolate> Function(SendPort sendPort, SendPort onError, SendPort onExit) isolateSpawner, {
    required Duration timeout,
  }) async {
    final receivePort = ReceivePort();
    final errorPort = RawReceivePort();
    final exitPort = RawReceivePort();
    final errorCompleter = Completer<Never>();
    final logs = <ExtensionLogMessage>[];
    final logController = StreamController<ExtensionLogMessage>.broadcast();
    final progressController = StreamController<ExtensionProgressEvent>.broadcast();

    Isolate? isolate;
    var handshakeCompleted = false;

    void handleIsolateTermination(StateError error) {
      if (!handshakeCompleted) {
        if (!errorCompleter.isCompleted) {
          errorCompleter.completeError(error);
        }
      } else {
        receivePort.close();
      }
    }

    errorPort.handler = (Object? error) {
      final detail = error is List && error.isNotEmpty ? '${error[0]}' : '$error';
      handleIsolateTermination(StateError('Extension isolate error: $detail'));
    };

    exitPort.handler = (Object? _) {
      handleIsolateTermination(
        StateError('Extension isolate exited unexpectedly before handshake completed.'),
      );
    };

    try {
      isolate = await isolateSpawner(
        receivePort.sendPort,
        errorPort.sendPort,
        exitPort.sendPort,
      ).timeout(timeout);

      final channel = IsolateChannel<Object?>.connectReceive(receivePort);
      final peer = json_rpc.Peer.withoutJson(channel);

      peer
        ..registerMethod(ToolExtensionService.logNotificationMethod, (json_rpc.Parameters params) {
          if (params.value case final Map<String, Object?> rawMap) {
            final logMessage = ExtensionLogMessage.fromJson(rawMap);
            logs.add(logMessage);
            if (!logController.isClosed) {
              logController.add(logMessage);
            }
          }
        })
        ..registerMethod(ToolExtensionService.progressNotificationMethod, (
          json_rpc.Parameters params,
        ) {
          if (params.value case final Map<String, Object?> rawMap) {
            final notification = ExtensionProgressNotification.fromJson(rawMap);
            if (!progressController.isClosed) {
              progressController.add(notification);
            }
          }
        })
        ..registerMethod(ToolExtensionService.heartbeatNotificationMethod, (
          json_rpc.Parameters params,
        ) {
          if (params.value case final Map<String, Object?> rawMap) {
            final notification = ExtensionHeartbeatNotification.fromJson(rawMap);
            if (!progressController.isClosed) {
              progressController.add(notification);
            }
          }
        });

      unawaited(peer.listen());

      final Object? responseObj = await Future.any<Object?>(<Future<Object?>>[
        peer.sendRequest(ToolExtensionEntryPoint.getCapabilitiesMethod),
        errorCompleter.future,
      ]).timeout(timeout);
      handshakeCompleted = true;

      if (responseObj is! Map<String, Object?>) {
        throw StateError(
          'Extension handshake failed: extension.getCapabilities did not return a Map.',
        );
      }

      final capabilities = ToolExtensionCapabilities.fromJson(responseObj);
      return ExtensionTestHarness._(
        capabilities: capabilities,
        defaultTimeout: timeout,
        errorPort: errorPort,
        exitPort: exitPort,
        isolate: isolate,
        logController: logController,
        logs: logs,
        peer: peer,
        progressController: progressController,
        receivePort: receivePort,
      );
    } on TimeoutException {
      await _cleanupFailedSpawn(
        errorPort: errorPort,
        exitPort: exitPort,
        isolate: isolate,
        logController: logController,
        progressController: progressController,
        receivePort: receivePort,
      );
      throw TimeoutException('Handshake with tool extension isolate timed out.');
    } on Object {
      await _cleanupFailedSpawn(
        errorPort: errorPort,
        exitPort: exitPort,
        isolate: isolate,
        logController: logController,
        progressController: progressController,
        receivePort: receivePort,
      );
      rethrow;
    }
  }

  static Future<void> _cleanupFailedSpawn({
    required RawReceivePort errorPort,
    required RawReceivePort exitPort,
    required Isolate? isolate,
    required StreamController<ExtensionLogMessage> logController,
    required StreamController<ExtensionProgressEvent> progressController,
    required ReceivePort receivePort,
  }) async {
    errorPort.close();
    exitPort.close();
    receivePort.close();
    isolate?.kill(priority: Isolate.immediate);
    await logController.close();
    await progressController.close();
  }

  /// Sends a raw JSON-RPC 2.0 request to the extension isolate.
  Future<Object?> sendRawRequest(
    String method, {
    Map<String, Object?>? params,
    Duration? timeout,
  }) async {
    if (_isDisposed) {
      throw StateError('ExtensionTestHarness has been disposed.');
    }
    final Future<Object?> request = _peer.sendRequest(method, params);
    return request.timeout(timeout ?? _defaultTimeout);
  }

  /// Sends a fire-and-forget JSON-RPC 2.0 notification to the extension isolate.
  void sendNotification(String method, {Map<String, Object?>? params}) {
    if (_isDisposed) {
      throw StateError('ExtensionTestHarness has been disposed.');
    }
    _peer.sendNotification(method, params);
  }

  /// Sends an `'extension.cancelRequest'` notification for [requestId].
  void cancelRequest(Object requestId) {
    sendNotification(
      ToolExtensionService.cancelRequestNotificationMethod,
      params: <String, Object?>{ToolExtensionService.requestIdKey: requestId},
    );
  }

  /// Disposes the JSON-RPC peer, kills the extension isolate, and closes all
  /// open receive ports and notification streams.
  ///
  /// Idempotent: calling [dispose] multiple times is a no-op.
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    try {
      await _peer.close();
    } on Object {
      // Ignore peer closure errors during teardown.
    } finally {
      _errorPort.close();
      _exitPort.close();
      _receivePort.close();
      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;
      await _logController.close();
      await _progressController.close();
    }
  }
}

/// Validates an extension package's `extension/flutter_tools/config.yaml`
/// manifest against the runtime capabilities, build targets, and templates
/// reported by its extension isolate.
///
/// If [entryPoint] is provided, the extension isolate is spawned in-process via
/// [ExtensionTestHarness.spawn]; otherwise, the manifest's `entrypoint` script
/// under [packageRoot] is spawned via [ExtensionTestHarness.spawnUri].
///
/// Throws a [FormatException] or [StateError] if the manifest is missing,
/// invalid, or out of sync with the extension's runtime RPC responses.
Future<void> verifyExtensionPackage({
  required Uri packageRoot,
  ExtensionEntryPoint? entryPoint,
  ExtensionFileSystem fileSystem = const LocalExtensionFileSystem(),
  Uri? packageConfigUri,
  Duration timeout = const Duration(seconds: 5),
}) async {
  final Uri rootUri = packageRoot.path.endsWith('/')
      ? packageRoot
      : packageRoot.replace(path: '${packageRoot.path}/');

  final ExtensionFile manifestFile = fileSystem.file(
    rootUri.resolve(ExtensionPackageConfig.manifestRelativePath),
  );
  if (!manifestFile.existsSync()) {
    throw StateError(
      'Extension manifest not found at ${manifestFile.path} '
      '(expected ${ExtensionPackageConfig.manifestRelativePath}).',
    );
  }

  final Map<String, Object?> manifestMap = _parseSimpleYamlMap(manifestFile.readAsStringSync());
  final manifest = ExtensionPackageConfig.fromJson(manifestMap);

  for (final String service in manifest.services) {
    if (ExtensionService.tryFromNamespace(service) == null) {
      final String validNames = ExtensionService.values
          .map((ExtensionService s) => s.name)
          .join(', ');
      throw FormatException(
        'Unknown service "$service" in config.yaml "${ExtensionPackageConfig.servicesKey}". '
        'Valid services are: $validNames.',
      );
    }
  }

  if (manifest.protocolVersion != ToolExtensionCapabilities.currentProtocolVersion) {
    throw StateError(
      'Unsupported ${ExtensionPackageConfig.protocolVersionKey} ${manifest.protocolVersion} in config.yaml; '
      'expected ${ToolExtensionCapabilities.currentProtocolVersion}.',
    );
  }

  final Uri entrypointUri = rootUri.resolve(manifest.entrypoint);
  final ExtensionFile entrypointFile = fileSystem.file(entrypointUri);
  if (!entrypointFile.existsSync()) {
    throw StateError(
      'Declared extension entrypoint "${manifest.entrypoint}" does not exist '
      'at ${entrypointFile.path}.',
    );
  }

  final ExtensionTestHarness harness = entryPoint != null
      ? await ExtensionTestHarness.spawn(entryPoint, timeout: timeout)
      : await ExtensionTestHarness.spawnUri(
          entrypointUri,
          packageConfigUri: packageConfigUri,
          timeout: timeout,
        );

  try {
    if (harness.capabilities.extensionName != manifest.name) {
      throw StateError(
        'Extension name mismatch: config.yaml declares "${manifest.name}", '
        'but runtime capabilities reported "${harness.capabilities.extensionName}".',
      );
    }

    if (harness.capabilities.protocolVersion != manifest.protocolVersion) {
      throw StateError(
        'Protocol version mismatch: config.yaml declares ${manifest.protocolVersion}, '
        'but runtime capabilities reported ${harness.capabilities.protocolVersion}.',
      );
    }

    final Set<String> runtimeServices = harness.capabilities.services.toSet();
    if (!_setsEqual(runtimeServices, manifest.services)) {
      throw StateError(
        'Services mismatch: config.yaml declares ${manifest.services}, '
        'but runtime capabilities reported $runtimeServices.',
      );
    }

    final Set<String> runtimePlatforms = harness.capabilities.supportedPlatforms.toSet();
    if (!_setsEqual(runtimePlatforms, manifest.supportedPlatforms)) {
      throw StateError(
        'Supported platforms mismatch: config.yaml declares ${manifest.supportedPlatforms}, '
        'but runtime capabilities reported $runtimePlatforms.',
      );
    }

    if (manifest.services.contains(ExtensionService.build.name) &&
        manifest.buildTargets.isNotEmpty) {
      final List<ExtensionBuildTarget> targets = await harness.buildClient.getBuildTargets();
      final Set<String> runtimeTargetNames = targets
          .map((ExtensionBuildTarget t) => t.name)
          .toSet();
      if (!_setsEqual(runtimeTargetNames, manifest.buildTargets)) {
        throw StateError(
          'Build targets mismatch: config.yaml declares ${manifest.buildTargets}, '
          'but runtime build.getBuildTargets reported $runtimeTargetNames.',
        );
      }
    }

    if (manifest.services.contains(ExtensionService.template.name) &&
        manifest.templates.isNotEmpty) {
      final List<ExtensionProjectTemplate> templates = await harness.templateClient
          .getProjectTemplates();
      final Set<String> runtimeTemplateNames = templates
          .map((ExtensionProjectTemplate t) => t.name)
          .toSet();
      if (!_setsEqual(runtimeTemplateNames, manifest.templates)) {
        throw StateError(
          'Templates mismatch: config.yaml declares ${manifest.templates}, '
          'but runtime template.getProjectTemplates reported $runtimeTemplateNames.',
        );
      }
    }
  } finally {
    await harness.dispose();
  }
}

bool _setsEqual(Set<String> a, Set<String> b) => a.length == b.length && a.containsAll(b);

Map<String, Object?> _parseSimpleYamlMap(String content) {
  final result = <String, Object?>{};
  final List<String> lines = content.split('\n');
  String? activeListKey;
  List<String>? activeList;

  for (var i = 0; i < lines.length; i++) {
    final String stripped = _stripComment(lines[i]).trim();
    if (stripped.isEmpty) {
      continue;
    }

    if (stripped.startsWith('-')) {
      if (activeListKey == null || activeList == null) {
        throw FormatException('Unexpected YAML list item on line ${i + 1}: "${lines[i]}".');
      }
      final String itemValue = _unquote(stripped.substring(1).trim());
      if (itemValue.isEmpty) {
        throw FormatException('Empty YAML list item under "$activeListKey" on line ${i + 1}.');
      }
      activeList.add(itemValue);
      continue;
    }

    activeListKey = null;
    activeList = null;

    final int colonIndex = stripped.indexOf(':');
    if (colonIndex <= 0) {
      throw FormatException('Expected "key: value" entry on line ${i + 1}: "${lines[i]}".');
    }

    final String key = stripped.substring(0, colonIndex).trim();
    final String rawValue = stripped.substring(colonIndex + 1).trim();

    if (rawValue.isEmpty) {
      final list = <String>[];
      result[key] = list;
      activeListKey = key;
      activeList = list;
      continue;
    }

    if (rawValue.startsWith('[') && rawValue.endsWith(']')) {
      final String inner = rawValue.substring(1, rawValue.length - 1).trim();
      result[key] = inner.isEmpty ? <String>[] : _splitFlowList(inner);
      continue;
    }

    if (rawValue.startsWith('|') || rawValue.startsWith('>') || rawValue.startsWith('{')) {
      throw FormatException('Unsupported YAML syntax for "$key" on line ${i + 1}: "${lines[i]}".');
    }

    final String unquoted = _unquote(rawValue);
    final int? intValue = int.tryParse(unquoted);
    result[key] = (intValue != null && rawValue == unquoted) ? intValue : unquoted;
  }

  return result;
}

List<String> _splitFlowList(String inner) {
  final items = <String>[];
  final buffer = StringBuffer();
  var inSingleQuote = false;
  var inDoubleQuote = false;

  for (var i = 0; i < inner.length; i++) {
    final String char = inner[i];
    if (char == "'" && !inDoubleQuote) {
      inSingleQuote = !inSingleQuote;
      buffer.write(char);
    } else if (char == '"' && !inSingleQuote) {
      inDoubleQuote = !inDoubleQuote;
      buffer.write(char);
    } else if (char == ',' && !inSingleQuote && !inDoubleQuote) {
      items.add(_unquote(buffer.toString().trim()));
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }
  final String trailing = buffer.toString().trim();
  if (trailing.isNotEmpty) {
    items.add(_unquote(trailing));
  }
  return items;
}

String _stripComment(String line) {
  var inSingleQuote = false;
  var inDoubleQuote = false;
  for (var i = 0; i < line.length; i++) {
    final String char = line[i];
    if (char == "'" && !inDoubleQuote) {
      inSingleQuote = !inSingleQuote;
    } else if (char == '"' && !inSingleQuote) {
      inDoubleQuote = !inDoubleQuote;
    } else if (char == '#' && !inSingleQuote && !inDoubleQuote) {
      return line.substring(0, i);
    }
  }
  return line;
}

String _unquote(String value) {
  if (value.length >= 2) {
    if ((value.startsWith("'") && value.endsWith("'")) ||
        (value.startsWith('"') && value.endsWith('"'))) {
      return value.substring(1, value.length - 1);
    }
  }
  return value;
}
