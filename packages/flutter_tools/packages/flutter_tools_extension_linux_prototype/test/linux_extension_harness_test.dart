// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/testing.dart';
import 'package:flutter_tools_extension_linux_prototype/src/device.dart';
import 'package:flutter_tools_extension_linux_prototype/src/diagnostics.dart';
import 'package:test/test.dart';

Uri _resolvePrototypePackageRoot() {
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

void main() {
  group('Linux Prototype Testing Harness', () {
    test('ServiceTestHarness exercises LinuxExtensionDiagnostics in-process', () async {
      final diagnostics = LinuxExtensionDiagnostics();
      final harness = ServiceTestHarness<LinuxExtensionDiagnostics>(diagnostics);
      addTearDown(harness.dispose);

      expect(diagnostics.title, 'Linux Custom Extension Prototype');
      final List<ValidationResult> results = await diagnostics.runDiagnostics();
      expect(results, hasLength(1));
      expect(results.first.type, ValidationType.success);
      expect(results.first.statusInfo, 'Linux Prototype Extension OK');

      diagnostics.log('diagnostics checked');
      expect(harness.logs, hasLength(1));
      expect(harness.logs.single.level, ExtensionLogLevel.info);
      expect(harness.logs.single.message, 'diagnostics checked');
    });

    test('ServiceTestHarness exercises LinuxDeviceService in-process', () async {
      final Directory tempDir = Directory.systemTemp.createTempSync('linux_harness_test.');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      Directory.fromUri(tempDir.uri.resolve('linux/')).createSync();

      final deviceService = LinuxDeviceService();
      final harness = ServiceTestHarness<LinuxDeviceService>(deviceService);
      addTearDown(harness.dispose);

      final List<TargetDevice> devices = await deviceService.getDevices();
      expect(devices, hasLength(1));
      expect(devices.first.id, LinuxDeviceService.customLinuxDeviceId);

      final bool supported = await deviceService.isSupportedForProject(
        deviceId: LinuxDeviceService.customLinuxDeviceId,
        project: ExtensionFlutterProject(
          appName: 'temp_app',
          buildDirectory: tempDir.uri.resolve('build/'),
          directory: tempDir.uri,
        ),
      );
      expect(supported, isTrue);

      deviceService.emitLogLine(
        deviceId: LinuxDeviceService.customLinuxDeviceId,
        line: 'device ready',
      );
      expect(harness.deviceLogLines(LinuxDeviceService.customLinuxDeviceId), <String>[
        'device ready',
      ]);
    });

    test(
      'verifyExtensionPackage spawns bin/flutter_tools_extension_linux_prototype.dart',
      () async {
        await verifyExtensionPackage(
          packageRoot: _resolvePrototypePackageRoot(),
          entrypointRelativePath: 'bin/flutter_tools_extension_linux_prototype.dart',
        );
      },
    );
  });
}
