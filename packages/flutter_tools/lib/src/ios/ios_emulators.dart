// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/process.dart';
import '../device_categories.dart';
import '../emulator.dart';
import '../globals_null_migrated.dart' as globals;

const String iosSimulatorId = 'apple_ios_simulator';

class IOSEmulators extends EmulatorDiscovery {
  @override
  bool get supportsPlatform => globals.platform.isMacOS;

  @override
  bool get canListAnything => globals.iosWorkflow?.canListEmulators ?? false;

  @override
  Future<List<Emulator>> get emulators async => getEmulators();

  @override
  bool get canLaunchAnything => canListAnything;
}

class IOSEmulator extends Emulator {
  const IOSEmulator(String id) : super(id, true);

  @override
  String get name => 'iOS Simulator';

  @override
  String get manufacturer => 'Apple';

  @override
  Category get category => Category.mobile;

  @override
  PlatformType get platformType => PlatformType.ios;

  @override
  Future<void> launch() async {
    Future<bool> launchSimulator(List<String> additionalArgs) async {
      final String? simulatorPath = globals.xcode?.getSimulatorPath();
      if (simulatorPath == null) {
        return false;
      }
      final List<String> args = <String>[
        'open',
        ...additionalArgs,
        '-a',
        simulatorPath,
      ];

      final RunResult launchResult = await globals.processUtils.run(args);
      if (launchResult.exitCode != 0) {
        globals.printError('$launchResult');
        return false;
      }
      return true;
    }

    // First run with `-n` to force a device to boot if there isn't already one
    if (!await launchSimulator(<String>['-n'])) {
      return;
    }

    // Run again to force it to Foreground (using -n doesn't force existing
    // devices to the foreground)
    await launchSimulator(<String>[]);
  }
}

/// Return the list of iOS Simulators (there can only be zero or one).
List<IOSEmulator> getEmulators() {
  final String? simulatorPath = globals.xcode?.getSimulatorPath();
  if (simulatorPath == null) {
    return <IOSEmulator>[];
  }

  return <IOSEmulator>[const IOSEmulator(iosSimulatorId)];
}
