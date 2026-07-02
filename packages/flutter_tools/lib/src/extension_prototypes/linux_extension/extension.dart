// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';
import '../../../flutter_tools_extension.dart';
import './device.dart';

void linuxDeviceExtensionEntryPoint(SendPort hostSendPort) {
  final provider = ToolExtensionProvider(name: 'linux_device_extension', sendPort: hostSendPort);

  provider.registerService(
    LinuxDeviceService(
      onNotification: (String method, Map<String, Object?> params) {
        provider.sendNotification(method, params);
      },
    ),
  );
  provider.initialize();
}
