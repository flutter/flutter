// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/host_agent.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  await task(() async {
    try {
      final Directory? dumpDirectory = hostAgent.dumpDirectory;
      if (dumpDirectory == null) {
        return TaskResult.success(null);
      }

      // On command failure try uploading screenshot of failing command.
      final String screenshotPath = path.join(
        dumpDirectory.path,
        'device-screenshot-${DateTime.now().toLocal().toIso8601String()}.png',
      );

      deviceOperatingSystem = DeviceOperatingSystem.ios;
      final String deviceId = (await devices.workingDevice).deviceId;
      print('Taking screenshot of working device $deviceId at $screenshotPath');
      final int exitCode = await flutter(
        'screenshot',
        options: <String>[
          '--out',
          screenshotPath,
          '-d', deviceId,
        ],
      );

      if (exitCode != 0) {
        return TaskResult.failure('Failed to take screenshot.');
      }

      final File screenshot = File(screenshotPath);

      if (!screenshot.existsSync() || screenshot.readAsBytesSync().isEmpty) {
        return TaskResult.failure('Screenshot not created.');
      }

      return TaskResult.success(null);
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e) {
      return TaskResult.failure(e.toString());
    }
  });
}
