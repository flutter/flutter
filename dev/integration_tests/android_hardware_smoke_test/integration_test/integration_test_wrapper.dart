// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:android_driver_extensions/extension.dart';
import 'package:android_hardware_smoke_test/main.dart' as app;
import 'package:android_hardware_smoke_test/src/messages.g.dart';
import 'package:android_hardware_smoke_test/vm_service_keys.dart';
import 'package:flutter_driver/driver_extension.dart';

void main() {
  enableFlutterDriverExtension(
    // Register nativeDriverCommands so that host-side driver extensions can send NativeCommands
    // (specifically for capturing system-level screenshots from the host during host-driven tests).
    commands: <CommandExtension>[nativeDriverCommands],
    // Thin handler to bridge driver's requestData and MainApp's test_channel.
    handler: (String? request) async {
      if (request == null) {
        return json.encode(<String, Object?>{keyMessage: 'Error: request was null'});
      }

      final Map<String, Object?> payload = (json.decode(request) as Map<Object?, Object?>)
          .cast<String, Object?>();

      // Handle host-side graphics backend self-discovery query
      if (payload[keyCommand] == commandGetGoldenVariant) {
        final String? variant = await NativeSupportApi().getImpellerBackend();
        return json.encode(<String, Object?>{keyGoldenVariant: variant});
      }

      final scenarioName = payload[keyTestScenario]! as String;
      final TestScenario scenario = TestScenario.values.byName(scenarioName);

      final bool performAppSideGoldenCompare =
          payload[keyPerformAppSideGoldenCompare] as bool? ?? true;
      final bool captureScreenshot = payload[keyCaptureScreenshot] as bool? ?? true;

      // Call the coordinator directly!
      final RenderReply reply = await app.SmokeTestCoordinator.instance.renderTest(
        RenderRequest(
          scenario: scenario,
          performAppSideGoldenCompare: performAppSideGoldenCompare,
          captureScreenshot: captureScreenshot,
        ),
      );

      return json.encode(<String, Object?>{
        keyMessage: reply.message,
        keyReason: reply.reason,
        keyX: reply.x,
        keyY: reply.y,
        keyWidth: reply.width,
        keyHeight: reply.height,
        keyImageBytes: reply.imageBytes != null ? base64.encode(reply.imageBytes!) : null,
      });
    },
  );

  app.main();
}
