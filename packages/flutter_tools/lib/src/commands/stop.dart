// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../application_package.dart';
import '../device.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class StopCommand extends FlutterCommand {
  final String name = 'stop';
  final String description = 'Stop your Flutter app on an attached device.';

  bool get requiresDevice => true;

  @override
  Future<int> runInProject() async {
    await downloadApplicationPackages();
    Device device = deviceForCommand;
    ApplicationPackage app = applicationPackages.getPackageForPlatform(device.platform);
    printStatus('Stopping apps on ${device.name}.');
    return await device.stopApp(app) ? 0 : 1;
  }
}
