// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:vm_service/utils.dart';
import 'package:vm_service/vm_service.dart';

abstract class DevToolsUtils {
  static void printOutput(
    String? message,
    Object json, {
    required bool machineMode,
  }) {
    final output = machineMode ? jsonEncode(json) : message;
    if (output != null) {
      print(output);
    }
  }

  static Future<VmService?> connectToVmService(Uri theUri) async {
    // Fix up the various acceptable URI formats into a WebSocket URI to connect.
    final uri = convertToWebSocketUrl(serviceProtocolUrl: theUri);

    try {
      final WebSocket ws = await WebSocket.connect(uri.toString());

      final VmService service = VmService(
        ws.asBroadcastStream(),
        (String message) => ws.add(message),
      );

      return service;
    } catch (_) {
      print('ERROR: Unable to connect to VMService $theUri');
      return null;
    }
  }

  static Future<String> getVersion(String devToolsDir) async {
    try {
      final versionFile = File(path.join(devToolsDir, 'version.json'));
      final decoded = jsonDecode(await versionFile.readAsString());
      return decoded['version'] ?? 'unknown';
    } on FileSystemException {
      return 'unknown';
    }
  }
}
