// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_tools/src/device.dart';
import 'package:path/path.dart' as path;

import '../base/utils.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class ScreenshotCommand extends FlutterCommand {
  ScreenshotCommand() {
    argParser.addOption('out',
      abbr: 'o',
      help: 'Location to write the screenshot.');
  }

  @override
  String get name => 'screenshot';

  @override
  String get description => 'Take a screenshot from a connected device.';

  @override
  final List<String> aliases = <String>['pic'];

  Device deviceForCommand;

  @override
  Future<int> runCmd() async {
    deviceForCommand = await findTargetDevice(androidOnly: androidOnly);
    if (deviceForCommand == null)
      return 1;
    return super.runCmd();
  }

  @override
  Future<int> runInProject() async {
    if (!deviceForCommand.supportsScreenshot) {
      printError('Screenshot not supported for ${deviceForCommand.name}.');
      return 1;
    }

    File outputFile;

    if (argResults.wasParsed('out')) {
      outputFile = new File(argResults['out']);
    } else {
      outputFile = getUniqueFile(Directory.current, 'flutter', 'png');
    }

    try {
      bool result = await deviceForCommand.takeScreenshot(outputFile);

      if (result) {
        int sizeKB = outputFile.lengthSync() ~/ 1000;
        printStatus('Screenshot written to ${path.relative(outputFile.path)} (${sizeKB}kb).');
        return 0;
      }
    } catch (error) {
      printError('Error taking screenshot: $error');
    }

    return 1;
  }
}
