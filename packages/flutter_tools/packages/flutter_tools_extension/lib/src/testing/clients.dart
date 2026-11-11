// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_core/json.dart';

import '../artifacts.dart';
import '../build.dart';
import '../clean.dart';
import '../config.dart';
import '../device.dart';
import '../diagnostics.dart';
import '../templates.dart';
import 'harness.dart';

/// Typed JSON-RPC client for invoking [DiagnosticsExtension] methods on an
/// [ExtensionTestHarness].
final class ExtensionTestDiagnosticsClient {
  /// Creates a client bound to [_harness].
  ExtensionTestDiagnosticsClient(this._harness);

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
      timeout: null,
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
final class ExtensionTestConfigurationClient {
  /// Creates a client bound to [_harness].
  ExtensionTestConfigurationClient(this._harness);

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
final class ExtensionTestTemplateClient {
  /// Creates a client bound to [_harness].
  ExtensionTestTemplateClient(this._harness);

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
final class ExtensionTestDeviceClient {
  /// Creates a client bound to [_harness].
  ExtensionTestDeviceClient(this._harness);

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

  /// Queries `device.launchApp` over JSON-RPC.
  Future<bool> launchApp({
    required ExtensionDebuggingOptions debuggingOptions,
    required String deviceId,
    required Uri executableUri,
  }) async {
    final Object? response = await _harness.sendRawRequest(
      DeviceService.launchAppMethod,
      params: <String, Object?>{
        DeviceService.debuggingOptionsParam: debuggingOptions.toMap(),
        DeviceService.deviceIdParam: deviceId,
        DeviceService.executableUriParam: executableUri.toString(),
      },
      timeout: null,
    );
    if (response case final bool launched) {
      return launched;
    }
    throw StateError(
      'Expected bool from ${DeviceService.launchAppMethod}, '
      'got ${response.runtimeType}.',
    );
  }

  /// Queries `device.getVmServiceUri` over JSON-RPC.
  Future<Uri?> getVmServiceUri({required String deviceId}) async {
    final Object? response = await _harness.sendRawRequest(
      DeviceService.getVmServiceUriMethod,
      params: <String, Object?>{DeviceService.deviceIdParam: deviceId},
      timeout: null,
    );
    if (response case {DeviceService.vmServiceUriKey: final String? uriStr}) {
      if (uriStr == null) {
        return null;
      }
      final Uri? parsed = Uri.tryParse(uriStr);
      if (parsed == null) {
        throw FormatException(
          'Invalid "${DeviceService.vmServiceUriKey}" from '
          '${DeviceService.getVmServiceUriMethod}: "$uriStr".',
        );
      }
      return parsed;
    }
    throw StateError(
      'Expected Map with String or null "${DeviceService.vmServiceUriKey}" from '
      '${DeviceService.getVmServiceUriMethod}, got ${response.runtimeType}.',
    );
  }

  /// Queries `device.stopApp` over JSON-RPC.
  Future<bool> stopApp({required String deviceId}) async {
    final Object? response = await _harness.sendRawRequest(
      DeviceService.stopAppMethod,
      params: <String, Object?>{DeviceService.deviceIdParam: deviceId},
    );
    if (response case final bool stopped) {
      return stopped;
    }
    throw StateError(
      'Expected bool from ${DeviceService.stopAppMethod}, '
      'got ${response.runtimeType}.',
    );
  }

  /// Queries `device.startLogStream` over JSON-RPC.
  Future<void> startLogStream({required String deviceId}) async {
    await _harness.sendRawRequest(
      DeviceService.startLogStreamMethod,
      params: <String, Object?>{DeviceService.deviceIdParam: deviceId},
    );
  }

  /// Queries `device.stopLogStream` over JSON-RPC.
  Future<void> stopLogStream({required String deviceId}) async {
    await _harness.sendRawRequest(
      DeviceService.stopLogStreamMethod,
      params: <String, Object?>{DeviceService.deviceIdParam: deviceId},
    );
  }

  /// Returns a broadcast stream of log lines emitted via `'device.logEntry'`
  /// notifications for [deviceId].
  ///
  /// Throws a [FormatException] on the returned stream if a `'device.logEntry'`
  /// notification payload is missing a valid string `deviceId` or `line`.
  Stream<String> logLines({required String deviceId}) {
    return _harness.onNotification(DeviceService.logEntryNotificationMethod).expand<String>((
      Map<String, Object?> params,
    ) {
      final String eventDeviceId = params.requiredField<String>(DeviceService.deviceIdParam);
      final String line = params.requiredField<String>(DeviceService.lineKey);
      return eventDeviceId == deviceId ? <String>[line] : const <String>[];
    });
  }
}

/// Typed JSON-RPC client for invoking [BuildService] methods on an
/// [ExtensionTestHarness].
final class ExtensionTestBuildClient {
  /// Creates a client bound to [_harness].
  ExtensionTestBuildClient(this._harness);

  final ExtensionTestHarness _harness;

  /// Queries `build.getBuildTargets` over JSON-RPC.
  Future<List<ExtensionBuildTarget>> getBuildTargets() async {
    final Object? response = await _harness.sendRawRequest(BuildService.getBuildTargetsMethod);
    return ExtensionBuildTarget.listFromJson(response);
  }

  /// Queries `build.getAssembleTargets` over JSON-RPC.
  Future<List<ExtensionAssembleTarget>> getAssembleTargets() async {
    final Object? response = await _harness.sendRawRequest(BuildService.getAssembleTargetsMethod);
    return ExtensionAssembleTarget.listFromJson(response);
  }

  /// Queries `build.build` over JSON-RPC.
  Future<ExtensionBuildResult> build({
    required BuildMode buildMode,
    required Uri flutterRoot,
    required String mainPath,
    required Uri outputDir,
    required Uri projectRoot,
    required String targetName,
    Map<String, String> resolvedArtifacts = const <String, String>{},
  }) async {
    final Object? response = await _harness.sendRawRequest(
      BuildService.buildMethod,
      params: <String, Object?>{
        BuildService.buildModeParam: buildMode.cliName,
        BuildService.flutterRootParam: _ensureTrailingSlash(flutterRoot).toString(),
        BuildService.mainPathParam: mainPath,
        BuildService.outputDirParam: _ensureTrailingSlash(outputDir).toString(),
        BuildService.projectRootParam: _ensureTrailingSlash(projectRoot).toString(),
        BuildService.resolvedArtifactsParam: resolvedArtifacts,
        BuildService.targetNameParam: targetName,
      },
      timeout: null,
    );
    if (response case final Map<String, Object?> map) {
      return ExtensionBuildResult.fromJson(map);
    }
    throw StateError(
      'Expected Map<String, Object?> from ${BuildService.buildMethod}, '
      'got ${response.runtimeType}.',
    );
  }

  /// Queries `build.assemble` over JSON-RPC.
  Future<ExtensionBuildResult> assemble({
    required Uri buildDir,
    required BuildMode buildMode,
    required Uri flutterRoot,
    required String mainPath,
    required Uri outputDir,
    required Uri projectRoot,
    required String targetName,
    Map<String, String> resolvedArtifacts = const <String, String>{},
  }) async {
    final Object? response = await _harness.sendRawRequest(
      BuildService.assembleMethod,
      params: <String, Object?>{
        BuildService.buildDirParam: _ensureTrailingSlash(buildDir).toString(),
        BuildService.buildModeParam: buildMode.cliName,
        BuildService.flutterRootParam: _ensureTrailingSlash(flutterRoot).toString(),
        BuildService.mainPathParam: mainPath,
        BuildService.outputDirParam: _ensureTrailingSlash(outputDir).toString(),
        BuildService.projectRootParam: _ensureTrailingSlash(projectRoot).toString(),
        BuildService.resolvedArtifactsParam: resolvedArtifacts,
        BuildService.targetNameParam: targetName,
      },
      timeout: null,
    );
    if (response case final Map<String, Object?> map) {
      return ExtensionBuildResult.fromJson(map);
    }
    throw StateError(
      'Expected Map<String, Object?> from ${BuildService.assembleMethod}, '
      'got ${response.runtimeType}.',
    );
  }

  static Uri _ensureTrailingSlash(Uri uri) =>
      uri.path.endsWith('/') ? uri : uri.replace(path: '${uri.path}/');
}

/// Typed JSON-RPC client for invoking [ArtifactService] methods on an
/// [ExtensionTestHarness].
final class ExtensionTestArtifactClient {
  /// Creates a client bound to [_harness].
  ExtensionTestArtifactClient(this._harness);

  final ExtensionTestHarness _harness;

  /// Queries `artifact.listRequiredArtifacts` over JSON-RPC.
  Future<List<ArtifactDependency>> listRequiredArtifacts({
    required String engineVersion,
    required HostPlatform hostPlatform,
    Set<String>? targetPlatforms,
  }) async {
    final Object? response = await _harness.sendRawRequest(
      ArtifactService.listRequiredArtifactsMethod,
      params: <String, Object?>{
        ArtifactService.engineVersionParam: engineVersion,
        ArtifactService.hostPlatformParam: hostPlatform.cliName,
        ArtifactService.targetPlatformsParam: ?targetPlatforms?.toList(),
      },
    );
    return ArtifactDependency.listFromJson(response);
  }
}

/// Typed JSON-RPC client for invoking [CleanService] methods on an
/// [ExtensionTestHarness].
final class ExtensionTestCleanClient {
  /// Creates a client bound to [_harness].
  ExtensionTestCleanClient(this._harness);

  final ExtensionTestHarness _harness;

  /// Queries `clean.clean` over JSON-RPC.
  Future<void> clean(CleanEnvironment environment) async {
    await _harness.sendRawRequest(
      CleanService.cleanMethod,
      params: <String, Object?>{CleanService.environmentParam: environment.toMap()},
      timeout: null,
    );
  }
}
