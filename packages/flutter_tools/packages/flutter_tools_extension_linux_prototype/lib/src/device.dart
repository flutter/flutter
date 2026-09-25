// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

/// Prototype Linux [DeviceService] implementation.
final class LinuxDeviceService extends DeviceService {
  @override
  Future<List<TargetDevice>> getDevices({Uri? projectRoot}) async {
    final bool isSupportedForProject =
        projectRoot == null || Directory.fromUri(projectRoot.resolve('linux')).existsSync();
    return <TargetDevice>[
      TargetDevice(
        category: Category.desktop,
        id: 'custom_linux_device',
        name: 'Linux Custom Extension Prototype Device',
        ephemeral: false,
        isSupportedForProject: isSupportedForProject,
        sdkNameAndVersion: 'Custom Linux 1.0.0',
        targetPlatform: 'linux-x64',
      ),
    ];
  }
}
