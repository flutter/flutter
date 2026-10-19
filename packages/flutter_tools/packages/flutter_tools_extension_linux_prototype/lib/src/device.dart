// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

import 'build.dart';

/// Prototype Linux [DeviceService] implementation.
final class LinuxDeviceService extends DeviceService {
  /// Identifier of the prototype Linux target device.
  static const String customLinuxDeviceId = 'custom_linux_device';

  final _runningProcesses = <String, Process>{};
  final _vmServiceUriCompleters = <String, Completer<Uri?>>{};
  final _discoveredUris = <String, Uri?>{};

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
  Future<bool> isSupportedForProject({required String deviceId, required Uri projectRoot}) async {
    if (deviceId != customLinuxDeviceId) {
      return false;
    }
    return Directory.fromUri(projectRoot.resolve('linux')).existsSync();
  }

  @override
  Future<bool> launchApp({
    required String deviceId,
    required String executablePath,
    ExtensionDebuggingOptions? debuggingOptions,
  }) async {
    if (deviceId != customLinuxDeviceId) {
      return false;
    }
    final executable = File(executablePath);
    if (!executable.existsSync()) {
      stderr.writeln('Executable not found at $executablePath');
      return false;
    }

    // Stop any existing process for this device.
    await stopApp(deviceId: deviceId);

    final uriCompleter = Completer<Uri?>();
    _vmServiceUriCompleters[deviceId] = uriCompleter;
    _discoveredUris[deviceId] = null;

    try {
      final Process process = await Process.start(
        executablePath,
        const <String>[],
        workingDirectory: executable.parent.path,
      );
      _runningProcesses[deviceId] = process;

      final vmServiceRegExp = RegExp(
        r'The Dart VM service is listening on (http://127\.0\.0\.1:\d+/[a-zA-Z0-9_-]+/?)',
      );

      void checkVmServiceUri(String line) {
        final Match? match = vmServiceRegExp.firstMatch(line);
        if (match != null && !uriCompleter.isCompleted) {
          final String? uriStr = match.group(1);
          final Uri? uri = uriStr != null ? Uri.tryParse(uriStr) : null;
          _discoveredUris[deviceId] = uri;
          uriCompleter.complete(uri);
        }
      }

      process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((String line) {
        stdout.writeln('[App] $line');
        checkVmServiceUri(line);
      });
      process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((String line) {
        stderr.writeln('[App Error] $line');
        checkVmServiceUri(line);
      });

      unawaited(
        process.exitCode.then((int code) {
          _runningProcesses.remove(deviceId);
          if (!uriCompleter.isCompleted) {
            uriCompleter.complete();
          }
        }),
      );

      return true;
    } on ProcessException catch (e) {
      stderr.writeln('Failed to launch app: $e');
      if (!uriCompleter.isCompleted) {
        uriCompleter.complete();
      }
      return false;
    }
  }

  @override
  Future<Uri?> getVmServiceUri({required String deviceId}) async {
    if (_discoveredUris[deviceId] != null) {
      return _discoveredUris[deviceId];
    }
    final Completer<Uri?>? completer = _vmServiceUriCompleters[deviceId];
    if (completer != null) {
      return completer.future;
    }
    return null;
  }

  @override
  Future<bool> stopApp({required String deviceId}) async {
    final Process? process = _runningProcesses.remove(deviceId);
    final Completer<Uri?>? completer = _vmServiceUriCompleters.remove(deviceId);
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _discoveredUris.remove(deviceId);
    if (process != null) {
      process.kill();
      await process.exitCode;
      return true;
    }
    return false;
  }

  @override
  Future<void> shutdown() async {
    for (final String deviceId in _runningProcesses.keys.toList()) {
      await stopApp(deviceId: deviceId);
    }
  }
}
