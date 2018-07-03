// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/file_system.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../emulator.dart';
import '../globals.dart';
import '../ios/mac.dart';
import 'ios_workflow.dart';

class IOSEmulators extends EmulatorDiscovery {
  @override
  bool get supportsPlatform => platform.isMacOS;

  @override
  bool get canListAnything => iosWorkflow.canListEmulators;

  @override
  Future<List<Emulator>> get emulators async => getEmulators();
}

class IOSEmulator extends Emulator {
  IOSEmulator(String id) : super(id, true);

  @override
  String get name => 'iOS Simulator';

  @override
  String get manufacturer => 'Apple';

  @override
  String get label => null;

  @override
  Future<void> launch() async {
    Future<void> launchSimulator(List<String> additionalArgs) async {
      final List<String> args = <String>['open']
          .followedBy(additionalArgs)
          .followedBy(<String>['-a', getSimulatorPath()]);

      final RunResult launchResult = await runAsync(args);
      if (launchResult.exitCode != 0) {
        printError('$launchResult');
        return false;
      }
      return true;
    }

    // First run with `-n` to force a device to boot if there isn't already one
    if (!await launchSimulator(<String>['-n']))
      return false;
    
    // Run again to force it to Foreground (using -n doesn't force existing
    // devices to the foreground)
    return launchSimulator(<String>[]);
  }
}

/// Return the list of iOS Simulators (there can only be zero or one).
List<IOSEmulator> getEmulators() {
  final String simulatorPath = getSimulatorPath();
  if (simulatorPath == null) {
    return <IOSEmulator>[];
  }

  return <IOSEmulator>[new IOSEmulator('apple_ios_simulator')];
}

String getSimulatorPath() {
  if (xcode.xcodeSelectPath == null)
    return null;
  final List<String> searchPaths = <String>[
    fs.path.join(xcode.xcodeSelectPath, 'Applications', 'Simulator.app'),
  ];
  return searchPaths.where((String p) => p != null).firstWhere(
        (String p) => fs.directory(p).existsSync(),
        orElse: () => null,
      );
}
