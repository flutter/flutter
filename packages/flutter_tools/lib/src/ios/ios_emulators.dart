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
    final List<Emulator> discoveredEmulators = simulators.map<Emulator>((IOSSimulator device) {
      return IOSEmulator(device);
    }).toList();
    discoveredEmulators.add(const PlaceholderIOSEmulator());
    return discoveredEmulators;
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
  PlatformType get platformType => PlatformType.ios;

  @override
  Future<void> launch() async {
    await launchSimulator(<String>[]);
    return _simulator.boot();
  }
}

/// Used by IDEs to "Open iOS Simulator" without a specific simulator.
class PlaceholderIOSEmulator extends Emulator {
  const PlaceholderIOSEmulator() : super(iosSimulatorId, true);

  @override
  String get name => 'iOS Simulator (launch app only)';

  @override
  String get manufacturer => 'Apple';

  @override
  Category get category => Category.mobile;

  @override
  PlatformType get platformType => PlatformType.ios;

  @override
  Future<void> launch() async {
    // First run with `-n` to force a device to boot if there isn't already one
    if (!await launchSimulator(<String>['-n'])) {
      return;
    }

    // Run again to force it to Foreground (using -n doesn't force existing
    // devices to the foreground)
    await launchSimulator(<String>[]);
  }
}

Future<bool> launchSimulator(List<String> additionalArgs) async {
  final List<String> args = <String>[
    'open',
    ...additionalArgs,
    '-a',
    globals.xcode.getSimulatorPath(),
  ];

  final RunResult launchResult = await globals.processUtils.run(args);
  if (launchResult.exitCode != 0) {
    globals.printError('$launchResult');
    return false;
  }
  return true;
}
