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
  _RunningApp({required this.process, required this.vmServiceCompleter});

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
        supportsInstall: true,
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
  Future<ExtensionApplicationPackage?> resolveApplication(
    ExtensionApplicationResolutionContext context,
  ) async {
    if (context.deviceId != customLinuxDeviceId) {
      return null;
    }
    final String? binaryName = getLinuxCmakeBinaryName(context.project.directory);
    if (context.applicationBinaryUri case final Uri prebuiltUri) {
      final String fallbackName = context.project.appName.isNotEmpty
          ? context.project.appName
          : prebuiltUri.pathSegments.lastWhere((String s) => s.isNotEmpty, orElse: () => 'app');
      return ExtensionApplicationPackage(appId: binaryName ?? fallbackName, bundleUri: prebuiltUri);
    }
    if (binaryName == null) {
      return null;
    }
    return ExtensionApplicationPackage(
      appId: binaryName,
      bundleUri: customLinuxExecutableUri(
        binaryName: binaryName,
        buildDirectory: context.project.buildDirectory,
        buildMode: context.buildMode,
      ),
    );
  }

  // Since the host and target devices are the same on desktop, verify the
  // bundle exists without copying it.
  @override
  Future<void> installApp({
    required Uri bundleUri,
    required String deviceId,
    bool prebuiltApplication = false,
  }) async {
    if (deviceId != customLinuxDeviceId) {
      throw UnsupportedError('Unknown device "$deviceId".');
    }
    if (FileSystemEntity.typeSync(bundleUri.toFilePath()) == FileSystemEntityType.notFound) {
      throw FileSystemException('Application bundle does not exist', bundleUri.toFilePath());
    }
  }

  // Since the host and target devices are the same on desktop, no work needs
  // to be done to uninstall the application.
  @override
  Future<void> uninstallApp({required String appId, required String deviceId}) async {
    if (deviceId != customLinuxDeviceId) {
      throw UnsupportedError('Unknown device "$deviceId".');
    }
  }

  // Since the host and target devices are the same on desktop, mirror
  // DesktopDevice by treating the application as installed on the matching
  // device.
  @override
  Future<bool> isAppInstalled({required String appId, required String deviceId}) async {
    if (deviceId != customLinuxDeviceId) {
      throw UnsupportedError('Unknown device "$deviceId".');
    }
    return true;
  }

  @override
  Future<bool> launchApp({
    required ExtensionDebuggingOptions debuggingOptions,
    required String deviceId,
    required Uri executableUri,
  }) async {
    if (deviceId != customLinuxDeviceId) {
      return false;
    }
    final executable = File.fromUri(executableUri);
    if (!executable.existsSync()) {
      return false;
    }

    // Stop any existing process for this device.
    await stopApp(deviceId: deviceId);

    final uriCompleter = Completer<Uri?>();

    try {
      final Process process = await Process.start(
        executable.path,
        const <String>[],
        workingDirectory: executable.parent.path,
      );
      final runningApp = _RunningApp(process: process, vmServiceCompleter: uriCompleter);
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

      return true;
    } on ProcessException {
      if (!uriCompleter.isCompleted) {
        uriCompleter.complete();
      }
      return false;
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
  Future<bool> stopApp({required String deviceId, String? appId}) async {
    final _RunningApp? runningApp = _runningApps[deviceId];
    if (runningApp == null || !runningApp.process.kill()) {
      return false;
    }
    _runningApps.remove(deviceId);
    if (!runningApp.vmServiceCompleter.isCompleted) {
      runningApp.vmServiceCompleter.complete();
    }
    await runningApp.process.exitCode;
    return true;
  }

  @override
  Future<void> shutdown() async {
    await Future.wait(
      _runningApps.keys.toList().map((String deviceId) => stopApp(deviceId: deviceId)),
    );
  }
}
