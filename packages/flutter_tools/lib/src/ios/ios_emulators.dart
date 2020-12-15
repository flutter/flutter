// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/process.dart';
import '../device.dart';
import '../emulator.dart';
import '../globals.dart' as globals;
import 'simulators.dart';

class IOSEmulators extends EmulatorDiscovery {
  @override
  bool get supportsPlatform => globals.platform.isMacOS;

  @override
  bool get canListAnything => globals.iosWorkflow.canListEmulators;

  @override
  Future<List<Emulator>> get emulators async {
    final List<IOSSimulator> simulators = await globals.iosSimulatorUtils.getAvailableDevices();
    return simulators.map<Emulator>((IOSSimulator device) {
      return IOSEmulator(device);
    }).toList();
  }

  @override
  bool get canLaunchAnything => canListAnything;
}

class IOSEmulator extends Emulator {
  IOSEmulator(IOSSimulator simulator)
      : _simulator = simulator,
        super(simulator.id, true);

  final IOSSimulator _simulator;

  @override
  String get name => _simulator.name;

  @override
  String get manufacturer => 'Apple';

  @override
  Category get category => Category.mobile;

  @override
  String get platformDisplay =>
      // com.apple.CoreSimulator.SimRuntime.iOS-10-3 => iOS-10-3
      _simulator.simulatorCategory?.split('.')?.last ?? 'ios';

  @override
  Future<void> launch() async {
    final RunResult launchResult = await globals.processUtils.run(<String>[
      'open',
      '-a',
      globals.xcode.getSimulatorPath(),
    ]);
    if (launchResult.exitCode != 0) {
      globals.printError('$launchResult');
    }
    return _simulator.boot();
  }
}
