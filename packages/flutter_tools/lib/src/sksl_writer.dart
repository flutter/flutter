// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:file/file.dart';

import 'base/file_system.dart';
import 'base/logger.dart';
import 'build_info.dart';
import 'convert.dart';
import 'device.dart';
import 'globals_null_migrated.dart' as globals;

Future<String> sharedSkSlWriter(Device device, Map<String, Object> data, {
  File outputFile,
  Logger logger,
}) async {
  logger ??= globals.logger;
  if (data.isEmpty) {
    logger.printStatus(
      'No data was received. To ensure SkSL data can be generated use a '
      'physical device then:\n'
      '  1. Pass "--cache-sksl" as an argument to flutter run.\n'
      '  2. Interact with the application to force shaders to be compiled.\n'
    );
    return null;
  }
  if (outputFile == null) {
    outputFile = globals.fsUtils.getUniqueFile(
      globals.fs.currentDirectory,
      'flutter',
      'sksl.json',
    );
  } else if (!outputFile.parent.existsSync()) {
    outputFile.parent.createSync(recursive: true);
  }
  // Convert android sub-platforms to single target platform.
  TargetPlatform targetPlatform = await device.targetPlatform;
  switch (targetPlatform) {
    case TargetPlatform.android_arm:
    case TargetPlatform.android_arm64:
    case TargetPlatform.android_x64:
    case TargetPlatform.android_x86:
      targetPlatform = TargetPlatform.android;
      break;
    default:
      break;
  }
  final Map<String, Object> manifest = <String, Object>{
    'platform': getNameForTargetPlatform(targetPlatform),
    'name': device.name,
    'engineRevision': globals.flutterVersion.engineRevision,
    'data': data,
  };
  outputFile.writeAsStringSync(json.encode(manifest));
  logger.printStatus('Wrote SkSL data to ${outputFile.path}.');
  return outputFile.path;
}
