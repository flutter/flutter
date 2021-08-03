// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:simulators/simulator_manager.dart';

import 'browser_lock.dart';
import 'utils.dart';

class CreateSimulatorCommand extends Command<bool> with ArgUtils<bool> {
  @override
  String get name => 'create_simulator';

  @override
  String get description => 'Creates mobile simulators.';

  @override
  FutureOr<bool> run() async {
    final IosSimulatorManager iosSimulatorManager = IosSimulatorManager();
    try {
      final SafariIosLock lock = browserLock.safariIosLock;
      final IosSimulator simulator = await iosSimulatorManager.createSimulator(
        lock.majorVersion,
        lock.minorVersion,
        lock.device,
      );
      print('INFO: Simulator created ${simulator.toString()}');
    } catch (e) {
      throw Exception('Error creating requested simulator. You can use Xcode '
          'to install more versions: XCode > Preferences > Components.'
          ' Exception: $e');
    }
    return true;
  }
}
