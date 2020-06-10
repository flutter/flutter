// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:simulators/simulator_manager.dart';

import 'safari_installation.dart';
import 'utils.dart';

class CreateSimulatorCommand extends Command<bool> with ArgUtils {
  CreateSimulatorCommand() {
    IosSafariArgParser.instance.populateOptions(argParser);
    argParser
      ..addOption(
        'type',
        defaultsTo: _defaultType,
        help: 'Type of the mobile simulator. Currently the only iOS '
            'Simulators are supported. Android will be added soon. This option '
            'is not case sensitive, ios, iOS, IOS are all valid.',
      );
  }

  /// Currently the only iOS Simulators are supported.
  static final String _defaultType = 'iOS';

  @override
  String get name => 'create_simulator';

  @override
  String get description => 'Creates mobile simulators.';

  @override
  FutureOr<bool> run() async {
    IosSafariArgParser.instance.parseOptions(argResults);
    final String simulatorType = argResults['type'] as String;
    if (simulatorType.toUpperCase() != 'IOS') {
      throw Exception('Currently the only iOS Simulators are supported');
    }
    final IosSimulatorManager iosSimulatorManager = IosSimulatorManager();
    try {
      final IosSimulator simulator = await iosSimulatorManager.createSimulator(
          IosSafariArgParser.instance.iosMajorVersion,
          IosSafariArgParser.instance.iosMinorVersion,
          IosSafariArgParser.instance.iosDevice);
      print('INFO: Simulator created ${simulator.toString()}');
    } catch (e) {
      throw Exception('Error creating requested simulator. You can use Xcode '
          'to install more versions: XCode > Preferences > Components.'
          ' Exception: $e');
    }
    return true;
  }
}
