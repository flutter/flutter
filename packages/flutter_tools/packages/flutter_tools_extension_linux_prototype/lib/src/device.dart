// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

/// Prototype Linux [DeviceService] implementation.
final class LinuxDeviceService extends DeviceService {
  @override
  Future<List<TargetDevice>> getDevices() async {
    return <TargetDevice>[
      const TargetDevice(
        id: 'custom_linux_device',
        name: 'Linux Custom Extension Prototype Device',
        category: 'desktop',
        platformType: 'custom',
        targetPlatform: 'linux-x64',
        sdkNameAndVersion: 'Custom Linux 1.0.0',
        ephemeral: false,
      ),
    ];
  }
}
