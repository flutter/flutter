// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

/// Prototype Linux [DeviceService] implementation.
final class LinuxDeviceService extends DeviceService {
  /// Identifier of the prototype Linux target device.
  static const String customLinuxDeviceId = 'custom_linux_device';

  @override
  Future<List<TargetDevice>> getDevices() async {
    return const <TargetDevice>[
      TargetDevice(
        category: Category.desktop,
        id: customLinuxDeviceId,
        name: 'Linux Custom Extension Prototype Device',
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
    final Uri projectDirectoryUri = Directory.fromUri(project.directory).uri;
    return Directory.fromUri(projectDirectoryUri.resolve('linux')).existsSync();
  }
}
