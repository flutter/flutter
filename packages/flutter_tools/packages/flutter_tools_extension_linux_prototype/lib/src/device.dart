// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

import 'build.dart';

class _RunningApp {
  _RunningApp({required this.appId, required this.process, required this.vmServiceCompleter});

  final String appId;
  final Process process;
  final Completer<Uri?> vmServiceCompleter;
}

/// Prototype Linux [DeviceService] implementation.
final class LinuxDeviceService extends DeviceService {
  /// Identifier of the prototype Linux target device.
  static const String customLinuxDeviceId = 'custom_linux_device';

  // Mirrors kVMServiceMessageRegExp in package:flutter_tools/src/vmservice.dart.
  static final _vmServicePattern = RegExp(
    r'The Dart VM service is listening on ((http|//)[a-zA-Z0-9:/=_\-\.\[\]]+)',
  );

  final _runningApps = <String, _RunningApp>{};

  @override
  Future<List<TargetDevice>> getDevices() async {
    return const <TargetDevice>[
      TargetDevice(
        category: Category.desktop,
        id: customLinuxDeviceId,
        name: 'Linux Custom Extension Prototype Device',
        buildTarget: LinuxBuildService.customLinuxBuildTargetName,
        ephemeral: false,
        sdkNameAndVersion: 'Custom Linux 1.0.0',
        targetPlatform: 'linux-x64',
      ),
    ];
  }

  @override
  Future<bool> isSupportedForProject({
    required String deviceId,
    required ExtensionFlutterProject project,
  }) async {
    if (deviceId != customLinuxDeviceId) {
      return false;
    }
    return Directory.fromUri(project.directory.resolve('linux')).existsSync();
  }

  @override
  Future<void> launchApp({
    required String appId,
    required ExtensionDebuggingOptions debuggingOptions,
    required String deviceId,
    required Uri executableUri,
    bool prebuiltApplication = false,
  }) async {
    if (deviceId != customLinuxDeviceId) {
      throw ToolExtensionException('Unknown device "$deviceId".');
    }
    final String artifactPath = executableUri.toFilePath();
    final executable = FileSystemEntity.isDirectorySync(artifactPath)
        ? File.fromUri(Directory(artifactPath).uri.resolve(appId))
        : File(artifactPath);
    if (!executable.existsSync()) {
      throw ToolExtensionException('Application executable does not exist: ${executable.path}');
    }

    // Stop any existing process for this device.
    await stopApp(deviceId: deviceId);

    final uriCompleter = Completer<Uri?>();
    final environment = <String, String>{};
    final List<String> engineSwitches = debuggingOptions.engineSwitches;
    for (var i = 0; i < engineSwitches.length; i++) {
      environment['FLUTTER_ENGINE_SWITCH_${i + 1}'] = engineSwitches[i];
    }
    if (engineSwitches.isNotEmpty) {
      environment['FLUTTER_ENGINE_SWITCHES'] = engineSwitches.length.toString();
    }

    try {
      final Process process = await Process.start(
        executable.path,
        debuggingOptions.dartEntrypointArgs,
        environment: environment.isEmpty ? null : environment,
        workingDirectory: executable.parent.path,
      );
      final runningApp = _RunningApp(
        appId: appId,
        process: process,
        vmServiceCompleter: uriCompleter,
      );
      _runningApps[deviceId] = runningApp;

      void checkVmServiceUri(String line) {
        final Match? match = _vmServicePattern.firstMatch(line);
        if (match != null && !uriCompleter.isCompleted) {
          final String? uriStr = match.group(1);
          final Uri? uri = uriStr != null ? Uri.tryParse(uriStr) : null;
          uriCompleter.complete(uri);
        }
      }

      // TODO(bkonyi): Route application logs over a DeviceService log stream.
      process.stdout
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter())
          .listen(checkVmServiceUri);
      process.stderr
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter())
          .listen(checkVmServiceUri);

      unawaited(
        process.exitCode.then((int _) {
          if (identical(_runningApps[deviceId], runningApp)) {
            _runningApps.remove(deviceId);
          }
          if (!uriCompleter.isCompleted) {
            uriCompleter.complete();
          }
        }),
      );
    } on ProcessException catch (error) {
      if (!uriCompleter.isCompleted) {
        uriCompleter.complete();
      }
      throw ToolExtensionException('Failed to start "${executable.path}": ${error.message}');
    }
  }

  @override
  Future<Uri?> getVmServiceUri({required String deviceId}) async {
    final _RunningApp? runningApp = _runningApps[deviceId];
    if (runningApp == null) {
      return null;
    }
    return runningApp.vmServiceCompleter.future;
  }

  @override
  Future<void> stopApp({required String deviceId, String? appId}) async {
    if (deviceId != customLinuxDeviceId) {
      throw ToolExtensionException('Unknown device "$deviceId".');
    }
    final _RunningApp? runningApp = _runningApps[deviceId];
    if (runningApp == null || (appId != null && runningApp.appId != appId)) {
      return;
    }
    if (!runningApp.process.kill()) {
      throw ToolExtensionException(
        'Failed to stop application "${runningApp.appId}" on "$deviceId".',
      );
    }
    _runningApps.remove(deviceId);
    if (!runningApp.vmServiceCompleter.isCompleted) {
      runningApp.vmServiceCompleter.complete();
    }
    await runningApp.process.exitCode;
  }

  @override
  Future<void> shutdown() async {
    await Future.wait(
      _runningApps.keys.toList().map((String deviceId) => stopApp(deviceId: deviceId)),
    );
  }
}
